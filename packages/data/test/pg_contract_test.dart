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
}
