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
