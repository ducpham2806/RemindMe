import '../extract/candidate.dart';

/// Mã vạch thẻ lên máy bay IATA BCBP (Resolution 792), E1.4. Phần bắt buộc có độ dài cố định nên đọc chính xác 100%
/// nếu quét được. Không có giờ bay (chỉ ngày Julian) và không có năm: suy năm gần [reference] nhất.
/// Tên hành khách có trong mã nhưng **không** được trả ra (dữ liệu cá nhân, không cần cho lịch trình).
class BcbpDecoder {
  const BcbpDecoder();

  static bool looksLikeBcbp(String s) => RegExp(r'^M[1-9]').hasMatch(s) && s.length >= 60;

  /// Mỗi chặng 1 candidate; null nếu không phải BCBP hợp lệ.
  List<Candidate>? decode(String data, {required DateTime reference}) {
    if (!looksLikeBcbp(data)) return null;
    final legs = int.parse(data[1]);
    var pos = 23; // M, số chặng, tên (20), chỉ báo vé điện tử
    final out = <Candidate>[];
    for (var i = 0; i < legs; i++) {
      if (data.length < pos + 37) return out.isEmpty ? null : out;
      String f(int start, int len) => data.substring(pos + start, pos + start + len);
      final pnr = f(0, 7).trim();
      final from = f(7, 3).trim();
      final to = f(10, 3).trim();
      final carrier = f(13, 3).trim();
      final flight = f(16, 5).trim();
      final julian = int.tryParse(f(21, 3).trim());
      final seat = f(25, 4).trim();
      final condSize = int.tryParse(f(35, 2), radix: 16);
      if (!RegExp(r'^[A-Z]{3}$').hasMatch(from) || !RegExp(r'^[A-Z]{3}$').hasMatch(to) || condSize == null) {
        return out.isEmpty ? null : out;
      }
      out.add(Candidate(
        kind: CandidateKind.booking,
        bookingType: BookingType.flight,
        source: 'bcbp',
        confidence: 0.99,
        fields: CandidateFields(
          confirmationCode: pnr.isEmpty ? null : pnr,
          carrierCode: carrier.isEmpty ? null : carrier,
          number: _flightNumber(flight),
          origin: Place(code: from),
          destination: Place(code: to),
          startsAt: julian == null || julian < 1 || julian > 366 ? null : LocalTime(_dateFromJulian(julian, reference)),
          seat: _seat(seat),
        ),
      ));
      pos += 37 + condSize;
    }
    return out;
  }

  /// '0245 ' → '245', '0012A' → '12A'.
  static String? _flightNumber(String s) {
    final m = RegExp(r'^0*(\d+)([A-Z]?)$').firstMatch(s);
    return m == null ? (s.isEmpty ? null : s) : '${m[1]}${m[2]}';
  }

  /// '014C' → '14C'; 'INF'/'GATE' (chưa có ghế) → null.
  static String? _seat(String s) {
    final m = RegExp(r'^0*(\d+[A-Z])$').firstMatch(s);
    return m?[1];
  }

  /// Ngày thứ [julian] trong năm, năm nào cho ngày gần [reference] nhất (thẻ thường dùng trong vài ngày quanh lúc quét).
  static String _dateFromJulian(int julian, DateTime reference) {
    DateTime? best;
    for (final y in [reference.year - 1, reference.year, reference.year + 1]) {
      final d = DateTime.utc(y).add(Duration(days: julian - 1));
      if (d.year != y) continue; // ngày 366 của năm không nhuận
      if (best == null || (d.difference(reference).abs() < best.difference(reference).abs())) best = d;
    }
    final d = best!;
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
