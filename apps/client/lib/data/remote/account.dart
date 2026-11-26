import 'dart:async';
import 'dart:convert';

import 'package:remindme_data/remindme_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'remote_sync.dart';

/// Tài khoản đang dùng trên máy. Ẩn danh = chưa gắn email (dữ liệu vẫn sao lưu, nhưng chỉ máy này truy cập được).
class AccountInfo {
  const AccountInfo({required this.userId, this.email, required this.isAnonymous});
  final String userId;
  final String? email;
  final bool isAnonymous;
}

/// Cách xác nhận mã: gắn email vào user ẩn danh hiện tại (giữ dữ liệu) hoặc đăng nhập tài khoản đã có (đổi dữ liệu trên máy).
enum OtpMode { link, signIn }

enum AccountError { invalidEmail, rateLimited, invalidCode, network, unknown }

class AccountException implements Exception {
  const AccountException(this.code, [this.message]);
  final AccountError code;
  final String? message;
  @override
  String toString() => 'AccountException(${code.name}${message == null ? '' : ': $message'})';
}

/// 1 phiên đăng nhập (bảng `user_sessions`, UX §3.7). Không có IP, chỉ quốc gia.
class SessionInfo {
  const SessionInfo({
    required this.id,
    this.platform,
    this.deviceClass,
    this.deviceModel,
    this.country,
    required this.active,
    required this.current,
    this.createdAt,
    this.lastSeenAt,
    this.endedAt,
    this.endReason,
  });

  factory SessionInfo.fromJson(Map<String, Object?> j, {String? currentId}) => SessionInfo(
        id: (j['id'] ?? j['session_id'] ?? '') as String,
        platform: j['platform'] as String?,
        deviceClass: j['device_class'] as String?,
        deviceModel: j['device_model'] as String?,
        country: j['country'] as String?,
        active: (j['status'] ?? 'active') == 'active',
        current: currentId != null && (j['id'] ?? j['session_id']) == currentId,
        createdAt: _date(j['created_at']),
        lastSeenAt: _date(j['last_seen_at']),
        endedAt: _date(j['ended_at']),
        endReason: j['end_reason'] as String?,
      );

  static DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;

  final String id;
  final String? platform, deviceClass, deviceModel, country, endReason;
  final bool active, current;
  final DateTime? createdAt, lastSeenAt, endedAt;
}

/// Kết quả xác nhận mã. [switched]: đã xác minh một tài khoản khác, cần người dùng đồng ý (dữ liệu trên máy sẽ được thay,
/// [willReplace] là các máy sẽ bị đăng xuất) rồi gọi [AccountApi.finishSwitch] hoặc [AccountApi.cancelSwitch]. Phiên hiện tại giữ nguyên trong lúc chờ.
typedef VerifyResult = ({bool switched, List<SessionInfo> willReplace});

/// Đăng nhập bằng email + mã (OTP), không mật khẩu (UX C35/C36). UI chỉ phụ thuộc interface này (test dùng bản giả).
abstract interface class AccountApi {
  AccountInfo? get current;
  Stream<AccountInfo?> get changes;
  Future<OtpMode> sendCode(String email);
  Future<void> resend(String email, OtpMode mode);
  Future<VerifyResult> verify(String email, String code, OtpMode mode);
  Future<void> finishSwitch();
  Future<void> cancelSwitch();
  Future<void> signOut();

  /// Xóa tài khoản và dữ liệu đồng bộ (RPC `account_delete`, security-privacy.md §6), rồi xóa dữ liệu trên máy;
  /// app quay về dùng ẩn danh với tài khoản mới.
  Future<void> deleteAccount();
  Future<List<SessionInfo>> sessions();

  /// Máy đã đăng nhập thay phiên này (`session_status.replaced_by`), cho màn "Bạn đã được đăng xuất".
  Future<({String? device, DateTime? at})> revokedBy();
}

/// Bản thật trên Supabase Auth.
/// - Máy đang ẩn danh, email chưa có tài khoản: `updateUser(email)` → mã `email_change` → user ẩn danh thành tài khoản email, cùng id, giữ dữ liệu.
/// - Email đã có tài khoản: `signInWithOtp` → mã `email` → sang tài khoản đó; dữ liệu trên máy (của user ẩn danh) được thay bằng dữ liệu tài khoản.
/// Email template "Magic Link" và "Change Email Address" phải có `{{ .Token }}` (guides/backend-setup.md §3).
class SupabaseAccount implements AccountApi {
  SupabaseAccount({
    required this.client,
    required this.engine,
    required this.sync,
    required this.deviceId,
    required this.deviceProfile,
    required this.createVerificationClient,
    this.clearLocalFiles,
  });

  final SupabaseClient client;
  final SyncEngine engine;
  final RemoteSync sync;
  final String deviceId;
  final Future<DeviceProfile> Function() deviceProfile;
  final SupabaseClient Function() createVerificationClient;
  Session? _pendingSession;
  /// Xóa tệp chỉ có trên máy (bản gốc đã nhập) cùng lúc với dữ liệu local.
  final Future<void> Function()? clearLocalFiles;

  Future<void> _resetLocal() async {
    await engine.resetLocalData();
    await clearLocalFiles?.call();
  }

  @override
  AccountInfo? get current {
    final u = client.auth.currentUser;
    return u == null ? null : AccountInfo(userId: u.id, email: u.email, isAnonymous: u.isAnonymous);
  }

  @override
  Stream<AccountInfo?> get changes => client.auth.onAuthStateChange.map((_) => current);

  @override
  Future<OtpMode> sendCode(String email) => _guard(() async {
        if (current?.isAnonymous ?? false) {
          try {
            await client.auth.updateUser(UserAttributes(email: email));
            return OtpMode.link;
          } on AuthException catch (e) {
            if (e.code != 'email_exists' && e.statusCode != '422') rethrow;
          }
        }
        await client.auth.signInWithOtp(email: email, shouldCreateUser: current == null);
        return OtpMode.signIn;
      });

  @override
  Future<void> resend(String email, OtpMode mode) => _guard(() => mode == OtpMode.link
      ? client.auth.resend(type: OtpType.emailChange, email: email)
      : client.auth.signInWithOtp(email: email, shouldCreateUser: false));

  @override
  Future<VerifyResult> verify(String email, String code, OtpMode mode) => _guard(() async {
        _pendingSession = null;
        if (mode == OtpMode.link) {
          await client.auth.verifyOTP(type: OtpType.emailChange, email: email, token: code.trim());
          await sync.run();
          return (switched: false, willReplace: const <SessionInfo>[]);
        }

        // Chỉ client chính có lưu phiên. Đóng app ở màn xác nhận vẫn mở lại tài khoản cũ.
        final verification = createVerificationClient();
        try {
          final result = await verification.auth.verifyOTP(type: OtpType.email, email: email, token: code.trim());
          final session = result.session;
          if (session == null) throw const AccountException(AccountError.invalidCode);
          if (session.user.id == current?.userId) {
            await _activate(session, replaceData: false);
            return (switched: false, willReplace: const <SessionInfo>[]);
          }
          final p = await deviceProfile();
          final status = await verification.rpc<Object?>('session_status',
              params: {'device_id': deviceId, 'platform': p.platform, 'device_class': p.deviceClass});
          final will = ((status as Map?)?['will_replace'] as List<Object?>?) ?? const [];
          final devices = [for (final w in will) SessionInfo.fromJson((w! as Map).cast<String, Object?>())];
          _pendingSession = session;
          return (switched: true, willReplace: devices);
        } finally {
          await verification.dispose();
        }
      });

  Future<void> _activate(Session session, {required bool replaceData}) async {
    await sync.pause();
    try {
      if (session.isExpired || session.refreshToken == null) throw const AccountException(AccountError.invalidCode);
      if (replaceData) {
        await _resetLocal();
        await client.auth.recoverSession(jsonEncode(session.toJson()));
      } else {
        await client.auth.setSession(session.refreshToken!, accessToken: session.accessToken);
      }
    } finally {
      await sync.resume(reset: true);
    }
  }

  @override
  Future<void> finishSwitch() => _guard(() async {
        final session = _pendingSession;
        if (session == null) throw const AccountException(AccountError.invalidCode);
        _pendingSession = null;
        await _activate(session, replaceData: true);
      });

  @override
  Future<void> cancelSwitch() async {
    _pendingSession = null;
  }

  @override
  Future<void> signOut() => _guard(() async {
        await sync.pause();
        try {
          await client.rpc<Object?>('session_end');
        } on PostgrestException {
          // Phiên đã bị kết thúc ở server: vẫn đăng xuất trên máy.
        }
        await client.auth.signOut();
        await _resetLocal();
        await sync.resume(reset: true);
      });

  @override
  Future<void> deleteAccount() => _guard(() async {
        await sync.pause();
        try {
          await client.rpc<Object?>('account_delete');
        } on Object {
          await sync.resume();
          rethrow;
        }
        // User đã bị xóa ở server: chỉ bỏ phiên trên máy, không gọi /logout.
        await client.auth.signOut(scope: SignOutScope.local);
        await _resetLocal();
        await sync.resume(reset: true);
      });

  @override
  Future<List<SessionInfo>> sessions() => _guard(() async {
        final rows = await client.from('user_sessions').select().order('created_at', ascending: false).limit(20);
        final sid = sync.sessionId;
        return [for (final r in rows) SessionInfo.fromJson(r, currentId: sid)];
      });

  @override
  Future<({String? device, DateTime? at})> revokedBy() async {
    try {
      final s = await client.rpc<Object?>('session_status');
      final by = ((s as Map?)?['replaced_by'] as Map?)?.cast<String, Object?>();
      return (device: (by?['device_model'] ?? by?['platform']) as String?, at: DateTime.tryParse('${by?['signed_in_at']}'));
    } on Exception {
      return (device: null, at: null);
    }
  }

  static Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on AuthRetryableFetchException catch (e) {
      throw AccountException(AccountError.network, e.message);
    } on AuthException catch (e) {
      throw AccountException(switch (e.code) {
        'validation_failed' || 'email_address_invalid' || 'email_address_not_authorized' => AccountError.invalidEmail,
        'over_email_send_rate_limit' || 'over_request_rate_limit' => AccountError.rateLimited,
        'otp_expired' || 'invalid_credentials' || 'bad_code_verifier' => AccountError.invalidCode,
        'otp_disabled' || 'user_not_found' => AccountError.invalidEmail,
        _ => e.statusCode == '429' ? AccountError.rateLimited : AccountError.unknown,
      }, e.message);
    } on PostgrestException catch (e) {
      throw AccountException(AccountError.unknown, e.message);
    }
  }
}
