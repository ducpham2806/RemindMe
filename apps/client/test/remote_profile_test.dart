import 'dart:convert';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:remindme_client/data/remote/remote_sync.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Server đồng bộ rỗng (push/pull không có gì).
class _EmptyApi implements SyncApi {
  @override
  Future<List<MutationResult>> push(String deviceId, List<Mutation> mutations) async => const [];
  @override
  Future<PullPage> pull(int since, {int limit = 500}) async => PullPage(rows: const {}, nextSince: since, hasMore: false);
  @override
  Future<Map<String, Object?>> quotaStatus() async => {'plan': 'free', 'limits': {}, 'usage': {}, 'features': {}};
}

String _jwt(Map<String, Object?> claims) {
  String part(Object o) => base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${part({'alg': 'HS256', 'typ': 'JWT'})}.${part(claims)}.sig';
}

http.Response _json(Object body, http.Request r, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'}, request: r);

void main() {
  test('đồng bộ xong thì ghi ngôn ngữ, quốc gia, hệ lịch vào profiles; không đổi thì không ghi lại; đổi thì ghi', () async {
    final seen = <http.Request>[];
    final token = _jwt({'sub': 'u1', 'session_id': 's1', 'exp': 4102444800, 'role': 'authenticated', 'aud': 'authenticated'});
    final client = SupabaseClient('https://example.supabase.co', 'sb_publishable_test',
        authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit, autoRefreshToken: false),
        httpClient: MockClient((r) async {
          seen.add(r);
          if (r.url.path == '/auth/v1/signup') {
            return _json({
              'access_token': token,
              'token_type': 'bearer',
              'expires_in': 3600,
              'expires_at': 4102444800,
              'refresh_token': 'r1',
              'user': {'id': 'u1', 'aud': 'authenticated', 'role': 'authenticated', 'created_at': '2026-11-25T00:00:00Z',
                'app_metadata': {}, 'user_metadata': {}, 'is_anonymous': true},
            }, r);
          }
          if (r.url.path.startsWith('/rest/v1/rpc/')) return _json({}, r);
          return http.Response('', 204, request: r);
        }));
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    addTearDown(db.close);
    final engine = SyncEngine(db: db, api: _EmptyApi(), clock: HlcClock('d1'), deviceId: 'd1');
    var calendars = const ['lunar_vi'];
    final sync = RemoteSync(
      client: client,
      engine: engine,
      deviceId: 'd1',
      profile: () async => (uiLocale: 'vi-VN', region: 'VN', homeTz: 'Asia/Ho_Chi_Minh', platform: 'android', deviceClass: 'phone',
          appVersion: null, calendarSystems: calendars),
    );
    List<http.Request> profileWrites() => seen.where((r) => r.url.path == '/rest/v1/profiles').toList();

    await sync.run();
    expect(sync.state, RemoteSyncState.ok);
    final w = profileWrites().single;
    expect(w.method, 'PATCH');
    expect(w.url.queryParameters['id'], 'eq.u1');
    expect(jsonDecode(w.body), {'ui_locale': 'vi-VN', 'region': 'VN', 'calendar_systems': ['lunar_vi']},
        reason: 'không ghi home_tz: đi du lịch không đổi múi giờ nhà');

    await sync.run();
    expect(profileWrites(), hasLength(1));

    calendars = const [];
    await sync.run();
    expect(profileWrites(), hasLength(2));
    expect(jsonDecode(profileWrites().last.body)['calendar_systems'], isEmpty);
  });
}
