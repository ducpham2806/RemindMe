/// Kết quả trích xuất chung cho mọi tầng (T0 decoder, T2 luật, T3 LLM): cùng dạng `fixtures/schema/expected.schema.json`
/// để harness eval so trực tiếp (on-device-extraction.md §11). Màn Xem lại (E5) hiển thị từ đây.
library;

/// Giờ địa phương như in trên vé ('YYYY-MM-DD' hoặc 'YYYY-MM-DDTHH:MM') + múi giờ IANA nơi đó nếu biết.
/// [utcOffsetMinutes]: độ lệch UTC nếu nguồn có (ISO 8601 có offset) dù chưa biết tên múi giờ; dùng để suy tz sau (theo sân bay/ga).
class LocalTime {
  const LocalTime(this.local, {this.tz, this.utcOffsetMinutes});
  final String local;
  final String? tz;
  final int? utcOffsetMinutes;

  bool get hasTime => local.contains('T');

  /// '2026-12-05T10:30:00+07:00' → local '2026-12-05T10:30', offset 420. 'Z' → offset 0, tz 'Etc/UTC'.
  static LocalTime? fromIso(String? s) {
    if (s == null) return null;
    final m = RegExp(r'^(\d{4}-\d{2}-\d{2})(?:[T ](\d{2}):(\d{2})(?::\d{2}(?:\.\d+)?)?\s*(Z|[+-]\d{2}:?\d{2})?)?$').firstMatch(s.trim());
    if (m == null) return null;
    if (m[2] == null) return LocalTime(m[1]!);
    final local = '${m[1]}T${m[2]}:${m[3]}';
    final z = m[4];
    if (z == null) return LocalTime(local);
    if (z == 'Z') return LocalTime(local, tz: 'Etc/UTC', utcOffsetMinutes: 0);
    final sign = z.startsWith('-') ? -1 : 1;
    final digits = z.substring(1).replaceAll(':', '');
    return LocalTime(local, utcOffsetMinutes: sign * (int.parse(digits.substring(0, 2)) * 60 + int.parse(digits.substring(2))));
  }

  Map<String, Object?> toJson() => {'local': local, 'tz': tz};

  @override
  String toString() => tz == null ? local : '$local[$tz]';
}

class Place {
  const Place({this.code, this.name, this.terminal, this.gate});
  final String? code;
  final String? name;
  final String? terminal;
  final String? gate;

  Map<String, Object?> toJson() => {'code': ?code, 'name': ?name, 'terminal': ?terminal, 'gate': ?gate};
}

class Price {
  const Price(this.amount, this.currency);
  /// Chuỗi số thập phân chuẩn ('1890000', '12.50'), không định dạng theo locale.
  final String amount;
  final String currency;
}

/// Các trường của 1 candidate (tên theo schema; null = không có).
class CandidateFields {
  const CandidateFields({
    this.title,
    this.provider,
    this.confirmationCode,
    this.carrierCode,
    this.number,
    this.origin,
    this.destination,
    this.startsAt,
    this.endsAt,
    this.checkIn,
    this.checkOut,
    this.seat,
    this.carriage,
    this.travelClass,
    this.passengerCount,
    this.locationText,
    this.price,
    this.due,
  });

  final String? title;
  final String? provider;
  final String? confirmationCode;
  final String? carrierCode;
  final String? number;
  final Place? origin;
  final Place? destination;
  final LocalTime? startsAt;
  final LocalTime? endsAt;
  final LocalTime? checkIn;
  final LocalTime? checkOut;
  final String? seat;
  final String? carriage;
  final String? travelClass;
  final int? passengerCount;
  final String? locationText;
  final Price? price;
  final LocalTime? due;

  Map<String, Object?> toJson() => {
        'title': ?title,
        'provider': ?provider,
        'confirmation_code': ?confirmationCode,
        'carrier_code': ?carrierCode,
        'number': ?number,
        'origin': ?origin?.toJson(),
        'destination': ?destination?.toJson(),
        'starts_at': ?startsAt?.toJson(),
        'ends_at': ?endsAt?.toJson(),
        'check_in': ?checkIn?.toJson(),
        'check_out': ?checkOut?.toJson(),
        'seat': ?seat,
        'carriage': ?carriage,
        'class': ?travelClass,
        'passenger_count': ?passengerCount,
        'location_text': ?locationText,
        if (price != null) 'price': {'amount': price!.amount, 'currency': price!.currency},
        'due': ?due?.toJson(),
      };
}

enum CandidateKind { booking, appointment, event, task }

enum BookingType { flight, train, bus, hotel, carRental, ferry, tour, restaurant, eventTicket, other }

extension BookingTypeWire on BookingType {
  String get wire => switch (this) {
        BookingType.carRental => 'car_rental',
        BookingType.eventTicket => 'event_ticket',
        _ => name,
      };
}

/// Một đề xuất cho màn Xem lại.
class Candidate {
  const Candidate({
    required this.kind,
    required this.fields,
    required this.source,
    this.bookingType,
    this.confidence = 0.95,
    this.rrule,
    this.reminderOffsetsMinutes = const [],
    this.notes,
  });

  final CandidateKind kind;
  final BookingType? bookingType;
  final CandidateFields fields;
  /// Tầng/decoder đã tạo ra: `ics`, `pkpass`, `bcbp`, `jsonld`, `template:<id>`, `generic`, `llm`.
  final String source;
  /// on-device-extraction.md §4.4: decoder định dạng có cấu trúc ≈ 0,95-0,99.
  final double confidence;
  /// Lặp lại (từ .ics), dạng `FREQ=...` như bảng `recurrences.rrule`.
  final String? rrule;
  /// Nhắc có sẵn trong nguồn (VALARM của .ics), phút trước giờ bắt đầu.
  final List<int> reminderOffsetsMinutes;
  final String? notes;

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'booking_type': ?bookingType?.wire,
        'fields': fields.toJson(),
      };
}
