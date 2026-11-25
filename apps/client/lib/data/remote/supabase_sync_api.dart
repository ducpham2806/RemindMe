import 'dart:async';
import 'dart:io' show SocketException;

import 'package:remindme_core/remindme_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [SyncApi] thật: gọi RPC `sync_push` / `sync_pull` / `quota_status` qua PostgREST (ADR-012, api-spec.md §1).
/// Lỗi cấp request đổi sang [SyncException]: message của exception Postgres là mã (`session_revoked`, `profile_missing: …`),
/// lỗi mạng là [SyncErrorCode.network] (engine giữ outbox, thử lại lần sau).
class SupabaseSyncApi implements SyncApi {
  SupabaseSyncApi(this.client);
  final SupabaseClient client;

  @override
  Future<List<MutationResult>> push(String deviceId, List<Mutation> mutations) async {
    final res = await _rpc('sync_push', {'device_id': deviceId, 'mutations': [for (final m in mutations) m.toJson()]});
    return [for (final r in res as List<Object?>) MutationResult.fromJson((r! as Map).cast<String, Object?>())];
  }

  @override
  Future<PullPage> pull(int since, {int limit = 500}) async =>
      PullPage.fromJson(((await _rpc('sync_pull', {'since': since, 'lim': limit}))! as Map).cast<String, Object?>());

  @override
  Future<Map<String, Object?>> quotaStatus() async => ((await _rpc('quota_status'))! as Map).cast<String, Object?>();

  Future<Object?> _rpc(String fn, [Map<String, Object?>? params]) async {
    try {
      return await client.rpc<Object?>(fn, params: params);
    } on PostgrestException catch (e) {
      throw SyncException(errorCodeOf(e), e.message);
    } on SocketException catch (e) {
      throw SyncException(SyncErrorCode.network, e.message);
    } on TimeoutException {
      throw const SyncException(SyncErrorCode.network, 'timeout');
    } on AuthException catch (e) {
      throw SyncException(SyncErrorCode.unauthenticated, e.message);
    }
  }

  /// `28000` = chưa đăng nhập, `42501` = gọi bằng role anon (RPC chỉ cấp cho người đã đăng nhập), PGRST301/303 = JWT
  /// hỏng/hết hạn; còn lại theo message (`session_revoked`, `profile_missing: call profile_init first`…).
  static SyncErrorCode errorCodeOf(PostgrestException e) {
    if (const {'28000', '42501', 'PGRST301', 'PGRST303', '401'}.contains(e.code)) return SyncErrorCode.unauthenticated;
    final code = SyncErrorCode.fromMessage(e.message);
    if (code != SyncErrorCode.unknown) return code;
    return e.code == '22023' ? SyncErrorCode.invalidBatch : SyncErrorCode.unknown;
  }
}
