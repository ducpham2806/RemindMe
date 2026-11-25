// Chạy với project Supabase thật (không chạy trong CI mặc định):
//   REMINDME_LIVE=1 flutter test test/live_supabase_test.dart --dart-define-from-file=env/dev.json
// Cần bật "Allow anonymous sign-ins" trong Authentication. Test tạo 1 user ẩn danh; dọn bằng SQL (xem docs/guides).
import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remindme_client/data/remote/remote_sync.dart';
import 'package:remindme_client/data/remote/supabase_config.dart';
import 'package:remindme_client/data/remote/supabase_sync_api.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final live = Platform.environment['REMINDME_LIVE'] == '1' && SupabaseConfig.isConfigured;

  test('đăng nhập ẩn danh → profile_init → session_claim → push việc mới → pull lại trên máy thứ 2', () async {
    final client = SupabaseClient(SupabaseConfig.url, SupabaseConfig.publishableKey,
        authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit));
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    const device = 'live-test-1';
    final engine = SyncEngine(db: db, api: SupabaseSyncApi(client), clock: HlcClock(device), deviceId: device);
    Future<DeviceProfile> profile() async =>
        (uiLocale: 'vi-VN', region: 'VN', homeTz: 'Asia/Ho_Chi_Minh', platform: 'android', deviceClass: 'phone', appVersion: null);
    final sync = RemoteSync(client: client, engine: engine, deviceId: device, profile: profile);

    final itemId = await ItemsRepository(engine).create(title: 'Live sync test');
    final report = await sync.run();
    expect(sync.state, RemoteSyncState.ok, reason: 'report: ${report?.error}');
    expect(report!.pushed, greaterThanOrEqualTo(1));

    // Máy thứ 2 cùng tài khoản: DB trống, kéo về phải có việc vừa tạo + Inbox do profile_init tạo.
    final db2 = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    final engine2 = SyncEngine(db: db2, api: SupabaseSyncApi(client), clock: HlcClock('live-test-2'), deviceId: 'live-test-2');
    expect((await engine2.sync()).error, isNull);
    expect((await (db2.select(db2.items)..where((t) => t.id.equals(itemId))).getSingle()).title, 'Live sync test');
    expect(await (db2.select(db2.lists)..where((t) => t.isInbox.equals(true))).get(), hasLength(1));
    expect((await engine.cachedQuota())!.plan, 'free');

    await client.auth.signOut();
    await db.close();
    await db2.close();
  }, skip: live ? false : 'cần REMINDME_LIVE=1 và --dart-define-from-file=env/dev.json');
}
