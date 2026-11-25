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
    this.department,
    this.queueNumber,
    this.preparation,
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
  /// Lịch khám: khoa, số thứ tự, dặn dò in trên phiếu ("Nhịn ăn 8 tiếng"): chỉ chép lại, không diễn giải.
  final String? department;
  final String? queueNumber;
  final String? preparation;

  /// Bản sao đổi vài trường (màn Xem lại sửa tay). Truyền `null` để xóa trường; bỏ qua tham số thì giữ nguyên.
  CandidateFields copyWith({
    Object? title = _keep,
    Object? provider = _keep,
    Object? confirmationCode = _keep,
    Object? carrierCode = _keep,
    Object? number = _keep,
    Object? origin = _keep,
    Object? destination = _keep,
    Object? startsAt = _keep,
    Object? endsAt = _keep,
    Object? checkIn = _keep,
    Object? checkOut = _keep,
    Object? seat = _keep,
    Object? carriage = _keep,
    Object? travelClass = _keep,
    Object? passengerCount = _keep,
    Object? locationText = _keep,
    Object? price = _keep,
    Object? due = _keep,
    Object? department = _keep,
    Object? queueNumber = _keep,
    Object? preparation = _keep,
  }) =>
      CandidateFields(
        title: title == _keep ? this.title : title as String?,
        provider: provider == _keep ? this.provider : provider as String?,
        confirmationCode: confirmationCode == _keep ? this.confirmationCode : confirmationCode as String?,
        carrierCode: carrierCode == _keep ? this.carrierCode : carrierCode as String?,
        number: number == _keep ? this.number : number as String?,
        origin: origin == _keep ? this.origin : origin as Place?,
        destination: destination == _keep ? this.destination : destination as Place?,
        startsAt: startsAt == _keep ? this.startsAt : startsAt as LocalTime?,
        endsAt: endsAt == _keep ? this.endsAt : endsAt as LocalTime?,
        checkIn: checkIn == _keep ? this.checkIn : checkIn as LocalTime?,
        checkOut: checkOut == _keep ? this.checkOut : checkOut as LocalTime?,
        seat: seat == _keep ? this.seat : seat as String?,
        carriage: carriage == _keep ? this.carriage : carriage as String?,
        travelClass: travelClass == _keep ? this.travelClass : travelClass as String?,
        passengerCount: passengerCount == _keep ? this.passengerCount : passengerCount as int?,
        locationText: locationText == _keep ? this.locationText : locationText as String?,
        price: price == _keep ? this.price : price as Price?,
        due: due == _keep ? this.due : due as LocalTime?,
        department: department == _keep ? this.department : department as String?,
        queueNumber: queueNumber == _keep ? this.queueNumber : queueNumber as String?,
        preparation: preparation == _keep ? this.preparation : preparation as String?,
      );

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
        'department': ?department,
        'queue_number': ?queueNumber,
        'preparation': ?preparation,
      };
}

/// Giá trị mặc định của tham số `copyWith`: phân biệt "không đổi" với "xóa" (null).
const Object _keep = Object();

enum CandidateKind { booking, appointment, event, task }

enum BookingType { flight, train, bus, hotel, carRental, ferry, tour, restaurant, eventTicket, other }

extension BookingTypeWire on BookingType {
  String get wire => switch (this) {
        BookingType.carRental => 'car_rental',
        BookingType.eventTicket => 'event_ticket',
        _ => name,
      };
}

/// Việc con (cột `items.checklist`): dòng thụt lề dưới 1 việc trong Markdown.
class ChecklistEntry {
  const ChecklistEntry(this.text, {this.done = false});
  final String text;
  final bool done;

  Map<String, Object?> toJson() => {'text': text, 'done': done};

  @override
  String toString() => '[${done ? 'x' : ' '}] $text';
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
    this.priority,
    this.done = false,
    this.tags = const [],
    this.listName,
    this.checklist = const [],
    this.fieldConfidence = const {},
    this.issues = const [],
  });

  final CandidateKind kind;
  final BookingType? bookingType;
  final CandidateFields fields;
  /// Tầng/decoder đã tạo ra: `ics`, `pkpass`, `bcbp`, `jsonld`, `csv`, `xlsx`, `md`, `template:<id>`, `generic`, `llm`.
  final String source;
  /// on-device-extraction.md §4.4: decoder định dạng có cấu trúc ≈ 0,95-0,99.
  final double confidence;
  /// Lặp lại (từ .ics), dạng `FREQ=...` như bảng `recurrences.rrule`.
  final String? rrule;
  /// Nhắc có sẵn trong nguồn (VALARM của .ics), phút trước giờ bắt đầu.
  /// Theo `offset_minutes`: âm = trước giờ bắt đầu.
  final List<int> reminderOffsetsMinutes;
  final String? notes;
  /// 0-3 như `items.priority` (danh sách việc: cột Ưu tiên, emoji Obsidian).
  final int? priority;
  /// Việc đã xong trong nguồn (`- [x]`, cột Trạng thái).
  final bool done;
  final List<String> tags;
  /// Tên list đề xuất (heading Markdown, tên sheet); màn Xem lại khớp với list có sẵn hoặc tạo mới.
  final String? listName;
  final List<ChecklistEntry> checklist;
  /// Độ tin cậy theo trường (tên theo schema: `starts_at`, `confirmation_code`...) để màn Xem lại tô vàng trường dưới ngưỡng (E5.1).
  /// Rỗng = mọi trường như [confidence] (decoder định dạng có cấu trúc).
  final Map<String, double> fieldConfidence;
  /// Cảnh báo của bước kiểm tra logic (không chặn): `past_date`, `date_order_ambiguous`, `arrival_next_day`, `check_out_before_check_in`.
  final List<String> issues;

  /// Bản sao sau khi người dùng sửa ở màn Xem lại.
  Candidate copyWith({CandidateFields? fields, Map<String, double>? fieldConfidence, List<String>? issues}) => Candidate(
        kind: kind,
        fields: fields ?? this.fields,
        source: source,
        bookingType: bookingType,
        confidence: confidence,
        rrule: rrule,
        reminderOffsetsMinutes: reminderOffsetsMinutes,
        notes: notes,
        priority: priority,
        done: done,
        tags: tags,
        listName: listName,
        checklist: checklist,
        fieldConfidence: fieldConfidence ?? this.fieldConfidence,
        issues: issues ?? this.issues,
      );

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'booking_type': ?bookingType?.wire,
        'fields': fields.toJson(),
      };
}
