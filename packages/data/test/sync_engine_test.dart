import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:test/test.dart';

import 'fake_server.dart';

class Device {
  Device(this.name, FakeServer server, {required int Function() now, int pullLimit = 500})
      : db = AppDatabase(NativeDatabase.memory()) {
    engine = SyncEngine(db: db, api: server.apiFor(name)..pullLimit = pullLimit, clock: HlcClock(name, now: now), deviceId: name);
  }
  final String name;
  final AppDatabase db;
  late final SyncEngine engine;

  Future<Map<String, Object?>?> row(String table, String id, {String key = 'id'}) async =>
      (await db.customSelect('SELECT * FROM $table WHERE $key = ?', variables: [Variable.withString(id)]).getSingleOrNull())?.data;
}

// Mất tiến trình trước request thứ hai: lô đầu đã được xử lý và commit xuống SQLite.
class _StopAfterFirstPush extends FakeApi {
  _StopAfterFirstPush(FakeServer server) : super(server, 'phone');
  int pushes = 0;

  @override
  Future<List<MutationResult>> push(String deviceId, List<Mutation> mutations) {
    if (++pushes == 2) throw StateError('app stopped');
    return super.push(deviceId, mutations);
  }
}

void main() {
  // Mỗi "thiết bị" trong test có DB in-memory riêng, không dùng chung executor.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late FakeServer server;
  var wall = 1764000000000;
  int now() => wall;

  setUp(() {
    server = FakeServer();
    wall = 1764000000000;
  });

  test('sửa offline ghi local + outbox; sync đẩy lên và nhận version', () async {
    final a = Device('phone', server, now: now);
    await a.engine.edit(SyncTable.items, 'i1', {'kind': 'task', 'title': 'Buy milk', 'starts_at': '2026-12-01T08:00:00.000Z', 'tags': ['home']});
    expect(await a.engine.pendingCount(), 1);
    final local = await a.row('items', 'i1');
    expect(local!['starts_at'], DateTime.utc(2026, 12, 1, 8).millisecondsSinceEpoch);
    expect(local['tags'], '["home"]');

    final report = await a.engine.sync();
    expect(report.pushed, 1);
    expect(await a.engine.pendingCount(), 0);
    expect((await a.row('items', 'i1'))!['version'], greaterThan(0));
    expect(server.rows['items/i1']!['title'], 'Buy milk');
  });

  test('resetLocalData: xóa dữ liệu tài khoản + outbox + con trỏ pull, giữ device id và pref.*', () async {
    final a = Device('phone', server, now: now);
    final deviceId = await InstallInfo.deviceId(a.db);
    await LocalPrefs(a.db).set('theme', 'dark');
    await a.engine.edit(SyncTable.items, 'i1', {'kind': 'task', 'title': 'Synced'});
    await a.engine.sync();
    await a.engine.edit(SyncTable.items, 'i2', {'kind': 'task', 'title': 'Pending'});

    await a.engine.resetLocalData();
    expect(await a.db.select(a.db.items).get(), isEmpty);
    expect(await a.engine.pendingCount(), 0);
    expect(await InstallInfo.deviceId(a.db), deviceId);
    expect(await LocalPrefs(a.db).get('theme'), 'dark');
    // Con trỏ pull về 0: đồng bộ lại kéo đủ dữ liệu của tài khoản trên server.
    await a.engine.sync();
    expect((await a.row('items', 'i1'))!['title'], 'Synced');
  });

  test('2 máy sửa offline 2 trường khác nhau: cả 2 thay đổi được giữ (LWW theo trường)', () async {
    final phone = Device('phone', server, now: now);
    final tablet = Device('tablet', server, now: now);
    await phone.engine.edit(SyncTable.items, 'i1', {'kind': 'task', 'title': 'Report', 'priority': 0});
    await phone.engine.sync();
    await tablet.engine.sync();

    wall += 1000;
    await phone.engine.edit(SyncTable.items, 'i1', {'title': 'Report Q4'});
    wall += 1000;
    await tablet.engine.edit(SyncTable.items, 'i1', {'priority': 3});
    await tablet.engine.sync();
    await phone.engine.sync();
    await tablet.engine.sync();

    for (final d in [phone, tablet]) {
      final r = await d.row('items', 'i1');
      expect(r!['title'], 'Report Q4', reason: d.name);
      expect(r['priority'], 3, reason: d.name);
    }
  });

  test('cùng 1 trường: lần sửa sau (clock lớn hơn) thắng ở cả 2 máy', () async {
    final phone = Device('phone', server, now: now);
    final tablet = Device('tablet', server, now: now);
    await phone.engine.edit(SyncTable.items, 'i1', {'kind': 'task', 'title': 'A'});
    await phone.engine.sync();
    await tablet.engine.sync();
    wall += 10;
    await tablet.engine.edit(SyncTable.items, 'i1', {'title': 'newer'});
    wall -= 5000; // đồng hồ máy phone chạy chậm hơn, nhưng HLC đã nhận clock từ server nên vẫn đúng thứ tự nhân quả
    await phone.engine.edit(SyncTable.items, 'i1', {'title': 'older-wall-clock'});
    await phone.engine.sync();
    await tablet.engine.sync();
    await phone.engine.sync();
    final p = await phone.row('items', 'i1');
    final t = await tablet.row('items', 'i1');
    expect(p!['title'], t!['title']);
  });

  test('sửa local chưa đẩy không bị server_row cũ ghi đè', () async {
    final a = Device('phone', server, now: now);
    await a.engine.edit(SyncTable.items, 'i1', {'kind': 'task', 'title': 'v1'});
    await a.engine.sync();
    wall += 100;
    await a.engine.edit(SyncTable.items, 'i1', {'title': 'v2 (chưa sync)'});
    // kéo lại hàng cũ từ server (ví dụ push từ máy khác) trước khi đẩy outbox
    await a.engine.sync();
    expect((await a.row('items', 'i1'))!['title'], 'v2 (chưa sync)');
  });

  test('xóa item: tombstone dây chuyền local và lan sang máy khác', () async {
    final phone = Device('phone', server, now: now);
    final tablet = Device('tablet', server, now: now);
    await phone.engine.edit(SyncTable.items, 'i1', {'kind': 'task', 'title': 'x'});
    await phone.engine.edit(SyncTable.reminders, 'r1', {'item_id': 'i1', 'trigger_kind': 'offset', 'offset_minutes': -10});
    await phone.engine.sync();
    await tablet.engine.sync();
    await phone.engine.delete(SyncTable.items, 'i1');
    expect((await phone.row('reminders', 'r1'))!['deleted_at'], isNotNull);
    await phone.engine.sync();
    await tablet.engine.sync();
    expect((await tablet.row('items', 'i1'))!['deleted_at'], isNotNull);
  });

  test('occurrence_log khóa kép, recurrences khóa item_id', () async {
    final a = Device('phone', server, now: now);
    await a.engine.edit(SyncTable.items, 'h1', {'kind': 'habit', 'title': 'Water'});
    await a.engine.edit(SyncTable.recurrences, 'h1', {'kind': 'rrule', 'rrule': 'FREQ=DAILY', 'dtstart': '2026-11-24T00:00:00.000Z'});
    await a.engine.edit(SyncTable.occurrenceLog, 'h1', {'occurrence_at': '2026-11-25T08:00:00.000Z', 'status': 'done'});
    await a.engine.sync();
    expect(server.rows.keys, contains('occurrence_log/h1|2026-11-25T08:00:00.000Z'));
    expect((await a.row('recurrences', 'h1', key: 'item_id'))!['rrule'], 'FREQ=DAILY');
  });

  test('pull nhiều trang', () async {
    final a = Device('phone', server, now: now);
    for (var i = 0; i < 7; i++) {
      await a.engine.edit(SyncTable.lists, 'l$i', {'name': 'L$i'});
    }
    await a.engine.sync();
    final b = Device('tablet', server, now: now, pullLimit: 3);
    final r = await b.engine.sync();
    expect(r.pulled, 7);
  });

  test('quota_exceeded và notes_conflict được ghi vào sync_issues cho UI', () async {
    final a = Device('phone', server, now: now);
    server.rejectQuota = (m) => m.payload['kind'] == 'appointment';
    await a.engine.edit(SyncTable.items, 'ap1', {'kind': 'appointment', 'title': 'Dentist'});
    final r = await a.engine.sync();
    expect(r.issues.single.status, MutationStatus.quotaExceeded);

    final b = Device('tablet', server, now: now);
    await a.engine.edit(SyncTable.items, 'n1', {'kind': 'task', 'title': 'n', 'notes': 'base'});
    await a.engine.sync();
    await b.engine.sync();
    wall += 10;
    await b.engine.edit(SyncTable.items, 'n1', {'notes': 'from tablet'});
    await b.engine.sync();
    wall += 10;
    // phone sửa từ bản gốc cũ
    await a.engine.edit(SyncTable.items, 'n1', {'notes': 'from phone'},
        baseClock: {'notes': (server.rows['items/n1']!['field_clock'] as Map)['title'] as String});
    final r2 = await a.engine.sync();
    expect(r2.issues.single.isNotesConflict, isTrue);
    final kinds = (await a.db.select(a.db.syncIssues).get()).map((i) => i.kind);
    expect(kinds, containsAll(['quota_exceeded', 'notes_conflict']));
  });

  test('chuyến mới bị từ chối vì hạn mức: bỏ chuyến ở máy, item + nhắc được gỡ khỏi chuyến và gửi lại', () async {
    final a = Device('phone', server, now: now);
    server
      ..checkForeignKeys = true
      ..rejectQuota = (m) => m.table == SyncTable.trips;
    await a.engine.edit(SyncTable.trips, 't1', {'title': 'Huế', 'starts_on': '2027-03-01'});
    await a.engine.edit(SyncTable.items, 'b1', {'kind': 'booking', 'title': 'Hotel', 'trip_id': 't1'});
    await a.engine.edit(SyncTable.reminders, 'r1', {'item_id': 'b1', 'trigger_kind': 'offset', 'offset_minutes': 0});
    await a.engine.edit(SyncTable.trips, 't1', {'ends_on': '2027-03-03'});
    final r = await a.engine.sync();
    expect(r.issues.map((i) => '${i.table.wire} ${i.error}'), ['trips quota_exceeded']);
    expect(r.rejectedTrips, ['t1']);
    expect(server.rows['items/b1']!['trip_id'], isNull);
    expect(server.rows['items/b1']!['title'], 'Hotel');
    expect(server.rows.containsKey('reminders/r1'), isTrue);
    expect((await a.row('trips', 't1'))!['deleted_at'], isNotNull);
    expect((await a.row('items', 'b1'))!['trip_id'], isNull);
    expect(await a.engine.pendingCount(), 0);
  });

  for (final interruptBeforeRepair in [true, false]) {
    final stage = interruptBeforeRepair ? 'trước khi gỡ chuyến' : 'sau khi gỡ chuyến, trước khi gửi lại';
    test('tắt app $stage: mở lại SQLite vẫn gửi đủ booking, chi tiết và nhắc', () async {
      final dir = await Directory.systemTemp.createTemp('remindme-trip-retry-');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/app.sqlite');
      var db = AppDatabase(NativeDatabase(file));
      addTearDown(() => db.close());
      SyncEngine openEngine(SyncApi api) => SyncEngine(db: db, api: api, clock: HlcClock('phone', now: now), deviceId: 'phone');
      server
        ..checkForeignKeys = true
        ..rejectQuota = (m) => m.table == SyncTable.trips;
      var engine = openEngine(_StopAfterFirstPush(server));
      await db.transaction(() async {
        await engine.edit(SyncTable.trips, 't', {'title': 'Huế'});
        await engine.edit(SyncTable.items, 'b', {'kind': 'booking', 'title': 'Hotel', 'trip_id': 't'});
        await engine.edit(SyncTable.bookingDetails, 'b', {'booking_type': 'hotel'});
        await engine.edit(SyncTable.reminders, 'r', {'item_id': 'b', 'trigger_kind': 'offset', 'offset_minutes': -30});
        if (interruptBeforeRepair) {
          // Còn một lô chưa gửi sau lô bị từ chối, trước lúc quét hết outbox để gỡ trip_id.
          for (var i = 4; i <= SyncEngine.pushBatchSize; i++) {
            await engine.edit(SyncTable.lists, 'list-$i', {'name': 'List $i'});
          }
        }
      });
      await expectLater(engine.sync(), throwsA(isA<StateError>().having((e) => e.message, 'message', 'app stopped')));
      expect((await db.select(db.syncIssues).get()).single.kind, 'quota_exceeded');
      expect(server.rows.containsKey('items/b'), isFalse);
      await db.close();

      db = AppDatabase(NativeDatabase(file));
      engine = openEngine(server.apiFor('phone'));
      final result = await engine.sync();
      expect(result.error, isNull);
      expect(result.issues, isEmpty);
      expect(server.rows.containsKey('trips/t'), isFalse);
      expect(server.rows['items/b'], containsPair('trip_id', null));
      expect(server.rows['items/b']!['title'], 'Hotel');
      expect(server.rows['booking_details/b']!['booking_type'], 'hotel');
      expect(server.rows['reminders/r']!['item_id'], 'b');
      expect((await db.select(db.items).getSingle()).tripId, isNull);
      expect((await db.select(db.trips).getSingle()).deletedAt, isNotNull);
      expect((await db.select(db.syncIssues).get()), hasLength(1));
      expect(await engine.pendingCount(), 0);
      expect((await engine.sync()).pushed, 0);
    });
  }

  test('quota_status được cache sau lần sync thành công; lỗi lấy hạn mức giữ cache cũ', () async {
    final a = Device('phone', server, now: now);
    expect(await a.engine.cachedQuota(), isNull);
    server.quota = {'plan': 'free', 'limits': {'max_active_trips': 1}, 'usage': {'max_active_trips': 0}, 'features': {}};
    await a.engine.sync();
    final q = (await a.engine.cachedQuota())!;
    expect(q.limit(EntitlementKey.maxActiveTrips), 1);
    server.quota = null;
    expect((await a.engine.sync()).error, isNull);
    expect((await a.engine.cachedQuota())!.plan, 'free');
  });

  test('lỗi khóa ngoại không do chuyến bị từ chối vẫn được báo, không gửi lại', () async {
    final a = Device('phone', server, now: now);
    server.checkForeignKeys = true;
    await a.engine.edit(SyncTable.items, 'x1', {'kind': 'task', 'title': 'x', 'list_id': 'missing'});
    final r = await a.engine.sync();
    expect(r.issues.map((i) => i.error), ['23503']);
    expect(r.rejectedTrips, isEmpty);
    expect(await a.engine.pendingCount(), 0);
  });

  test('session_revoked: dừng sync, giữ outbox để đẩy lại khi đăng nhập lại', () async {
    final a = Device('phone', server, now: now);
    await a.engine.edit(SyncTable.items, 'i1', {'kind': 'task', 'title': 'x'});
    server.failWith = SyncErrorCode.sessionRevoked;
    final r = await a.engine.sync();
    expect(r.sessionRevoked, isTrue);
    expect(await a.engine.pendingCount(), 1);
    server.failWith = null;
    expect((await a.engine.sync()).pushed, 1);
  });
}
