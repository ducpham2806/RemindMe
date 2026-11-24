import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:remindme_core/remindme_core.dart';

/// Chuyển hàng giữa định dạng server (JSON của PostgREST) và cột SQLite local, dựa vào kiểu cột Drift.
/// Server: timestamptz là chuỗi ISO 8601, jsonb/mảng là JSON lồng. Local: epoch ms, chuỗi JSON.
class RowCodec {
  RowCodec(this.table)
      : columns = {
          for (final c in table.$columns)
            c.name: c.type == DriftSqlType.int
                ? ColumnKind.int
                : c.type == DriftSqlType.bool
                    ? ColumnKind.bool
                    : c.type == DriftSqlType.string
                        ? ColumnKind.string
                        : ColumnKind.other
        };

  final TableInfo<Table, Object?> table;
  final Map<String, ColumnKind> columns;

  static const metaColumns = {'version', 'updated_at', 'deleted_at', 'device_id', 'field_clock'};

  /// Cột dữ liệu (không gồm cột đồng bộ) mà client nhận/gửi.
  Iterable<String> get dataColumns => columns.keys.where((c) => !metaColumns.contains(c));

  Object? toLocal(String column, Object? v) {
    if (v == null) return null;
    final type = columns[column];
    if (type == ColumnKind.int) {
      if (v is String) return DateTime.parse(v).millisecondsSinceEpoch;
      if (v is bool) return v ? 1 : 0;
      return (v as num).toInt();
    }
    if (type == ColumnKind.bool) return (v as bool) ? 1 : 0;
    if (type == ColumnKind.string) return (v is Map || v is List) ? jsonEncode(v) : v.toString();
    return v;
  }

  String get name => table.actualTableName;

  static List<String> keyColumns(SyncTable t) => switch (t) {
        SyncTable.recurrences || SyncTable.bookingDetails => const ['item_id'],
        SyncTable.occurrenceLog => const ['item_id', 'occurrence_at'],
        _ => const ['id'],
      };
}

enum ColumnKind { int, bool, string, other }
