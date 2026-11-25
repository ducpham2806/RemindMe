import 'dart:convert';

import 'package:remindme_core/remindme_core.dart';

import 'database.dart';
import 'row_codec.dart';

/// Xuất dữ liệu (security-privacy.md §6, US-52): tạo trên máy, không cần server.
/// - [json]: `remindme-export.json`, có `export_version`, một mảng cho mỗi bảng đồng bộ (hàng chưa xóa), thời điểm ISO 8601 UTC
///   kèm cột `tz` IANA của hàng; bỏ cột nội bộ của đồng bộ (`version`, `device_id`, `field_clock`).
/// - [ics]: `calendar.ics`, VEVENT cho sự kiện/đặt chỗ và VTODO cho việc; RRULE giữ nguyên; lặp âm lịch trải phẳng 2 năm.
class DataExporter {
  DataExporter(this.db);
  final AppDatabase db;

  static const exportVersion = 1;
  static const _internal = {'version', 'device_id', 'field_clock'};

  /// Cột số nguyên là thời điểm (epoch ms ở máy).
  static bool _isInstant(String column) =>
      column.endsWith('_at') || const {'at', 'dtstart', 'until', 'snoozed_until'}.contains(column);

  /// Cột chữ chứa JSON (mảng/đối tượng) ở máy.
  static const _jsonColumns = {'tags', 'checklist', 'calendar', 'exdates', 'location', 'passengers', 'segments', 'extra', 'geofence'};

  Future<List<Map<String, Object?>>> _rows(SyncTable t) async {
    final codec = RowCodec(db.allTables.firstWhere((x) => x.actualTableName == t.wire));
    final rows = await db.customSelect('select * from ${codec.name} where deleted_at is null').get();
    return [
      for (final r in rows)
        {
          for (final e in r.data.entries)
            if (!_internal.contains(e.key)) e.key: _value(codec, e.key, e.value),
        },
    ];
  }

  static Object? _value(RowCodec codec, String column, Object? v) {
    if (v == null) return null;
    switch (codec.columns[column]) {
      case ColumnKind.int when _isInstant(column):
        return DateTime.fromMillisecondsSinceEpoch((v as num).toInt(), isUtc: true).toIso8601String();
      case ColumnKind.bool:
        return v is bool ? v : v == 1;
      case ColumnKind.string when _jsonColumns.contains(column) && v is String:
        try {
          return jsonDecode(v);
        } on FormatException {
          return v;
        }
      default:
        return v;
    }
  }

  /// `remindme-export.json`.
  Future<String> json({required DateTime now}) async {
    final out = <String, Object?>{
      'export_version': exportVersion,
      'exported_at': now.toUtc().toIso8601String(),
    };
    for (final t in SyncTable.values) {
      out[t.wire] = await _rows(t);
    }
    return const JsonEncoder.withIndent('  ').convert(out);
  }

  /// `calendar.ics` (RFC 5545). Giờ có múi giờ ghi `TZID=<IANA>` + giờ tường (giữ đúng qua DST), cả ngày ghi `VALUE=DATE`.
  Future<String> ics({required DateTime now, required String deviceTz, required String prodId}) async {
    final items = await (db.select(db.items)..where((t) => t.deletedAt.isNull())).get();
    final recs = {for (final r in await (db.select(db.recurrences)..where((t) => t.deletedAt.isNull())).get()) r.itemId: r};
    final stamp = _utc(now);
    final lines = <String>['BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:$prodId', 'CALSCALE:GREGORIAN'];
    final today = TimeZones.toWall(now.toUtc(), deviceTz).date;
    for (final i in items) {
      if (i.startsAt == null && i.startDate == null) continue;
      final tz = i.tz ?? deviceTz;
      final todo = i.kind == null || i.kind == 'task';
      final allDay = i.startDate != null && (i.allDay == true || i.startsAt == null);
      final start = allDay ? CivilDateTime(CivilDate.parse(i.startDate!)) : TimeZones.toWall(DateTime.fromMillisecondsSinceEpoch(i.startsAt!, isUtc: true), tz);
      final rec = recs[i.id];
      Recurrence? lunar;
      String? rrule;
      if (rec != null && rec.kind == 'rrule') rrule = rec.rrule;
      if (rec != null && rec.kind == 'calendar') {
        lunar = Recurrence.fromRow({'kind': 'calendar', 'calendar': jsonDecode(rec.calendar!), 'workdays_region': rec.workdaysRegion});
      }
      // Lặp âm lịch: mỗi lần 1 thành phần riêng (UID khác nhau) trong 2 năm tới.
      final starts = lunar == null ? [start] : lunar.between(start, today, today.addDays(730));
      for (final (n, s) in starts.indexed) {
        lines
          ..add(todo ? 'BEGIN:VTODO' : 'BEGIN:VEVENT')
          ..add('UID:${i.id}${lunar == null ? '' : '-$n'}')
          ..add('DTSTAMP:$stamp')
          ..add(_prop(todo ? 'DUE' : 'DTSTART', s, tz))
          ..add(_text('SUMMARY', i.title ?? ''));
        if (!todo && i.endsAt != null && !allDay && lunar == null) {
          lines.add(_prop('DTEND', TimeZones.toWall(DateTime.fromMillisecondsSinceEpoch(i.endsAt!, isUtc: true), i.endTz ?? tz), i.endTz ?? tz));
        }
        if (i.notes != null && i.notes!.isNotEmpty) lines.add(_text('DESCRIPTION', i.notes!));
        if (rrule != null) lines.add('RRULE:${rrule.replaceFirst(RegExp('^RRULE:', caseSensitive: false), '')}');
        if (todo && i.status == 'done') lines.add('STATUS:COMPLETED');
        lines.add(todo ? 'END:VTODO' : 'END:VEVENT');
      }
    }
    lines.add('END:VCALENDAR');
    return '${lines.map(_fold).join('\r\n')}\r\n';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _date(CivilDate d) => '${d.year.toString().padLeft(4, '0')}${_two(d.month)}${_two(d.day)}';
  static String _utc(DateTime t) {
    final u = t.toUtc();
    return '${_date(CivilDate(u.year, u.month, u.day))}T${_two(u.hour)}${_two(u.minute)}${_two(u.second)}Z';
  }

  static String _prop(String name, CivilDateTime w, String tz) => w.time == null
      ? '$name;VALUE=DATE:${_date(w.date)}'
      : '$name;TZID=$tz:${_date(w.date)}T${_two(w.time!.hour)}${_two(w.time!.minute)}00';

  static String _text(String name, String v) =>
      '$name:${v.replaceAll(r'\', r'\\').replaceAll(';', r'\;').replaceAll(',', r'\,').replaceAll('\r\n', r'\n').replaceAll('\n', r'\n')}';

  /// Gập dòng dài hơn 75 octet (RFC 5545 §3.1), không cắt giữa ký tự UTF-8.
  static String _fold(String line) {
    final out = StringBuffer();
    var width = 0;
    for (final rune in line.runes) {
      final ch = String.fromCharCode(rune);
      final len = utf8.encode(ch).length;
      if (width + len > 75) {
        out.write('\r\n ');
        width = 1;
      }
      out.write(ch);
      width += len;
    }
    return out.toString();
  }
}
