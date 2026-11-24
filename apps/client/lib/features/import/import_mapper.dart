import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:remindme_parsers/remindme_parsers.dart';

/// Thời điểm đã quy về cách lưu của `items`: UTC + tz IANA, hoặc ngày (cả ngày).
class ResolvedTime {
  const ResolvedTime.instant(DateTime this.utc, String this.tz) : date = null;
  const ResolvedTime.date(String this.date)
      : utc = null,
        tz = null;
  final DateTime? utc;
  final String? tz;
  final String? date;

  /// Giờ tường để hiển thị ở màn Xem lại (theo [tz] của chính nó).
  CivilDateTime wall() => utc != null ? TimeZones.toWall(utc!, tz!) : CivilDateTime(CivilDate.parse(date!));
}

/// Giờ in trên vé → UTC + tz. Thứ tự: tz IANA của nguồn; `Etc/UTC` (giờ Z của .ics) đổi sang giờ máy cho dễ đọc;
/// chỉ có offset thì dùng múi giờ máy nếu trùng offset lúc đó, không thì `Etc/GMT∓h` (offset lẻ phút: giờ máy, giữ đúng thời điểm);
/// không có gì thì giờ máy (danh sách việc, Markdown).
ResolvedTime? resolveLocalTime(LocalTime? t, String deviceTz) {
  if (t == null) return null;
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(t.local);
  if (m == null || !CivilDate.isValid(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!))) return null;
  if (!t.hasTime) return ResolvedTime.date(t.local.substring(0, 10));
  final date = CivilDate.parse(t.local.substring(0, 10));
  final wall = CivilDateTime(date, CivilTime.parse(t.local.substring(11, 16)));
  final asUtc = DateTime.utc(date.year, date.month, date.day, wall.time!.hour, wall.time!.minute);
  final tz = t.tz;
  if (tz == 'Etc/UTC' || tz == 'UTC') return ResolvedTime.instant(asUtc, deviceTz);
  if (tz != null && TimeZones.isValid(tz)) return ResolvedTime.instant(TimeZones.toUtc(wall, tz).utc, tz);
  final off = t.utcOffsetMinutes;
  if (off != null) {
    final utc = asUtc.subtract(Duration(minutes: off));
    final deviceOff = TimeZones.toWall(utc, deviceTz);
    final deviceMinutes = DateTime.utc(deviceOff.date.year, deviceOff.date.month, deviceOff.date.day, deviceOff.time!.hour, deviceOff.time!.minute)
        .difference(utc)
        .inMinutes;
    if (deviceMinutes == off || off % 60 != 0) return ResolvedTime.instant(utc, deviceTz);
    final h = off ~/ 60;
    // Etc/GMT đảo dấu: UTC+7 là 'Etc/GMT-7'.
    return ResolvedTime.instant(utc, h == 0 ? 'Etc/UTC' : 'Etc/GMT${h > 0 ? '-' : '+'}${h.abs()}');
  }
  return ResolvedTime.instant(TimeZones.toUtc(wall, deviceTz).utc, deviceTz);
}

/// Tên mặc định khi nguồn không có tiêu đề (vé máy bay/tàu): mã + tuyến, không có chữ của ngôn ngữ nào.
String? fallbackTitle(Candidate c) {
  final f = c.fields;
  final number = [?f.carrierCode, ?f.number].join(' ').trim();
  String? place(Place? p) => p?.code ?? p?.name;
  final from = place(f.origin), to = place(f.destination);
  final route = from != null && to != null ? '$from → $to' : null;
  final parts = [if (number.isNotEmpty) number, ?route];
  if (parts.isNotEmpty) return parts.join(' · ');
  return f.provider ?? f.confirmationCode;
}

/// Đề xuất (đã chỉnh ở màn Xem lại) → hàng để ghi. [title] là tên người dùng đã sửa (hoặc tên gốc).
/// [confirmationLine] định dạng dòng "Mã đặt chỗ: X" theo ngôn ngữ giao diện cho ghi chú.
ImportedItem toImportedItem(
  Candidate c, {
  required String title,
  required String deviceTz,
  required String Function(String code) confirmationLine,
}) {
  TimeZones.ensureInitialized();
  final f = c.fields;
  final isTask = c.kind == CandidateKind.task;
  final start = resolveLocalTime(isTask ? (f.due ?? f.startsAt) : (f.startsAt ?? f.checkIn ?? f.due), deviceTz);
  final end = isTask ? null : resolveLocalTime(f.endsAt ?? f.checkOut, deviceTz);
  final rrule = c.rrule;
  DateTime? recurrenceStart;
  if (rrule != null && start != null) {
    recurrenceStart = start.utc ?? TimeZones.toUtc(CivilDateTime(CivilDate.parse(start.date!)), deviceTz).utc;
  }
  final notes = [
    if (f.confirmationCode != null && !isTask) confirmationLine(f.confirmationCode!),
    ?c.notes,
  ].join('\n');
  final location = f.locationText ?? (f.origin?.name ?? f.origin?.code);
  // Có ngày/giờ thì nhắc như Quick Add (đúng giờ); .ics có VALARM thì theo VALARM.
  final reminders = start == null ? const <int>[] : (c.reminderOffsetsMinutes.isNotEmpty ? c.reminderOffsetsMinutes : const [0]);
  return ImportedItem(
    title: title,
    kind: switch (c.kind) {
      CandidateKind.task => 'task',
      CandidateKind.appointment => 'appointment',
      // Đặt chỗ lưu thành sự kiện có giờ tới khi có chuyến đi (trips + booking_details, S6).
      CandidateKind.booking || CandidateKind.event => 'event',
    },
    startsAt: start?.utc,
    tz: start?.tz ?? (start?.date != null ? deviceTz : null),
    startDate: start?.date,
    endsAt: start?.utc != null ? end?.utc : null,
    endTz: start?.utc != null ? end?.tz : null,
    endDate: start?.date != null ? end?.date : null,
    priority: c.priority ?? 0,
    tags: c.tags,
    notes: notes.isEmpty ? null : notes,
    locationText: location,
    checklist: [for (final e in c.checklist) (text: e.text, done: e.done)],
    done: c.done,
    recurrence: rrule == null || recurrenceStart == null ? null : {'kind': 'rrule', 'rrule': rrule},
    recurrenceStart: rrule == null ? null : recurrenceStart,
    reminderOffsets: reminders,
    listName: c.listName,
  );
}
