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
  return f.provider ?? f.department ?? f.confirmationCode;
}

/// Dòng ghi chú theo ngôn ngữ giao diện (ARB) cho chi tiết của đặt chỗ/lịch khám; mapper không chứa chuỗi hiển thị.
class ImportNoteLabels {
  const ImportNoteLabels({
    required this.bookingCode,
    required this.seat,
    required this.carriage,
    required this.department,
    required this.queueNumber,
  });

  final String Function(String code) bookingCode;
  final String Function(String seat) seat;
  final String Function(String carriage) carriage;
  final String Function(String name) department;
  final String Function(String number) queueNumber;
}

/// Đề xuất (đã chỉnh ở màn Xem lại) → hàng để ghi. [title] là tên người dùng đã sửa (hoặc tên gốc).
/// [labels] định dạng các dòng ghi chú ("Mã đặt chỗ: X", "Toa: 5") theo ngôn ngữ giao diện.
/// [defaults]: nhắc mặc định theo loại đặt chỗ (`defaultReminders`, tính trong isolate giải mã vì cần từ điển sân bay).
/// [tripIndex], [updateItemId]: xem [ImportedItem].
ImportedItem toImportedItem(
  Candidate c, {
  required String title,
  required String deviceTz,
  required ImportNoteLabels labels,
  DefaultReminders? defaults,
  int? tripIndex,
  String? updateItemId,
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
  // Dặn dò của phiếu khám chép nguyên văn lên đầu (không diễn giải, glossary med_fasting).
  final notes = [
    ?f.preparation,
    if (f.confirmationCode != null && !isTask) labels.bookingCode(f.confirmationCode!),
    if (f.carriage != null) labels.carriage(f.carriage!),
    if (f.seat != null) labels.seat(f.seat!),
    if (f.department != null) labels.department(f.department!),
    if (f.queueNumber != null) labels.queueNumber(f.queueNumber!),
    ?c.notes,
  ].join('\n');
  final location = f.locationText ?? (f.origin?.name ?? f.origin?.code);
  // Có ngày/giờ thì nhắc như Quick Add (đúng giờ); .ics có VALARM thì theo VALARM.
  final reminders = start == null
      ? const <int>[]
      : (c.reminderOffsetsMinutes.isNotEmpty ? c.reminderOffsetsMinutes : (defaults?.offsets.isNotEmpty ?? false) ? defaults!.offsets : const [0]);
  final absolute = <DateTime>[
    // Khách sạn: 18:00 hôm trước nhận phòng theo giờ nơi ở; 1 giờ trước trả phòng.
    if (defaults?.dayBeforeAt case final m? when start?.utc != null)
      TimeZones.toUtc(CivilDateTime(start!.wall().date.addDays(-1), CivilTime(m ~/ 60, m % 60)), start.tz!).utc,
    if (end?.utc != null)
      for (final m in defaults?.beforeEndMinutes ?? const <int>[]) end!.utc!.subtract(Duration(minutes: m)),
  ];
  // Có nhắc riêng theo loại (khách sạn chỉ có mốc tuyệt đối) thì không thêm "đúng giờ".
  final offsets = defaults != null && defaults.offsets.isEmpty && absolute.isNotEmpty && c.reminderOffsetsMinutes.isEmpty ? const <int>[] : reminders;
  return ImportedItem(
    title: title,
    kind: switch (c.kind) {
      CandidateKind.task => 'task',
      CandidateKind.appointment => 'appointment',
      CandidateKind.booking => 'booking',
      CandidateKind.event => 'event',
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
    reminderOffsets: offsets,
    absoluteReminders: absolute,
    listName: c.listName,
    booking: c.kind == CandidateKind.booking ? bookingRow(c, start: start, end: end) : null,
    tripIndex: tripIndex,
    updateItemId: updateItemId,
  );
}

/// Hàng `booking_details` từ đề xuất. Không bao giờ có `passengers` (không trích tên hành khách). `extraction_meta` chỉ có
/// nguồn + độ tin cậy theo trường, không có ảnh hay chữ gốc (data-model.md).
Map<String, Object?> bookingRow(Candidate c, {ResolvedTime? start, ResolvedTime? end}) {
  final f = c.fields;
  Map<String, Object?>? place(Place? p, String? tz) => p == null
      ? null
      : {'code': ?p.code, 'name': ?p.name, 'terminal': ?p.terminal, 'gate': ?p.gate, 'tz': ?tz};
  final hotel = c.bookingType == BookingType.hotel;
  return {
    'booking_type': (c.bookingType ?? BookingType.other).wire,
    'provider': ?f.provider,
    'confirmation_code': ?f.confirmationCode,
    'carrier_code': ?f.carrierCode,
    'number': ?f.number,
    'origin': ?place(f.origin, f.startsAt?.tz),
    'destination': ?place(f.destination, f.endsAt?.tz),
    'seat': ?f.seat,
    'class': ?f.travelClass,
    if (hotel && start?.utc != null) 'check_in_at': start!.utc!.toIso8601String(),
    if (hotel && end?.utc != null) 'check_out_at': end!.utc!.toIso8601String(),
    if (f.price != null) 'price': {'amount': f.price!.amount, 'currency': f.price!.currency},
    'extraction_meta': {'source': c.source, if (c.fieldConfidence.isNotEmpty) 'field_confidence': c.fieldConfidence},
  };
}

/// Đặt chỗ trong lần nhập đã có trong máy: [duplicate] = cùng mã, cùng chặng, cùng giờ (bỏ qua);
/// không thì cùng mã + cùng chặng nhưng giờ khác (đổi giờ bay): đề xuất cập nhật [itemId].
class BookingMatch {
  const BookingMatch(this.itemId, {required this.duplicate, this.tripId});
  final String itemId;
  final bool duplicate;
  final String? tripId;
}

List<BookingMatch?> matchExistingBookings(List<Candidate> candidates, List<ExistingBooking> existing, {required String deviceTz}) {
  TimeZones.ensureInitialized();
  return [
    for (final c in candidates) _match(c, existing, deviceTz),
  ];
}

BookingMatch? _match(Candidate c, List<ExistingBooking> existing, String deviceTz) {
  final f = c.fields;
  final code = f.confirmationCode?.toUpperCase();
  if (c.kind != CandidateKind.booking || code == null) return null;
  final type = (c.bookingType ?? BookingType.other).wire;
  bool sameSegment(ExistingBooking e) {
    if (e.confirmationCode.toUpperCase() != code || e.bookingType != type) return false;
    if (f.number != null && e.number != null) return f.number == e.number && (f.carrierCode ?? '') == (e.carrierCode ?? '');
    if (f.origin?.code != null && e.originCode != null) return f.origin!.code == e.originCode && f.destination?.code == e.destinationCode;
    return true;
  }

  final hit = existing.where(sameSegment).firstOrNull;
  if (hit == null) return null;
  final start = resolveLocalTime(f.startsAt ?? f.checkIn, deviceTz);
  final same = start == null || (start.utc != null ? start.utc == hit.startsAt : start.date == hit.startDate);
  return BookingMatch(hit.itemId, duplicate: same, tripId: hit.tripId);
}
