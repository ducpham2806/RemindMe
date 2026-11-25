import 'dart:async';
import 'dart:convert';

import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Trạng thái đồng bộ với server, cho UI (chấm trạng thái, màn phiên bị kết thúc UX §3.7).
enum RemoteSyncState {
  idle,
  syncing,
  ok,
  /// Lỗi mạng: outbox giữ nguyên, thử lại lần sau.
  offline,
  /// Chưa đăng nhập được (ví dụ project chưa bật đăng nhập ẩn danh).
  signedOut,
  /// Máy chưa có vùng (region) để tạo profile: người dùng chọn quốc gia ở Ngôn ngữ & vùng.
  regionMissing,
  /// Tài khoản đã đăng nhập ở thiết bị khác (ADR-013): ngừng đồng bộ, chờ màn đăng nhập lại.
  revoked,
  error,
}

/// Trạng thái + lần đồng bộ thành công gần nhất (giờ máy).
typedef RemoteSyncStatus = ({RemoteSyncState state, DateTime? lastOk});

/// Thông tin máy gửi lên `profile_init` / `session_claim`. [region] null thì chưa tạo được profile.
/// [calendarSystems]: hệ lịch phụ đang dùng (`profiles.calendar_systems`, ví dụ `['lunar_vi']`).
typedef DeviceProfile = ({
  String uiLocale,
  String? region,
  String homeTz,
  String platform,
  String deviceClass,
  String? appVersion,
  List<String> calendarSystems,
});

/// Luồng S1 (STATE "Tiếp theo" mục 6): đăng nhập (ẩn danh nếu chưa có phiên) → `profile_init` → `session_claim` → [SyncEngine.sync].
/// Chạy tuần tự (không chồng 2 lượt); lỗi phiên/profile thì làm lại bước thiếu rồi thử 1 lần nữa.
class RemoteSync {
  RemoteSync({required this.client, required this.engine, required this.deviceId, required this.profile});

  final SupabaseClient client;
  final SyncEngine engine;
  final String deviceId;
  final Future<DeviceProfile> Function() profile;

  final _state = StreamController<RemoteSyncStatus>.broadcast();
  RemoteSyncState _current = RemoteSyncState.idle;
  DateTime? _lastOk;
  Future<SyncReport?>? _running;
  String? _claimedSession;
  /// Cài đặt profile đã gửi lên trong lần chạy app này (tránh ghi lặp mỗi lượt).
  String? _pushedProfile;

  RemoteSyncState get state => _current;
  RemoteSyncStatus get status => (state: _current, lastOk: _lastOk);
  Stream<RemoteSyncStatus> get statuses => _state.stream;

  void _set(RemoteSyncState s) {
    _current = s;
    if (s == RemoteSyncState.ok) _lastOk = DateTime.now();
    if (!_state.isClosed) _state.add(status);
  }

  /// Một lượt đồng bộ; gọi lúc mở app, khi app trở lại, sau khi sửa (đã gom).
  Future<SyncReport?> run() => _running ??= _run().whenComplete(() => _running = null);

  bool _paused = false;

  /// Đang đổi tài khoản (giữa lúc xác nhận mã và lúc người dùng đồng ý): không đồng bộ, không claim phiên.
  Future<void> pause() async {
    _paused = true;
    await _running;
  }

  /// Sau khi đổi/đăng xuất tài khoản: quên phiên đã claim, bỏ trạng thái revoked, rồi đồng bộ lại.
  Future<SyncReport?> resume({bool reset = false}) {
    _paused = false;
    if (reset) {
      _claimedSession = null;
      _pushedProfile = null;
      _lastOk = null;
      _set(RemoteSyncState.idle);
    }
    return run();
  }

  Future<SyncReport?> _run() async {
    if (_paused || _current == RemoteSyncState.revoked) return null;
    _set(RemoteSyncState.syncing);
    try {
      if (!await _ensureSignedIn()) {
        _set(RemoteSyncState.signedOut);
        return null;
      }
      final p = await profile();
      if (p.region == null) {
        _set(RemoteSyncState.regionMissing);
        return null;
      }
      await _ensureClaimed(p);
      var report = await engine.sync();
      if (report.error == SyncErrorCode.profileMissing || report.error == SyncErrorCode.sessionNotClaimed) {
        _claimedSession = null;
        await _ensureClaimed(p);
        report = await engine.sync();
      }
      if (report.error == null) await _pushProfile(p);
      _set(switch (report.error) {
        null => RemoteSyncState.ok,
        SyncErrorCode.network => RemoteSyncState.offline,
        SyncErrorCode.sessionRevoked => RemoteSyncState.revoked,
        SyncErrorCode.unauthenticated => RemoteSyncState.signedOut,
        _ => RemoteSyncState.error,
      });
      return report;
    } on SyncException catch (e) {
      _set(e.code == SyncErrorCode.sessionRevoked
          ? RemoteSyncState.revoked
          : e.code == SyncErrorCode.network
              ? RemoteSyncState.offline
              : RemoteSyncState.error);
      return null;
    } on AuthException {
      _set(RemoteSyncState.signedOut);
      return null;
    } on Exception {
      // Mạng chập chờn khi đăng nhập/refresh token: thử lại lượt sau.
      _set(RemoteSyncState.offline);
      return null;
    }
  }

  /// Ngôn ngữ, quốc gia ngày lễ, hệ lịch phụ chọn trên máy → `profiles` (server dùng cho email, gợi ý, đếm hạn mức theo vùng).
  /// `profile_init` chỉ tạo profile lần đầu nên đổi sau đó phải ghi ở đây. Không đổi `home_tz` theo máy (đi du lịch không đổi nhà).
  /// Lỗi thì bỏ qua, lượt sau thử lại.
  Future<void> _pushProfile(DeviceProfile p) async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;
    final values = {'ui_locale': p.uiLocale, 'region': p.region, 'calendar_systems': p.calendarSystems};
    final key = jsonEncode(values);
    if (key == _pushedProfile) return;
    try {
      await client.from('profiles').update(values).eq('id', uid);
      _pushedProfile = key;
    } on PostgrestException {
      // RLS/phiên hết hạn: lượt đồng bộ sau thử lại.
    } on Exception {
      // mạng
    }
  }

  Future<bool> _ensureSignedIn() async {
    if (client.auth.currentSession != null) return true;
    await client.auth.signInAnonymously();
    return client.auth.currentSession != null;
  }

  /// `profile_init` (không đổi profile đã có) rồi `session_claim` cho phiên của JWT hiện tại, mỗi phiên 1 lần.
  Future<void> _ensureClaimed(DeviceProfile p) async {
    final sid = _sessionId();
    if (sid != null && sid == _claimedSession) return;
    try {
      await client.rpc<Object?>('profile_init', params: {'ui_locale': p.uiLocale, 'region': p.region, 'home_tz': p.homeTz});
      await client.rpc<Object?>('session_claim', params: {
        'device_id': deviceId,
        'device': {'platform': p.platform, 'device_class': p.deviceClass, 'app_version': ?p.appVersion, 'locale': p.uiLocale, 'tz': p.homeTz},
      });
    } on PostgrestException catch (e) {
      throw SyncException(SyncErrorCode.fromMessage(e.message), e.message);
    }
    _claimedSession = sid;
  }

  /// Phiên (claim `session_id`) của access token hiện tại.
  String? get sessionId => _sessionId();

  /// Claim `session_id` trong access token (Supabase Auth đặt sẵn).
  String? _sessionId() {
    final token = client.auth.currentSession?.accessToken;
    if (token == null) return null;
    try {
      return JwtDecoder.claims(token)['session_id'] as String?;
    } on FormatException {
      return null;
    }
  }

  Future<void> dispose() => _state.close();
}

/// Đọc phần payload của JWT (không kiểm chữ ký: server kiểm, app chỉ cần đọc claim của token chính nó).
abstract final class JwtDecoder {
  static Map<String, Object?> claims(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw const FormatException('jwt');
    final normalized = base64Url.normalize(parts[1]);
    return (jsonDecode(utf8.decode(base64Url.decode(normalized))) as Map).cast<String, Object?>();
  }
}
