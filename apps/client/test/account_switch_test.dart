import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:remindme_client/data/remote/account.dart';
import 'package:remindme_client/data/remote/remote_sync.dart';
import 'package:remindme_client/data/remote/supabase_sync_api.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, Object?> _session(String user) {
  String encode(Object value) => base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final header = encode({'alg': 'HS256', 'typ': 'JWT'});
  final payload = encode({'sub': user, 'session_id': 'session-$user', 'exp': 4102444800});
  return {
    'access_token': '$header.$payload.sig',
    'token_type': 'bearer',
    'expires_in': 3600,
    'refresh_token': 'refresh-$user',
    'user': {'id': user, 'aud': 'authenticated', 'created_at': '2026-11-25T00:00:00Z', 'app_metadata': {}, 'user_metadata': {}},
  };
}

class _Server {
  final pushes = <(String, String)>[];
  final claims = <String>[];

  SupabaseClient client() => SupabaseClient('https://example.supabase.co', 'test-key',
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit, autoRefreshToken: false),
      httpClient: MockClient((r) async {
        http.Response reply(Object data, [int status = 200]) =>
            http.Response(jsonEncode(data), status, headers: {'content-type': 'application/json'}, request: r);
        if (r.url.path == '/auth/v1/verify') {
          final body = jsonDecode(r.body) as Map<String, Object?>;
          if (body['token'] == '123456') return reply(_session(body['email'] == 'a@example.org' ? 'A' : 'B'));
          return reply({'code': 'otp_expired', 'error_code': 'otp_expired', 'msg': 'Invalid OTP'}, 403);
        }
        final jwt = r.headers['Authorization']!.split(' ').last;
        final user = JwtDecoder.claims(jwt)['sub']! as String;
        switch (r.url.path) {
          case '/auth/v1/user':
            return reply(_session(user)['user']!);
          case '/rest/v1/rpc/session_status':
            expect(user, 'B');
            return reply({'will_replace': []});
          case '/rest/v1/rpc/session_claim':
            claims.add(user);
            return reply({});
          case '/rest/v1/rpc/profile_init':
            return reply({});
          case '/rest/v1/rpc/sync_push':
            final body = jsonDecode(r.body) as Map<String, Object?>;
            final mutations = (body['mutations']! as List<Object?>).cast<Map<String, Object?>>();
            for (final m in mutations) {
              final payload = m['payload']! as Map<String, Object?>;
              pushes.add((user, payload['title']! as String));
            }
            return reply([for (final m in mutations) {'id': m['id'], 'table': m['table'], 'status': 'ok'}]);
          case '/rest/v1/rpc/sync_pull':
            return reply({'rows': {}, 'next_since': 0, 'has_more': false});
          case '/rest/v1/rpc/quota_status':
            return reply({'plan': 'free', 'usage': {}, 'limits': {}, 'features': {}});
          case '/rest/v1/profiles':
            return http.Response('', 204, request: r);
          default:
            throw StateError('Unexpected request ${r.url.path}');
        }
      }));
}

Future<DeviceProfile> _profile() async => (
  uiLocale: 'vi', region: 'VN', homeTz: 'Asia/Ho_Chi_Minh', platform: 'android',
  deviceClass: 'phone', appVersion: null, calendarSystems: <String>[],
);

class _App {
  _App(File file, _Server server) : db = AppDatabase(NativeDatabase(file)), client = server.client() {
    engine = SyncEngine(db: db, api: SupabaseSyncApi(client), clock: HlcClock('device'), deviceId: 'device');
    sync = RemoteSync(client: client, engine: engine, deviceId: 'device', profile: _profile);
    account = SupabaseAccount(client: client, engine: engine, sync: sync, deviceId: 'device',
        deviceProfile: _profile, createVerificationClient: server.client);
  }

  final AppDatabase db;
  final SupabaseClient client;
  late final SyncEngine engine;
  late final RemoteSync sync;
  late final SupabaseAccount account;

  Future<void> close() async {
    await sync.dispose();
    await client.dispose();
    await db.close();
  }
}

void main() {
  late Directory dir;
  late File file;
  late _Server server;
  late _App app;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('remindme-switch-');
    file = File('${dir.path}/app.sqlite');
    server = _Server();
    app = _App(file, server);
    await app.client.auth.recoverSession(jsonEncode(_session('A')));
  });
  tearDown(() async {
    await app.close();
    await dir.delete(recursive: true);
  });

  test('đóng app sau OTP trước khi xác nhận: mở lại vẫn gửi việc đang chờ bằng phiên A', () async {
    await ItemsRepository(app.engine).create(title: 'Việc riêng của A');
    final result = await app.account.verify('b@example.org', '123456', OtpMode.signIn);
    expect(result.switched, isTrue);
    final persisted = jsonEncode(app.client.auth.currentSession!.toJson());
    await app.close();
    app = _App(file, server);
    await app.client.auth.recoverSession(persisted);
    expect(app.account.current?.userId, 'A');
    expect(await app.engine.pendingCount(), 1);
    await app.sync.run();
    expect(server.claims, ['A']);
    expect(server.pushes, [('A', 'Việc riêng của A')]);
    expect(await app.engine.pendingCount(), 0);
  });

  test('sai OTP rồi quay lại tạo việc: sync tiếp tục cho A', () async {
    await expectLater(app.account.verify('b@example.org', '000000', OtpMode.signIn),
        throwsA(isA<AccountException>().having((e) => e.code, 'code', AccountError.invalidCode)));
    await ItemsRepository(app.engine).create(title: 'Việc sau OTP sai');
    await app.sync.run();
    expect(app.sync.state, RemoteSyncState.ok);
    expect(server.pushes, [('A', 'Việc sau OTP sai')]);
    expect(await app.engine.pendingCount(), 0);
  });

  test('đăng nhập lại đúng tài khoản giữ cả việc lẫn hàng đợi', () async {
    await ItemsRepository(app.engine).create(title: 'Giữ lại');
    final result = await app.account.verify('a@example.org', '123456', OtpMode.signIn);
    expect(result.switched, isFalse);
    expect(app.account.current?.userId, 'A');
    expect((await app.db.select(app.db.items).get()).single.title, 'Giữ lại');
    expect(server.pushes, [('A', 'Giữ lại')]);
  });

  test('hủy giữ phiên A, chỉ xác nhận mới xóa dữ liệu A rồi đồng bộ B', () async {
    await ItemsRepository(app.engine).create(title: 'Của A');
    await app.account.verify('b@example.org', '123456', OtpMode.signIn);
    await app.account.cancelSwitch();
    expect(app.account.current?.userId, 'A');
    expect(await app.engine.pendingCount(), 1);
    await app.account.verify('b@example.org', '123456', OtpMode.signIn);
    await app.account.finishSwitch();
    expect(app.account.current?.userId, 'B');
    expect(await app.db.select(app.db.items).get(), isEmpty);
    expect(await app.engine.pendingCount(), 0);
    expect(server.claims, ['B']);
    expect(server.pushes, isEmpty);
  });
}
