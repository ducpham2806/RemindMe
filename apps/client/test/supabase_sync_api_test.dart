import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:remindme_client/data/remote/remote_sync.dart';
import 'package:remindme_client/data/remote/supabase_sync_api.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// PostgREST giả: ghi lại request RPC, trả body/status cho trước.
SupabaseClient client(Future<http.Response> Function(http.Request) handler, List<http.Request> seen) => SupabaseClient(
      'https://example.supabase.co',
      'sb_publishable_test',
      httpClient: MockClient((r) async {
        seen.add(r);
        final res = await handler(r);
        // postgrest đọc response.request (method, header Accept) khi phân tích kết quả.
        return http.Response(res.body, res.statusCode, headers: res.headers, request: r);
      }),
    );

http.Response json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  test('push gửi đúng tham số RPC sync_push và đọc kết quả từng mutation', () async {
    final seen = <http.Request>[];
    final api = SupabaseSyncApi(client((_) async => json([
          {'table': 'items', 'id': 'a', 'key': {'id': 'a'}, 'status': 'ok', 'version': 7, 'server_row': {'id': 'a', 'version': 7}},
        ]), seen));
    final clock = Hlc(1764000000000, 1, 'dev1');
    final res = await api.push('dev1', [Mutation.edit(SyncTable.items, 'a', {'title': 'X'}, clock)]);
    expect(seen.single.url.path, '/rest/v1/rpc/sync_push');
    final body = jsonDecode(seen.single.body) as Map<String, Object?>;
    expect(body['device_id'], 'dev1');
    expect(((body['mutations']! as List).single as Map)['field_clock'], {'title': clock.pack()});
    expect((res.single.status, res.single.version), (MutationStatus.ok, 7));
  });

  test('pull và quota_status đọc JSON của server', () async {
    final seen = <http.Request>[];
    final api = SupabaseSyncApi(client((r) async => r.url.path.endsWith('sync_pull')
        ? json({'rows': {'lists': [{'id': 'l1'}]}, 'next_since': 12, 'has_more': false})
        : json({'plan': 'free', 'limits': {'max_lists': 5}, 'usage': {}, 'features': {}}), seen));
    final page = await api.pull(3, limit: 100);
    expect((page.nextSince, page.hasMore, page.rows[SyncTable.lists]!.single['id']), (12, false, 'l1'));
    expect(jsonDecode(seen.first.body), {'since': 3, 'lim': 100});
    expect((await api.quotaStatus())['plan'], 'free');
  });

  test('lỗi server đổi sang SyncErrorCode: phiên bị kết thúc, thiếu profile, chưa đăng nhập, mạng', () async {
    Future<SyncErrorCode> codeFor(Future<http.Response> Function(http.Request) h) async {
      try {
        await SupabaseSyncApi(client(h, [])).pull(0);
      } on SyncException catch (e) {
        return e.code;
      }
      fail('không ném lỗi');
    }

    expect(await codeFor((_) async => json({'code': 'PT403', 'message': 'session_revoked', 'hint': null, 'details': null}, 403)),
        SyncErrorCode.sessionRevoked);
    expect(await codeFor((_) async => json({'code': 'P0002', 'message': 'profile_missing: call profile_init first'}, 400)),
        SyncErrorCode.profileMissing);
    expect(await codeFor((_) async => json({'code': '42501', 'message': 'permission denied for function sync_pull'}, 401)),
        SyncErrorCode.unauthenticated, reason: 'gọi bằng publishable key, chưa đăng nhập');
    expect(await codeFor((_) async => throw const SocketException('no route')), SyncErrorCode.network);
  });

  test('JwtDecoder đọc claim session_id của access token', () {
    String part(Object o) => base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
    final token = '${part({'alg': 'HS256'})}.${part({'sub': 'u1', 'session_id': 's-123'})}.sig';
    expect(JwtDecoder.claims(token)['session_id'], 's-123');
  });
}
