import 'package:remindme_core/remindme_core.dart';

/// Server giả trong bộ nhớ, mô phỏng ngữ nghĩa `sync_push`/`sync_pull` (LWW theo trường, version tăng, tombstone).
/// Hành vi chi tiết (quota, RLS, phiên) được kiểm bằng pgTAP và contract test với Postgres thật.
class FakeServer {
  final Map<String, Map<String, Object?>> rows = {}; // '<table>/<key>' -> row
  int _version = 0;
  SyncErrorCode? failWith;
  bool Function(Mutation m)? rejectQuota;

  /// Mô phỏng khóa ngoại của Postgres: item trỏ `trip_id`/`list_id` chưa có, hoặc hàng con trỏ `item_id` chưa có → invalid 23503.
  bool checkForeignKeys = false;

  /// Trả về cho `quota_status()`; null = lỗi mạng.
  Map<String, Object?>? quota;

  MutationResult? _foreignKey(Mutation m) {
    if (!checkForeignKeys || m.op == MutationOp.delete) return null;
    final refs = <String, Object?>{
      if (m.table == SyncTable.items) ...{'trips': m.payload['trip_id'], 'lists': m.payload['list_id']},
      if (m.table != SyncTable.items && m.payload.containsKey('item_id')) 'items': m.payload['item_id'],
    };
    for (final e in refs.entries) {
      if (e.value != null && !rows.containsKey('${e.key}/${e.value}')) {
        return MutationResult(table: m.table, id: m.id, status: MutationStatus.invalid, error: '23503');
      }
    }
    return null;
  }

  FakeApi apiFor(String device) => FakeApi(this, device);

  String _k(Mutation m) => m.table == SyncTable.occurrenceLog
      ? '${m.table.wire}/${m.payload['item_id']}|${m.payload['occurrence_at']}'
      : '${m.table.wire}/${m.id}';

  MutationResult apply(String device, Mutation m) {
    final key = _k(m);
    final existing = rows[key];
    if (m.op == MutationOp.delete) {
      if (existing != null) {
        existing['deleted_at'] = DateTime.utc(2026).toIso8601String();
        existing['version'] = ++_version;
      }
      return MutationResult(table: m.table, id: m.id, status: MutationStatus.ok, serverRow: existing);
    }
    if (existing != null && existing['deleted_at'] != null) {
      return MutationResult(table: m.table, id: m.id, status: MutationStatus.conflict, error: 'deleted', serverRow: existing);
    }
    if (_foreignKey(m) case final fk?) return fk;
    if (existing == null && (rejectQuota?.call(m) ?? false)) {
      return MutationResult(table: m.table, id: m.id, status: MutationStatus.quotaExceeded, error: 'quota_exceeded',
          details: {'key': 'max_active_appointments', 'limit': 10, 'used': 10});
    }
    final row = existing ?? <String, Object?>{'field_clock': <String, String>{}};
    final clocks = (row['field_clock'] as Map).cast<String, String>();
    var conflict = false;
    for (final e in m.payload.entries) {
      final inc = m.fieldClock[e.key] ?? '';
      final ex = clocks[e.key] ?? '';
      if (e.key == 'notes' && m.baseClock?['notes'] != null && m.baseClock!['notes'] != ex && row['notes'] != e.value) {
        conflict = true;
        continue;
      }
      if (existing == null || inc.compareTo(ex) > 0) {
        row[e.key] = e.value;
        if (m.fieldClock.containsKey(e.key)) clocks[e.key] = inc;
      }
    }
    row['field_clock'] = clocks;
    row['device_id'] = device;
    row['version'] = ++_version;
    rows[key] = row;
    return MutationResult(
      table: m.table, id: m.id,
      status: conflict ? MutationStatus.conflict : MutationStatus.ok,
      error: conflict ? 'notes_conflict' : null,
      version: _version, serverRow: Map.of(row),
    );
  }

  PullPage pull(int since, int limit) {
    final changed = rows.entries.where((e) => (e.value['version'] as int) > since).toList()
      ..sort((a, b) => (a.value['version'] as int).compareTo(b.value['version'] as int));
    final page = changed.take(limit).toList();
    final out = <SyncTable, List<Map<String, Object?>>>{};
    for (final e in page) {
      out.putIfAbsent(SyncTable.fromWire(e.key.split('/').first), () => []).add(Map.of(e.value));
    }
    return PullPage(rows: out, nextSince: page.isEmpty ? since : page.last.value['version'] as int, hasMore: changed.length > limit);
  }
}

class FakeApi implements SyncApi {
  FakeApi(this.server, this.device);
  final FakeServer server;
  final String device;
  int pullLimit = 500;

  @override
  Future<List<MutationResult>> push(String deviceId, List<Mutation> mutations) async {
    if (server.failWith != null) throw SyncException(server.failWith!);
    return [for (final m in mutations) server.apply(device, m)];
  }

  @override
  Future<PullPage> pull(int since, {int limit = 500}) async {
    if (server.failWith != null) throw SyncException(server.failWith!);
    return server.pull(since, pullLimit);
  }

  @override
  Future<Map<String, Object?>> quotaStatus() async {
    if (server.failWith != null) throw SyncException(server.failWith!);
    return server.quota ?? (throw const SyncException(SyncErrorCode.network));
  }
}
