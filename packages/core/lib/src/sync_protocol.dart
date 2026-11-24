import 'hlc.dart';

/// Giao thức RPC `sync_push` / `sync_pull` (api-spec.md §1). Giữ đúng tên trường JSON của server.
enum MutationOp { upsert, delete }

/// Bảng đồng bộ, cùng thứ tự áp dụng an toàn với khóa ngoại (cha trước con).
enum SyncTable {
  lists,
  trips,
  imports,
  items,
  recurrences,
  reminders,
  bookingDetails('booking_details'),
  occurrenceLog('occurrence_log');

  const SyncTable([this._wire]);
  final String? _wire;
  String get wire => _wire ?? name;

  static SyncTable fromWire(String s) => values.firstWhere((t) => t.wire == s);
}

class Mutation {
  Mutation({
    required this.table,
    required this.id,
    required this.op,
    this.payload = const {},
    this.fieldClock = const {},
    this.baseClock,
  });

  /// Một lần sửa local: mọi trường trong [payload] mang cùng 1 clock.
  factory Mutation.edit(SyncTable table, String id, Map<String, Object?> payload, Hlc clock, {Map<String, String>? baseClock}) =>
      Mutation(
        table: table,
        id: id,
        op: MutationOp.upsert,
        payload: payload,
        fieldClock: {for (final k in payload.keys) k: clock.pack()},
        baseClock: baseClock,
      );

  factory Mutation.fromJson(Map<String, Object?> json) => Mutation(
        table: SyncTable.fromWire(json['table'] as String),
        id: json['id'] as String,
        op: MutationOp.values.byName(json['op'] as String),
        payload: (json['payload'] as Map<String, Object?>?) ?? const {},
        fieldClock: ((json['field_clock'] as Map<String, Object?>?) ?? const {}).cast<String, String>(),
        baseClock: (json['base_clock'] as Map<String, Object?>?)?.cast<String, String>(),
      );

  final SyncTable table;
  final String id;
  final MutationOp op;
  final Map<String, Object?> payload;
  final Map<String, String> fieldClock;
  final Map<String, String>? baseClock;

  Map<String, Object?> toJson() => {
        'table': table.wire,
        'id': id,
        'op': op.name,
        if (op == MutationOp.upsert || payload.isNotEmpty) 'payload': payload,
        if (op == MutationOp.upsert) 'field_clock': fieldClock,
        if (baseClock != null) 'base_clock': baseClock,
      };
}

enum MutationStatus {
  ok,
  conflict,
  quotaExceeded('quota_exceeded'),
  invalid;

  const MutationStatus([this._wire]);
  final String? _wire;
  String get wire => _wire ?? name;
  static MutationStatus fromWire(String s) => values.firstWhere((v) => v.wire == s);
}

class MutationResult {
  const MutationResult({
    required this.table,
    required this.id,
    required this.status,
    this.version,
    this.serverRow,
    this.error,
    this.details,
    this.clampedFields = const [],
  });

  factory MutationResult.fromJson(Map<String, Object?> json) => MutationResult(
        table: SyncTable.fromWire(json['table'] as String),
        id: json['id'] as String?,
        status: MutationStatus.fromWire(json['status'] as String),
        version: (json['version'] as num?)?.toInt(),
        serverRow: json['server_row'] as Map<String, Object?>?,
        error: json['error'] as String?,
        details: json['details'] as Map<String, Object?>?,
        clampedFields: ((json['clamped'] as List<Object?>?) ?? const []).cast<String>(),
      );

  final SyncTable table;
  final String? id;
  final MutationStatus status;
  final int? version;
  final Map<String, Object?>? serverRow;
  final String? error;
  final Map<String, Object?>? details;

  /// Trường có clock ở tương lai quá xa bị server kẹp về giờ server (máy đặt sai giờ).
  final List<String> clampedFields;

  bool get isNotesConflict => status == MutationStatus.conflict && error == 'notes_conflict';
  bool get isDeletedOnServer => status == MutationStatus.conflict && error == 'deleted';
}

class PullPage {
  const PullPage({required this.rows, required this.nextSince, required this.hasMore});

  factory PullPage.fromJson(Map<String, Object?> json) => PullPage(
        rows: ((json['rows'] as Map<String, Object?>?) ?? const {}).map((k, v) => MapEntry(
              SyncTable.fromWire(k),
              (v as List<Object?>).cast<Map<String, Object?>>(),
            )),
        nextSince: (json['next_since'] as num).toInt(),
        hasMore: json['has_more'] as bool,
      );

  final Map<SyncTable, List<Map<String, Object?>>> rows;
  final int nextSince;
  final bool hasMore;
}

/// Lỗi cấp request mà server trả (message của exception Postgres / HTTP 403 qua PostgREST).
enum SyncErrorCode {
  unauthenticated,
  sessionMissing('session_missing'),
  sessionNotClaimed('session_not_claimed'),
  sessionRevoked('session_revoked'),
  profileMissing('profile_missing'),
  invalidBatch('invalid'),
  network,
  unknown;

  const SyncErrorCode([this._wire]);
  final String? _wire;
  String get wire => _wire ?? name;

  /// Message server có thể kèm phần giải thích sau dấu ':' (ví dụ 'profile_missing: call profile_init first').
  static SyncErrorCode fromMessage(String? message) {
    final head = (message ?? '').split(':').first.trim();
    return values.firstWhere((v) => v.wire == head, orElse: () => unknown);
  }

  /// Phải đăng xuất và hủy thông báo đã lập lịch (reminder-engine.md §8, UX §3.7).
  bool get endsSession => this == sessionRevoked;
}

class SyncException implements Exception {
  const SyncException(this.code, [this.message]);
  final SyncErrorCode code;
  final String? message;
  @override
  String toString() => 'SyncException(${code.wire}${message == null ? '' : ': $message'})';
}

/// Lớp gọi server. Bản thật dùng `supabase_flutter` (`rpc('sync_push')`); test dùng bản giả.
abstract interface class SyncApi {
  Future<List<MutationResult>> push(String deviceId, List<Mutation> mutations);
  Future<PullPage> pull(int since, {int limit = 500});
}
