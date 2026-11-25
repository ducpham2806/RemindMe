import 'package:remindme_core/remindme_core.dart';

import '../engine/airports.dart';
import 'candidate.dart';

/// Loại đặt chỗ của 1 chuyến đi (gom vào trip). Vé sự kiện, nhà hàng, lịch khám không gom.
const travelBookingTypes = {BookingType.flight, BookingType.train, BookingType.bus, BookingType.ferry, BookingType.hotel, BookingType.carRental};

/// Gợi ý 1 chuyến đi từ các đề xuất của lần nhập (US-21: máy gợi ý, người dùng xác nhận).
class TripSuggestion {
  const TripSuggestion({required this.indices, required this.startsOn, required this.endsOn, this.destination, required this.confident});
  /// Vị trí trong danh sách đề xuất.
  final List<int> indices;
  /// 'YYYY-MM-DD' theo giờ địa phương in trên vé.
  final String startsOn;
  final String endsOn;
  /// Tên nơi đến (thành phố của sân bay đến chặng đầu, ga/điểm đến) để đặt tên chuyến; null = không biết.
  final String? destination;
  /// ≥ 2 đặt chỗ hoặc có lưu trú: mặc định gộp. 1 vé lẻ: mặc định không gộp (giữ lượt `max_active_trips` của gói Free).
  final bool confident;
}

/// Gom đặt chỗ đi lại theo ngày: sắp theo ngày bắt đầu, đặt chỗ bắt đầu trong vòng [gapDays] ngày sau khi đặt chỗ trước
/// kết thúc thì cùng chuyến (bay đi → khách sạn → bay về).
List<TripSuggestion> suggestTrips(List<Candidate> candidates, {AirportIndex? airports, int gapDays = 2}) {
  final travel = <(int, String, String)>[];
  for (var i = 0; i < candidates.length; i++) {
    final c = candidates[i];
    if (c.kind != CandidateKind.booking || !travelBookingTypes.contains(c.bookingType)) continue;
    final f = c.fields;
    final start = (f.startsAt ?? f.checkIn)?.local;
    if (start == null || start.length < 10) continue;
    final end = (f.endsAt ?? f.checkOut)?.local ?? start;
    travel.add((i, start.substring(0, 10), end.length < 10 ? start.substring(0, 10) : end.substring(0, 10)));
  }
  travel.sort((a, b) => a.$2.compareTo(b.$2));
  final groups = <List<(int, String, String)>>[];
  for (final t in travel) {
    final last = groups.lastOrNull;
    if (last != null && _daysBetween(last.map((x) => x.$3).reduce(_max), t.$2) <= gapDays) {
      last.add(t);
    } else {
      groups.add([t]);
    }
  }
  return [
    for (final g in groups)
      TripSuggestion(
        indices: [for (final t in g) t.$1]..sort(),
        startsOn: g.first.$2,
        endsOn: g.map((x) => x.$3).reduce(_max),
        destination: _destination([for (final t in g) candidates[t.$1]], airports),
        confident: g.length >= 2 || g.any((t) => candidates[t.$1].bookingType == BookingType.hotel),
      ),
  ];
}

String? _destination(List<Candidate> group, AirportIndex? airports) {
  for (final c in group) {
    final d = c.fields.destination;
    if (d == null) continue;
    if (d.code != null) {
      final city = airports?[d.code!]?.city;
      if (city != null && city.isNotEmpty) return city;
    }
    if (d.name != null) return d.name;
  }
  return null;
}

String _max(String a, String b) => a.compareTo(b) >= 0 ? a : b;

int _daysBetween(String a, String b) => DateTime.parse('${b}T00:00:00Z').difference(DateTime.parse('${a}T00:00:00Z')).inDays;

/// Nhắc mặc định khi tạo đặt chỗ/lịch khám (nguồn chuẩn: reminder-engine.md §5, bảng "Nhắc mặc định khi tạo booking").
class DefaultReminders {
  const DefaultReminders({this.offsets = const [], this.dayBeforeAt, this.beforeEndMinutes = const []});
  /// Phút so với giờ bắt đầu (âm = trước).
  final List<int> offsets;
  /// Phút tính từ 0:00 của ngày trước ngày bắt đầu (khách sạn: 18:00 hôm trước = 1080), theo giờ địa phương của đặt chỗ.
  final int? dayBeforeAt;
  /// Phút trước giờ kết thúc (khách sạn: 1 giờ trước trả phòng).
  final List<int> beforeEndMinutes;
}

/// null = không có mặc định riêng (việc, sự kiện: như Quick Add, nhắc đúng giờ hoặc theo VALARM của nguồn).
/// Đặt chỗ chỉ có ngày (không giờ) cũng null: offset theo 0:00 vô nghĩa.
DefaultReminders? defaultReminders(Candidate c, {AirportIndex? airports}) {
  final f = c.fields;
  final start = f.startsAt ?? f.checkIn;
  if (start == null || !start.hasTime) return null;
  if (c.kind == CandidateKind.appointment) return const DefaultReminders(offsets: [-1440, -60]);
  if (c.kind != CandidateKind.booking) return null;
  switch (c.bookingType) {
    case BookingType.flight:
      final o = airports?[f.origin?.code ?? '']?.country, d = airports?[f.destination?.code ?? '']?.country;
      // Không biết nước của 1 đầu: dùng mốc của bay quốc tế (sớm hơn, an toàn hơn).
      final domestic = o != null && o == d;
      return DefaultReminders(offsets: domestic ? const [-1440, -180, -120] : const [-1440, -240, -180]);
    case BookingType.train || BookingType.bus || BookingType.ferry:
      return const DefaultReminders(offsets: [-120, -30]);
    case BookingType.hotel:
      final out = f.checkOut;
      return DefaultReminders(dayBeforeAt: 18 * 60, beforeEndMinutes: out != null && out.hasTime ? const [60] : const []);
    default:
      return null;
  }
}

/// Chuyến bay có giờ mà thiếu tên múi giờ (JSON-LD, `.ics` chỉ có offset): lấy múi giờ của sân bay đi/đến
/// (giờ in trên vé là giờ địa phương sân bay, reminder-engine.md §5). Nguồn có offset thì chỉ nhận khi offset khớp múi giờ
/// sân bay lúc đó, không khớp thì giữ nguyên (mã sân bay hoặc giờ có thể đọc sai).
Candidate withAirportTimeZones(Candidate c, AirportIndex airports) {
  if (c.bookingType != BookingType.flight) return c;
  final f = c.fields;
  LocalTime? fill(LocalTime? t, String? code) {
    if (t == null || t.tz != null || !t.hasTime || code == null) return t;
    final tz = airports[code]?.tz;
    if (tz == null || !TimeZones.isValid(tz)) return t;
    if (t.utcOffsetMinutes != null) {
      final d = CivilDate.parse(t.local.substring(0, 10));
      final wall = CivilDateTime(d, CivilTime.parse(t.local.substring(11, 16)));
      final utc = TimeZones.toUtc(wall, tz).utc;
      final asIfUtc = DateTime.utc(d.year, d.month, d.day, wall.time!.hour, wall.time!.minute);
      if (asIfUtc.difference(utc).inMinutes != t.utcOffsetMinutes) return t;
    }
    return LocalTime(t.local, tz: tz, utcOffsetMinutes: t.utcOffsetMinutes);
  }

  final start = fill(f.startsAt, f.origin?.code), end = fill(f.endsAt, f.destination?.code);
  if (identical(start, f.startsAt) && identical(end, f.endsAt)) return c;
  return c.copyWith(fields: f.copyWith(startsAt: start, endsAt: end));
}
