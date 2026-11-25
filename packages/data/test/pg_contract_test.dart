// Contract test: SyncEngine (Dart) ↔ RPC thật trong Postgres (supabase/migrations).
// Chạy sau `tools/db-test.sh` (DB đã có migrations), với biến môi trường:
//   REMINDME_PG=1 PGHOST=localhost PGPORT=5432 PGUSER=postgres PGPASSWORD=... DB_TEST_NAME=remindme_test
// Không có REMINDME_PG thì bỏ qua (máy dev không có Postgres).
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:postgres/postgres.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:test/test.dart';

final env = Platform.environment;

/// SyncApi gọi RPC như PostgREST: đặt JWT claims + role authenticated trong 1 transaction.
class PgSyncApi implements SyncApi {
  PgSyncApi(this.conn, this.userId, this.sessionId);
  final Connection conn;
  final String userId;
  final String sessionId;

  Future<Object?> _rpc(String sql, Map<String, Object?> params) async {
    try {
      return await conn.runTx((tx) async {
        await tx.execute(Sql.named("select set_config('request.jwt.claims', @c, true)"),
            parameters: {'c': '{"sub":"$userId","role":"authenticated","session_id":"$sessionId"}'});
        await tx.execute('set local role authenticated');
        final r = await tx.execute(Sql.named(sql), parameters: params);
        return r.first.first;
      });
    } on ServerException catch (e) {
      throw SyncException(SyncErrorCode.fromMessage(e.message), e.message);
    }
  }

  @override
  Future<List<MutationResult>> push(String deviceId, List<Mutation> mutations) async {
    final r = await _rpc('select public.sync_push(@d, @m::jsonb)', {
      'd': deviceId,
      'm': TypedValue(Type.jsonb, [for (final m in mutations) m.toJson()]),
    });
    return [for (final x in r! as List<Object?>) MutationResult.fromJson((x! as Map).cast<String, Object?>())];
  }

  @override
  Future<PullPage> pull(int since, {int limit = 500}) async {
    final r = await _rpc('select public.sync_pull(@s, @l)', {'s': since, 'l': limit});
    return PullPage.fromJson((r! as Map).cast<String, Object?>());
  }

  @override
  Future<Map<String, Object?>> quotaStatus() async => ((await _rpc('select public.quota_status()', {}))! as Map).cast<String, Object?>();

  Future<Object?> call(String sql, [Map<String, Object?> params = const {}]) => _rpc(sql, params);
}

void main() {
  final enabled = env['REMINDME_PG'] == '1';
  late Connection conn;

  setUpAll(() async {
    if (!enabled) return;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    conn = await Connection.open(
      Endpoint(
        host: env['PGHOST'] ?? 'localhost',
        port: int.parse(env['PGPORT'] ?? '5432'),
        database: env['DB_TEST_NAME'] ?? 'remindme_test',
        username: env['PGUSER'] ?? 'postgres',
        password: env['PGPASSWORD'],
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
  });

  tearDownAll(() async {
    if (enabled) await conn.close();
  });

  /// Tạo user + profile; trả hàm đăng nhập 1 thiết bị (tạo phiên + session_claim) → SyncEngine.
  Future<Future<(SyncEngine, AppDatabase)> Function(String device, String platform, String cls, {int Function()? now})> newUser(
      {bool plus = false}) async {
    final uid = uuidV7();
    await conn.execute(Sql.named('insert into auth.users (id) values (@u::uuid)'), parameters: {'u': uid});
    final bootstrap = PgSyncApi(conn, uid, uuidV7());
    await bootstrap.call("select public.profile_init('en-US', 'US', 'America/New_York')");
    if (plus) {
      await conn.execute(
          Sql.named('insert into public.subscriptions (user_id, plan_id, status, current_period_end) '
              "values (@u::uuid, 'plus', 'active', now() + interval '30 days')"),
          parameters: {'u': uid});
    }
    return (String device, String platform, String cls, {int Function()? now}) async {
      final sid = uuidV7();
      await conn.execute(Sql.named('insert into auth.sessions (id, user_id) values (@s::uuid, @u::uuid)'),
          parameters: {'s': sid, 'u': uid});
      final api = PgSyncApi(conn, uid, sid);
      await api.call('select public.session_claim(@d, @i::jsonb)', {
        'd': device,
        'i': TypedValue(Type.jsonb, {'platform': platform, 'device_class': cls}),
      });
      final db = AppDatabase(NativeDatabase.memory());
      return (SyncEngine(db: db, api: api, clock: HlcClock(device, now: now), deviceId: device), db);
    };
  }

  Future<Map<String, Object?>> row(AppDatabase db, String id) async =>
      (await db.customSelect('SELECT * FROM items WHERE id = ?', variables: [Variable.withString(id)]).getSingle()).data;

  test('Plus: điện thoại + tablet sửa offline 2 trường, hội tụ qua sync_push/sync_pull thật', () async {
    final login = await newUser(plus: true);
    final (phone, phoneDb) = await login('phone-1', 'ios', 'phone');
    final (tablet, tabletDb) = await login('ipad-1', 'ipados', 'tablet');
    final id = uuidV7();
    await phone.edit(SyncTable.items, id, {'kind': 'task', 'title': 'Report', 'starts_at': '2026-12-01T09:00:00Z', 'tags': ['work']});
    expect((await phone.sync()).error, isNull);
    await tablet.sync();
    expect((await row(tabletDb, id))['tags'], '["work"]');

    await phone.edit(SyncTable.items, id, {'title': 'Report Q4'});
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await tablet.edit(SyncTable.items, id, {'priority': 3});
    await tablet.sync();
    await phone.sync();
    await tablet.sync();
    for (final db in [phoneDb, tabletDb]) {
      final r = await row(db, id);
      expect(r['title'], 'Report Q4');
      expect(r['priority'], 3);
      expect(r['starts_at'], DateTime.utc(2026, 12, 1, 9).millisecondsSinceEpoch);
    }
  }, skip: enabled ? false : 'đặt REMINDME_PG=1 để chạy với Postgres');

  test('Free: lịch hẹn thứ 11 bị từ chối, issue có chi tiết quota', () async {
    final login = await newUser();
    final (phone, _) = await login('phone-1', 'android', 'phone');
    for (var i = 0; i < 11; i++) {
      await phone.edit(SyncTable.items, uuidV7(), {
        'kind': 'appointment', 'title': 'A$i',
        'starts_at': DateTime.now().toUtc().add(Duration(days: i + 1)).toIso8601String(),
      });
    }
    final r = await phone.sync();
    expect(r.issues, hasLength(1));
    expect(r.issues.single.status, MutationStatus.quotaExceeded);
    expect(r.issues.single.details!['key'], 'max_active_appointments');
  }, skip: enabled ? false : 'đặt REMINDME_PG=1 để chạy với Postgres');

  test('Free: đăng nhập máy thứ 2 thì máy 1 nhận session_revoked, outbox được giữ', () async {
    final login = await newUser();
    final (phone, _) = await login('phone-1', 'ios', 'phone');
    await phone.edit(SyncTable.items, uuidV7(), {'kind': 'task', 'title': 'chưa sync'});
    await login('tablet-1', 'android', 'tablet');
    final r = await phone.sync();
    expect(r.sessionRevoked, isTrue);
    expect(await phone.pendingCount(), 1);
  }, skip: enabled ? false : 'đặt REMINDME_PG=1 để chạy với Postgres');

  test('Máy đặt sai giờ (năm 2030): server kẹp clock, bản sửa sau từ máy đúng giờ vẫn thắng ở cả 2 máy', () async {
    final login = await newUser(plus: true);
    final skewedNow = DateTime.utc(2030, 1, 1).millisecondsSinceEpoch;
    final (phone, phoneDb) = await login('phone-1', 'android', 'phone', now: () => skewedNow);
    final (tablet, tabletDb) = await login('tab-1', 'android', 'tablet');
    final id = uuidV7();
    await phone.edit(SyncTable.items, id, {'kind': 'task', 'title': 'from 2030'});
    final r1 = await phone.sync();
    expect(r1.clockSkewDetected, isTrue);
    final clocks = jsonDecode((await row(phoneDb, id))['field_clock'] as String) as Map<String, Object?>;
    expect((clocks['title']! as String).startsWith('$skewedNow'), isFalse, reason: 'clock title nhận giờ server');

    await Future<void>.delayed(const Duration(milliseconds: 5));
    await tablet.sync();
    await tablet.edit(SyncTable.items, id, {'title': 'fixed'});
    await tablet.sync();
    await phone.sync();
    expect((await row(phoneDb, id))['title'], 'fixed');
    expect((await row(tabletDb, id))['title'], 'fixed');
  }, skip: enabled ? false : 'đặt REMINDME_PG=1 để chạy với Postgres');

  test('xong 1 lần của chuỗi lặp rồi hoàn tác: occurrence_log khóa 2 cột qua RPC thật', () async {
    final login = await newUser();
    final (phone, _) = await login('phone-1', 'ios', 'phone');
    final repo = ItemsRepository(phone);
    final id = await repo.create(title: 'Pills', startsAt: DateTime.utc(2026, 12, 1, 1), tz: 'Asia/Ho_Chi_Minh',
        recurrence: {'kind': 'rrule', 'rrule': 'FREQ=DAILY'}, recurrenceStart: DateTime.utc(2026, 12, 1, 1), reminderOffsets: [0]);
    final occ = DateTime.utc(2026, 12, 2, 1);
    await repo.completeOccurrence(id, occ);
    var r = await phone.sync();
    expect(r.issues, isEmpty, reason: '${r.issues.map((i) => '${i.table} ${i.error} ${i.id}')}');
    await repo.reopenOccurrence(id, occ);
    r = await phone.sync();
    expect(r.issues, isEmpty, reason: '${r.issues.map((i) => '${i.table} ${i.error} ${i.id}')}');
    final rows = await conn.execute(
        Sql.named('select deleted_at is not null as gone from public.occurrence_log where item_id = @i::uuid'), parameters: {'i': id});
    expect(rows.single.first, isTrue);
  }, skip: enabled ? false : 'đặt REMINDME_PG=1 để chạy với Postgres');

  test('nhập file: hàng imports + item có checklist/location/end_tz/import_id được RPC thật nhận', () async {
    final login = await newUser();
    final (phone, _) = await login('phone-1', 'android', 'phone');
    final repo = ImportsRepository(phone, ItemsRepository(phone), ListsRepository(phone));
    final r = await repo.commit(
      const ImportRecord(kind: 'email', mime: 'message/rfc822', bytes: 2048, docType: 'hotel', docLanguage: 'vi'),
      [
        ImportedItem(title: 'Biển Xanh', kind: 'event', startsAt: DateTime.utc(2026, 12, 21, 7), tz: 'Asia/Ho_Chi_Minh',
            endsAt: DateTime.utc(2026, 12, 23, 5), endTz: 'Asia/Ho_Chi_Minh', locationText: 'Đà Nẵng', listName: 'Du lịch', reminderOffsets: const [0]),
        const ImportedItem(title: 'Mua sơn', startDate: '2026-12-12', done: true, checklist: [(text: 'chống gỉ', done: false)]),
      ],
      deviceTz: 'Asia/Ho_Chi_Minh',
    );
    final s = await phone.sync();
    expect(s.issues, isEmpty, reason: '${s.issues.map((i) => '${i.table} ${i.error} ${i.id}')}');
    final rows = await conn.execute(
        Sql.named('select count(*) from public.items where import_id = @i::uuid and (checklist is not null or location is not null)'),
        parameters: {'i': r.importId});
    expect(rows.single.first, 2);
    final imp = await conn.execute(Sql.named('select kind, status from public.imports where id = @i::uuid'), parameters: {'i': r.importId});
    expect(imp.single.toList(), ['email', 'committed']);
  }, skip: enabled ? false : 'đặt REMINDME_PG=1 để chạy với Postgres');

  test('chuyến đi + booking_details + nhắc tuyệt đối; vé đổi giờ cập nhật item cũ qua RPC thật', () async {
    final login = await newUser();
    final (phone, _) = await login('phone-1', 'android', 'phone');
    final repo = ImportsRepository(phone, ItemsRepository(phone), ListsRepository(phone));
    ImportedItem flight(DateTime at, {String? update}) => ImportedItem(
          title: 'ZZ 245',
          kind: 'booking',
          startsAt: at,
          tz: 'Asia/Ho_Chi_Minh',
          endsAt: at.add(const Duration(hours: 2)),
          endTz: 'Asia/Ho_Chi_Minh',
          reminderOffsets: const [-1440, -180],
          tripIndex: 0,
          updateItemId: update,
          booking: const {
            'booking_type': 'flight',
            'confirmation_code': 'XQ7K2M',
            'carrier_code': 'ZZ',
            'number': '245',
            'origin': {'code': 'SGN', 'tz': 'Asia/Ho_Chi_Minh', 'terminal': '1'},
            'destination': {'code': 'HAN', 'tz': 'Asia/Ho_Chi_Minh'},
            'seat': '14C',
            'class': 'Economy',
            'price': {'amount': '1890000', 'currency': 'VND'},
            'extraction_meta': {'tier': 't2', 'field_confidence': {'starts_at': 0.6}},
          },
        );
    final first = await repo.commit(
      const ImportRecord(kind: 'text', docType: 'flight', tierUsed: 't1t2'),
      [
        flight(DateTime.utc(2027, 1, 21, 3, 30)),
        ImportedItem(
          title: 'Hoa Sen',
          kind: 'booking',
          startsAt: DateTime.utc(2027, 1, 21, 7),
          tz: 'Asia/Ho_Chi_Minh',
          absoluteReminders: [DateTime.utc(2027, 1, 20, 11)],
          tripIndex: 0,
          booking: const {'booking_type': 'hotel', 'confirmation_code': 'HS-1', 'check_in_at': '2027-01-21T07:00:00.000Z'},
        ),
      ],
      deviceTz: 'Asia/Ho_Chi_Minh',
      trips: const [TripDraft(title: 'Hà Nội', destination: 'Hanoi', startsOn: '2027-01-21', endsOn: '2027-01-23')],
    );
    var s = await phone.sync();
    expect(s.issues, isEmpty, reason: '${s.issues.map((i) => '${i.table} ${i.error} ${i.id}')}');
    final trip = await conn.execute(Sql.named('select title, starts_on::text, ends_on::text from public.trips where id = @t::uuid'),
        parameters: {'t': first.tripIds.single});
    expect(trip.single.toList(), ['Hà Nội', '2027-01-21', '2027-01-23']);
    final b = await conn.execute(
        Sql.named("select b.booking_type, b.origin->>'terminal', b.price->>'currency', b.passengers is null, i.kind, i.trip_id = @t::uuid "
            'from public.booking_details b join public.items i on i.id = b.item_id where b.item_id = @i::uuid'),
        parameters: {'i': first.itemIds.first, 't': first.tripIds.single});
    expect(b.single.toList(), ['flight', '1', 'VND', true, 'booking', true]);
    final abs = await conn.execute(Sql.named("select count(*) from public.reminders where item_id = @i::uuid and trigger_kind = 'absolute' and at is not null"),
        parameters: {'i': first.itemIds.last});
    expect(abs.single.first, 1);

    final second = await repo.commit(const ImportRecord(kind: 'text', docType: 'flight', tierUsed: 't1t2'),
        [flight(DateTime.utc(2027, 1, 21, 5), update: first.itemIds.first)],
        deviceTz: 'Asia/Ho_Chi_Minh', trips: [TripDraft(existingTripId: first.tripIds.single, startsOn: '2027-01-21', endsOn: '2027-01-23')]);
    expect(second.updatedItemIds, [first.itemIds.first]);
    s = await phone.sync();
    expect(s.issues, isEmpty, reason: '${s.issues.map((i) => '${i.table} ${i.error} ${i.id}')}');
    final moved = await conn.execute(Sql.named("select to_char(starts_at at time zone 'UTC', 'HH24:MI') from public.items where id = @i::uuid"),
        parameters: {'i': first.itemIds.first});
    expect(moved.single.first, '05:00');
  }, skip: enabled ? false : 'đặt REMINDME_PG=1 để chạy với Postgres');

  test('Free: chuyến thứ 2 vượt max_active_trips thì bị bỏ, đặt chỗ + nhắc + booking_details vẫn lên server', () async {
    final login = await newUser();
    final (phone, db) = await login('phone-1', 'android', 'phone');
    final repo = ImportsRepository(phone, ItemsRepository(phone), ListsRepository(phone), trips: TripsRepository(phone));
    ImportedItem hotel(String code, DateTime at) => ImportedItem(
          title: 'Hotel $code',
          kind: 'booking',
          startsAt: at,
          tz: 'Asia/Ho_Chi_Minh',
          absoluteReminders: [at.subtract(const Duration(hours: 13))],
          tripIndex: 0,
          booking: {'booking_type': 'hotel', 'confirmation_code': code},
        );
    await repo.commit(const ImportRecord(kind: 'text', docType: 'hotel', tierUsed: 't1t2'), [hotel('H-1', DateTime.utc(2027, 2, 1, 7))],
        deviceTz: 'Asia/Ho_Chi_Minh', trips: const [TripDraft(title: 'Đà Nẵng', startsOn: '2027-02-01', endsOn: '2027-02-03')]);
    expect((await phone.sync()).issues, isEmpty);
    final quota = (await phone.cachedQuota())!;
    expect(quota.plan, 'free');
    expect(quota.limit(EntitlementKey.maxActiveTrips), 1);
    expect(quota.used(EntitlementKey.maxActiveTrips), 1);

    final second = await repo.commit(const ImportRecord(kind: 'text', docType: 'hotel', tierUsed: 't1t2'),
        [hotel('H-2', DateTime.utc(2027, 3, 1, 7)), hotel('H-3', DateTime.utc(2027, 3, 2, 7))],
        deviceTz: 'Asia/Ho_Chi_Minh', trips: const [TripDraft(title: 'Huế', startsOn: '2027-03-01', endsOn: '2027-03-03')]);
    final r = await phone.sync();
    expect(r.issues.map((i) => '${i.table.wire} ${i.error}'), ['trips quota_exceeded'], reason: '${r.issues.map((i) => i.details)}');
    expect(r.issues.single.details!['key'], 'max_active_trips');
    expect(r.rejectedTrips, second.tripIds);
    final server = await conn.execute(
        Sql.named('select count(*) filter (where i.trip_id is null), count(b.item_id), '
            "(select count(*) from public.reminders m where m.item_id = any(@ids::uuid[]) and m.trigger_kind = 'absolute') "
            'from public.items i left join public.booking_details b on b.item_id = i.id where i.id = any(@ids::uuid[])'),
        parameters: {'ids': second.itemIds});
    expect(server.single.toList(), [2, 2, 2]);
    final local = await TripsRepository(phone).trips();
    expect(local.map((t) => t.title), ['Đà Nẵng']);
    expect((await row(db, second.itemIds.first))['trip_id'], isNull);
    expect(await phone.pendingCount(), 0);
    expect((await phone.sync()).issues, isEmpty);
  }, skip: enabled ? false : 'đặt REMINDME_PG=1 để chạy với Postgres');
}
