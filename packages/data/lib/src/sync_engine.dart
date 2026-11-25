import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:remindme_core/remindme_core.dart';

import 'database.dart';
import 'row_codec.dart';

/// Kết quả 1 lần đồng bộ.
class SyncReport {
  int pushed = 0;
  int pulled = 0;
  final List<MutationResult> issues = [];
  SyncErrorCode? error;

  /// Server phải kẹp clock của máy này: đồng hồ máy chạy nhanh quá 1 ngày. App nên nhắc người dùng chỉnh giờ.
  bool clockSkewDetected = false;

  /// Chuyến đi mới bị server từ chối vì vượt `max_active_trips`: đã bỏ ở máy, đặt chỗ của nó được gỡ khỏi chuyến và gửi lại.
  /// Lỗi `quota_exceeded` của chuyến vẫn nằm trong [issues] để app mở paywall.
  final List<String> rejectedTrips = [];

  /// Server báo phiên đã bị đá (ADR-013): app phải hủy thông báo đã lập lịch và đăng xuất.
  bool get sessionRevoked => error == SyncErrorCode.sessionRevoked;
}

/// Offline-first: mọi sửa ghi vào DB local + outbox trong 1 transaction, `sync()` đẩy outbox rồi kéo thay đổi.
/// Merge theo trường bằng HLC ở cả 2 phía: trường nào clock lớn hơn thắng (data-model.md §3).
class SyncEngine {
  SyncEngine({required this.db, required this.api, required this.clock, required this.deviceId, DateTime Function()? now})
      : _now = now ?? DateTime.now {
    for (final t in SyncTable.values) {
      _codecs[t] = RowCodec(db.allTables.firstWhere((x) => x.actualTableName == t.wire));
    }
  }

  final AppDatabase db;
  final SyncApi api;
  final HlcClock clock;
  final String deviceId;
  final DateTime Function() _now;
  final Map<SyncTable, RowCodec> _codecs = {};

  static const pushBatchSize = 200;
  static const _sinceKey = 'pull_since';

  // ------------------------------------------------------------------ sửa local

  /// Sửa/tạo 1 hàng. [payload] theo định dạng server (tên cột snake_case, thời gian ISO 8601, JSON lồng).
  /// [id] là `id`, hoặc `item_id` với recurrences/booking_details/occurrence_log (occurrence_log cần thêm `occurrence_at` trong payload).
  Future<Hlc> edit(SyncTable table, String id, Map<String, Object?> payload, {Map<String, String>? baseClock}) {
    return db.transaction(() async {
      final stamp = clock.send();
      final key = _key(table, id, payload);
      final full = {...payload, ...key};
      final clocks = {for (final c in full.keys) c: stamp.pack()};
      await _mergeIntoLocal(table, full, clocks, fromServer: false);
      await _enqueue(Mutation(
        table: table,
        id: id,
        op: MutationOp.upsert,
        payload: full,
        fieldClock: {for (final c in payload.keys) c: stamp.pack()},
        baseClock: baseClock,
      ));
      return stamp;
    });
  }

  /// Xóa mềm (tombstone). Xóa item thì tombstone luôn reminder/recurrence/booking/occurrence của nó, giống server.
  /// [occurrenceAt] bắt buộc với `occurrence_log` (khóa 2 cột), bỏ qua với bảng khác.
  Future<void> delete(SyncTable table, String id, {DateTime? occurrenceAt}) {
    if (table == SyncTable.occurrenceLog && occurrenceAt == null) {
      throw ArgumentError('occurrence_log cần occurrenceAt');
    }
    return db.transaction(() async {
      final codec = _codecs[table]!;
      final keys = RowCodec.keyColumns(table);
      final nowMs = _now().millisecondsSinceEpoch;
      final occ = table == SyncTable.occurrenceLog;
      await db.customUpdate(
        'UPDATE ${codec.name} SET deleted_at = ? WHERE ${keys.first} = ?${occ ? ' AND occurrence_at = ?' : ''} AND deleted_at IS NULL',
        variables: [Variable.withInt(nowMs), Variable.withString(id), if (occ) Variable.withInt(occurrenceAt!.millisecondsSinceEpoch)],
        updates: {codec.table},
      );
      if (table == SyncTable.items) {
        for (final child in [SyncTable.reminders, SyncTable.recurrences, SyncTable.bookingDetails, SyncTable.occurrenceLog]) {
          await db.customUpdate(
            'UPDATE ${child.wire} SET deleted_at = ? WHERE item_id = ? AND deleted_at IS NULL',
            variables: [Variable.withInt(nowMs), Variable.withString(id)],
            updates: {_codecs[child]!.table},
          );
        }
      }
      await _enqueue(Mutation(
        table: table,
        id: id,
        op: MutationOp.delete,
        payload: table == SyncTable.occurrenceLog
            ? {'item_id': id, 'occurrence_at': occurrenceAt!.toUtc().toIso8601String()}
            : const {},
      ));
    });
  }

  // ------------------------------------------------------------------ đồng bộ

  Future<SyncReport> sync() async {
    final report = SyncReport();
    try {
      await _push(report);
      await _pull(report);
    } on SyncException catch (e) {
      report.error = e.code;
    }
    return report;
  }

  /// Lỗi khóa ngoại của Postgres: hàng cha (chuyến, item) chưa có trên server.
  static const _fkViolation = '23503';

  Future<void> _push(SyncReport report) async {
    // Lượt 1 hoãn lỗi khóa ngoại: chúng thường do hàng cha bị từ chối trong cùng lượt (chuyến vượt hạn mức → item trỏ
    // `trip_id` tới chuyến đó → nhắc/booking_details của item). Sửa xong hàng cha thì gửi lại 1 lần, lượt 2 ghi lỗi như thường.
    final pass = _PushPass();
    while (true) {
      final batch = await (db.select(db.outbox)
            ..orderBy([(o) => OrderingTerm.asc(o.seq)])
            ..limit(pushBatchSize))
          .get();
      if (batch.isEmpty) {
        if (!pass.retried && pass.rejectedTrips.isNotEmpty) {
          await _detachRejectedTrips(pass, report);
          pass.retried = true;
          continue;
        }
        for (final (m, r) in pass.deferred) {
          await _recordIssue(m, r, report);
        }
        return;
      }
      final mutations = [for (final e in batch) Mutation.fromJson(jsonDecode(e.mutation) as Map<String, Object?>)];
      List<MutationResult> results;
      try {
        results = await api.push(deviceId, mutations);
      } on SyncException {
        await _bumpAttempts(batch);
        rethrow;
      }
      final pendingAfter = await _pendingFields(afterSeq: batch.last.seq);
      await db.transaction(() async {
        for (var i = 0; i < results.length; i++) {
          await _applyResult(mutations[i], results[i], report, pendingAfter, pass);
        }
        await (db.delete(db.outbox)..where((o) => o.seq.isIn(batch.map((e) => e.seq)))).go();
      });
      report.pushed += results.length;
    }
  }

  Future<void> _applyResult(Mutation m, MutationResult r, SyncReport report, Set<String> pendingAfter, _PushPass pass) async {
    final row = r.serverRow;
    // Trường bị kẹp: clock local (ở tương lai) phải nhường clock server, nếu không bản sửa đúng giờ từ máy khác
    // sẽ không bao giờ thắng ở máy này. Bỏ qua trường còn bản sửa mới hơn đang chờ trong outbox.
    final force = {
      for (final f in r.clampedFields)
        if (!pendingAfter.contains('${m.table.wire}/${m.id}/$f')) f,
    };
    if (r.clampedFields.isNotEmpty) report.clockSkewDetected = true;
    if (row != null) await _applyServerRow(m.table, row, forceFields: force);
    if (r.status == MutationStatus.ok) return;
    if (!pass.retried) {
      if (r.status == MutationStatus.invalid && r.error == _fkViolation) {
        pass.deferred.add((m, r));
        return;
      }
      if (m.table == SyncTable.trips && r.status == MutationStatus.quotaExceeded && await _neverSynced(SyncTable.trips, m.id)) {
        // Sửa tiếp chuyến đã bị từ chối (nới ngày) cũng bị từ chối: chỉ báo 1 lần.
        if (!pass.rejectedTrips.add(m.id)) return;
      }
    }
    await _recordIssue(m, r, report);
  }

  Future<void> _recordIssue(Mutation m, MutationResult r, SyncReport report) async {
    report.issues.add(r);
    await db.into(db.syncIssues).insert(SyncIssuesCompanion.insert(
          tableName_: m.table.wire,
          rowId: m.id,
          kind: r.error ?? r.status.wire,
          detail: Value(jsonEncode({'details': r.details, if (r.isNotesConflict) 'local_notes': m.payload['notes']})),
          createdAt: _now().millisecondsSinceEpoch,
        ));
  }

  /// Chuyến chưa từng lên server bị từ chối vì hạn mức: bỏ chuyến ở máy (đặt chỗ vẫn giữ, như xóa chuyến), gỡ `trip_id`
  /// khỏi item của nó rồi gửi lại các mutation bị lỗi khóa ngoại theo thứ tự cũ (item trước, nhắc/booking_details sau).
  Future<void> _detachRejectedTrips(_PushPass pass, SyncReport report) => db.transaction(() async {
        final trips = pass.rejectedTrips.toList();
        final nowMs = _now().millisecondsSinceEpoch;
        final unlink = clock.send().pack();
        final members = await (db.select(db.items)..where((t) => t.tripId.isIn(trips))).get();
        for (final i in members) {
          await _mergeIntoLocal(SyncTable.items, {'id': i.id, 'trip_id': null}, {'trip_id': unlink}, fromServer: false);
        }
        final tripsCodec = _codecs[SyncTable.trips]!;
        await db.customUpdate(
          'UPDATE trips SET deleted_at = ? WHERE id IN (${List.filled(trips.length, '?').join(', ')}) AND deleted_at IS NULL',
          variables: [Variable.withInt(nowMs), for (final t in trips) Variable.withString(t)],
          updates: {tripsCodec.table},
        );
        report.rejectedTrips.addAll(trips);
        final retry = [...pass.deferred]..sort((a, b) => a.$1.table.index.compareTo(b.$1.table.index));
        pass.deferred.clear();
        final unlinked = {for (final i in members) i.id};
        for (final (m, _) in retry) {
          final payload = {...m.payload}, clocks = {...m.fieldClock};
          if (m.table == SyncTable.items && trips.contains(payload['trip_id'])) {
            payload['trip_id'] = null;
            clocks['trip_id'] = unlink;
            unlinked.remove(m.id);
          }
          await _enqueue(Mutation(table: m.table, id: m.id, op: m.op, payload: payload, fieldClock: clocks, baseClock: m.baseClock));
        }
        // Item đã có trên server mà mutation gắn vào chuyến không nằm trong lượt này: gửi riêng việc gỡ `trip_id`.
        for (final id in unlinked) {
          if (!await _neverSynced(SyncTable.items, id)) {
            await _enqueue(Mutation(table: SyncTable.items, id: id, op: MutationOp.upsert, payload: {'id': id, 'trip_id': null}, fieldClock: {'trip_id': unlink}));
          }
        }
      });

  /// Hàng chưa từng được server xác nhận (version local = 0).
  Future<bool> _neverSynced(SyncTable t, String id) async {
    final keys = RowCodec.keyColumns(t);
    final r = await db.customSelect('SELECT version FROM ${t.wire} WHERE ${keys.first} = ?', variables: [Variable.withString(id)]).getSingleOrNull();
    return ((r?.data['version'] as int?) ?? 0) == 0;
  }

  Future<void> _pull(SyncReport report) async {
    var since = int.parse(await _getState(_sinceKey) ?? '0');
    while (true) {
      final page = await api.pull(since);
      await db.transaction(() async {
        for (final t in SyncTable.values) {
          for (final row in page.rows[t] ?? const <Map<String, Object?>>[]) {
            await _applyServerRow(t, row);
            report.pulled++;
          }
        }
        since = page.nextSince;
        await _setState(_sinceKey, '$since');
      });
      if (!page.hasMore) return;
    }
  }

  // ------------------------------------------------------------------ merge

  Future<void> _applyServerRow(SyncTable t, Map<String, Object?> row, {Set<String> forceFields = const {}}) async {
    final serverClocks = ((row['field_clock'] as Map<String, Object?>?) ?? const {}).cast<String, String>();
    for (final c in serverClocks.values) {
      clock.receive(Hlc.parse(c));
    }
    await _mergeIntoLocal(t, row, serverClocks, fromServer: true, forceFields: forceFields);
  }

  /// Ghi [values] vào hàng local: trường nào có clock ≥ clock local thì lấy (server thắng khi bằng nhau,
  /// vì server là nơi đã quyết LWW). Cột đồng bộ: version lấy max, tombstone không bị gỡ.
  Future<void> _mergeIntoLocal(SyncTable t, Map<String, Object?> values, Map<String, String> clocks,
      {required bool fromServer, Set<String> forceFields = const {}}) async {
    final codec = _codecs[t]!;
    final keys = RowCodec.keyColumns(t);
    final where = keys.map((k) => '$k = ?').join(' AND ');
    final keyVars = [for (final k in keys) _variable(codec.toLocal(k, values[k]))];
    final existing = await db.customSelect('SELECT * FROM ${codec.name} WHERE $where', variables: keyVars).getSingleOrNull();
    final localClocks = existing == null
        ? <String, String>{}
        : (jsonDecode(existing.data['field_clock'] as String) as Map<String, Object?>).cast<String, String>();

    final out = <String, Object?>{};
    final mergedClocks = {...localClocks};
    for (final c in codec.dataColumns) {
      if (!values.containsKey(c)) continue;
      final incoming = clocks[c] ?? '';
      final local = localClocks[c] ?? '';
      final wins = existing == null || keys.contains(c) || forceFields.contains(c) || (fromServer ? incoming.compareTo(local) >= 0 : incoming.compareTo(local) > 0);
      if (!wins) continue;
      out[c] = codec.toLocal(c, values[c]);
      if (clocks.containsKey(c)) mergedClocks[c] = incoming;
    }
    if (fromServer) {
      final v = (values['version'] as num?)?.toInt() ?? 0;
      final localV = (existing?.data['version'] as int?) ?? 0;
      out['version'] = v > localV ? v : localV;
      if (values['updated_at'] != null) out['updated_at'] = codec.toLocal('updated_at', values['updated_at']);
      if (values['device_id'] != null) out['device_id'] = values['device_id'];
      if (values['deleted_at'] != null) out['deleted_at'] = codec.toLocal('deleted_at', values['deleted_at']);
    } else {
      out['device_id'] = deviceId;
    }
    out['field_clock'] = jsonEncode(mergedClocks);

    if (existing == null) {
      final cols = out.keys.toList();
      await db.customInsert(
        'INSERT INTO ${codec.name} (${cols.join(', ')}) VALUES (${List.filled(cols.length, '?').join(', ')})',
        variables: [for (final c in cols) _variable(out[c])],
        updates: {codec.table},
      );
    } else {
      final cols = out.keys.where((c) => !keys.contains(c)).toList();
      await db.customUpdate(
        'UPDATE ${codec.name} SET ${cols.map((c) => '$c = ?').join(', ')} WHERE $where',
        variables: [for (final c in cols) _variable(out[c]), ...keyVars],
        updates: {codec.table},
      );
    }
  }

  // ------------------------------------------------------------------ tiện ích

  Map<String, Object?> _key(SyncTable t, String id, Map<String, Object?> payload) => switch (t) {
        SyncTable.recurrences || SyncTable.bookingDetails => {'item_id': id},
        SyncTable.occurrenceLog => {'item_id': id, 'occurrence_at': payload['occurrence_at']},
        _ => {'id': id},
      };

  Future<void> _enqueue(Mutation m) => db.into(db.outbox).insert(
        OutboxCompanion.insert(mutation: jsonEncode(m.toJson()), createdAt: _now().millisecondsSinceEpoch),
      );

  Future<void> _bumpAttempts(List<OutboxEntry> batch) => db.customUpdate(
        'UPDATE outbox SET attempts = attempts + 1 WHERE seq IN (${batch.map((e) => e.seq).join(',')})',
        updates: {db.outbox},
      );

  Future<String?> _getState(String key) async =>
      (await (db.select(db.syncState)..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<void> _setState(String key, String value) =>
      db.into(db.syncState).insertOnConflictUpdate(SyncStateCompanion.insert(key: key, value: value));

  /// `table/id/field` của các mutation trong outbox có seq > [afterSeq] (sửa trong lúc đang push).
  Future<Set<String>> _pendingFields({required int afterSeq}) async {
    final rows = await (db.select(db.outbox)..where((o) => o.seq.isBiggerThanValue(afterSeq))).get();
    final out = <String>{};
    for (final e in rows) {
      final m = Mutation.fromJson(jsonDecode(e.mutation) as Map<String, Object?>);
      for (final f in m.payload.keys) {
        out.add('${m.table.wire}/${m.id}/$f');
      }
    }
    return out;
  }

  Future<int> pendingCount() async => (await db.select(db.outbox).get()).length;

  static Variable<Object> _variable(Object? v) => switch (v) {
        null => const Variable(null),
        final int i => Variable.withInt(i),
        final String s => Variable.withString(s),
        final double d => Variable.withReal(d),
        final bool b => Variable.withBool(b),
        _ => Variable.withString(v.toString()),
      };
}

/// Trạng thái 1 lần push (có thể 2 lượt).
class _PushPass {
  bool retried = false;
  final List<(Mutation, MutationResult)> deferred = [];
  final Set<String> rejectedTrips = {};
}
