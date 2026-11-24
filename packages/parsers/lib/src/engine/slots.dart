import 'package:remindme_core/remindme_core.dart';

import '../extract/candidate.dart';
import 'airports.dart';
import 'values.dart';
import 'vocabulary.dart';

/// Giá trị 1 trường + độ tin cậy theo nguồn (on-device-extraction.md §4.4):
/// khớp mẫu nhà cung cấp 0,95 · anchor + pattern 0,8 · chỉ pattern 0,6 · suy luận mặc định 0,4.
class Slot<T> {
  const Slot(this.value, this.confidence);
  final T value;
  final double confidence;

  static const template = 0.95;
  static const anchored = 0.8;
  static const pattern = 0.6;
  static const inferred = 0.4;
}

/// Trường thô của 1 đặt chỗ (1 chặng bay, 1 lần lưu trú) trước khi kiểm tra logic và ghép thành [Candidate].
/// Mẫu nhà cung cấp và extractor chung cùng điền vào đây để dùng chung validator.
class Slots {
  Slot<String>? confirmationCode;
  Slot<String>? carrierCode;
  Slot<String>? number;
  Slot<String>? origin;
  Slot<String>? destination;
  Slot<String>? originTerminal;
  Slot<String>? gate;
  Slot<String>? seat;
  Slot<String>? carriage;
  Slot<String>? travelClass;
  Slot<String>? property;
  Slot<String>? address;
  Slot<DocDate>? departureDate;
  Slot<DocTime>? departureTime;
  Slot<DocDate>? arrivalDate;
  Slot<DocTime>? arrivalTime;
  /// "+1" in cạnh giờ đến.
  bool arrivalNextDay = false;
  Slot<DocDate>? checkInDate;
  Slot<DocTime>? checkInTime;
  Slot<DocDate>? checkOutDate;
  Slot<DocTime>? checkOutTime;
  Slot<int>? passengerCount;
  Slot<Price>? price;

  /// Điền trường còn trống từ [header] (phần đầu tài liệu dùng chung cho mọi chặng: mã đặt chỗ, số khách).
  void fillFrom(Slots header) {
    confirmationCode ??= header.confirmationCode;
    passengerCount ??= header.passengerCount;
    property ??= header.property;
    address ??= header.address;
    travelClass ??= header.travelClass;
    departureDate ??= header.departureDate;
  }
}

/// Kiểm tra logic + ghép [Slots] thành [Candidate] (E3.4). Thiếu trường bắt buộc thì bỏ (không đoán).
class CandidateAssembler {
  const CandidateAssembler({this.airports, required this.reference});
  final AirportIndex? airports;
  /// Ngày nhận tài liệu (ngày gửi email, ngày quét): suy năm thiếu, cảnh báo ngày đã qua.
  final DateTime reference;

  Candidate? assemble(DocType type, Slots s, {required String source}) => switch (type) {
        DocType.flight => _flight(s, source),
        DocType.hotel => _hotel(s, source),
        _ => null,
      };

  Candidate? _flight(Slots s, String source) {
    final o = s.origin?.value, d = s.destination?.value, date = s.departureDate;
    if (o == null || d == null || date == null || o == d) return null;
    final conf = <String, double>{};
    final issues = <String>[];
    final depDate = date.value.iso(reference);
    final oTz = airports?[o]?.tz, dTz = airports?[d]?.tz;
    final dep = s.departureTime;
    final startsAt = LocalTime(dep == null ? depDate : '${depDate}T${dep.value.hm}', tz: oTz);
    conf['starts_at'] = _min([date.confidence, if (dep != null) dep.confidence]);
    if (date.value.orderAmbiguous) issues.add('date_order_ambiguous');
    if (depDate.compareTo(_iso(reference)) < 0) issues.add('past_date');

    LocalTime? endsAt;
    final arr = s.arrivalTime;
    if (arr != null && dep != null) {
      var arrDate = s.arrivalDate?.value.iso(reference) ?? depDate;
      var c = _min([arr.confidence, s.arrivalDate?.confidence ?? date.confidence]);
      if (s.arrivalDate == null && (s.arrivalNextDay || _arrivesNextDay(depDate, dep.value, oTz, arr.value, dTz))) {
        arrDate = _addDay(depDate);
        if (!s.arrivalNextDay) {
          issues.add('arrival_next_day');
          c = _min([c, Slot.inferred]);
        }
      }
      endsAt = LocalTime('${arrDate}T${arr.value.hm}', tz: dTz);
      conf['ends_at'] = c;
    }
    void put(String k, Slot<Object?>? v) {
      if (v != null) conf[k] = v.confidence;
    }

    put('confirmation_code', s.confirmationCode);
    put('carrier_code', s.carrierCode);
    put('number', s.number);
    put('origin', s.origin);
    put('destination', s.destination);
    put('seat', s.seat);
    put('class', s.travelClass);
    put('passenger_count', s.passengerCount);
    put('price', s.price);
    return Candidate(
      kind: CandidateKind.booking,
      bookingType: BookingType.flight,
      source: source,
      confidence: _min([conf['starts_at']!, s.origin!.confidence, s.destination!.confidence]),
      fieldConfidence: conf,
      issues: issues,
      fields: CandidateFields(
        confirmationCode: s.confirmationCode?.value,
        carrierCode: s.carrierCode?.value,
        number: s.number?.value,
        origin: Place(code: o, terminal: s.originTerminal?.value, gate: s.gate?.value),
        destination: Place(code: d),
        startsAt: startsAt,
        endsAt: endsAt,
        seat: s.seat?.value,
        travelClass: s.travelClass?.value,
        passengerCount: s.passengerCount?.value,
        price: s.price?.value,
      ),
    );
  }

  Candidate? _hotel(Slots s, String source) {
    final inDate = s.checkInDate;
    if (inDate == null || (s.property == null && s.confirmationCode == null)) return null;
    final conf = <String, double>{};
    final issues = <String>[];
    LocalTime at(Slot<DocDate> d, Slot<DocTime> t) => LocalTime('${d.value.iso(reference)}T${t.value.hm}');

    // Thiếu giờ thì nhận phòng 14:00, trả phòng 12:00 (§4.4), độ tin cậy "suy luận" để màn Xem lại tô vàng.
    final inTime = s.checkInTime ?? const Slot(DocTime(14, 0, start: 0, end: 0), Slot.inferred);
    final checkIn = at(inDate, inTime);
    conf['check_in'] = _min([inDate.confidence, inTime.confidence]);
    if (inDate.value.orderAmbiguous) issues.add('date_order_ambiguous');
    if (checkIn.local.compareTo(_iso(reference)) < 0) issues.add('past_date');
    LocalTime? checkOut;
    final outDate = s.checkOutDate;
    if (outDate != null) {
      final outTime = s.checkOutTime ?? const Slot(DocTime(12, 0, start: 0, end: 0), Slot.inferred);
      checkOut = at(outDate, outTime);
      // Trả phòng trước nhận phòng: thứ tự ngày đọc sai hoặc thiếu năm qua giao thừa → bỏ, để người dùng nhập.
      if (checkOut.local.substring(0, 10).compareTo(checkIn.local.substring(0, 10)) <= 0) {
        checkOut = null;
        issues.add('check_out_before_check_in');
      } else {
        conf['check_out'] = _min([outDate.confidence, outTime.confidence]);
      }
    }
    if (s.property != null) conf['title'] = s.property!.confidence;
    if (s.confirmationCode != null) conf['confirmation_code'] = s.confirmationCode!.confidence;
    if (s.address != null) conf['location_text'] = s.address!.confidence;
    if (s.price != null) conf['price'] = s.price!.confidence;
    return Candidate(
      kind: CandidateKind.booking,
      bookingType: BookingType.hotel,
      source: source,
      confidence: conf['check_in']!,
      fieldConfidence: conf,
      issues: issues,
      fields: CandidateFields(
        title: s.property?.value,
        confirmationCode: s.confirmationCode?.value,
        checkIn: checkIn,
        checkOut: checkOut,
        locationText: s.address?.value,
        price: s.price?.value,
      ),
    );
  }

  /// Vé không in ngày đến và không có "+1": đến cùng ngày mà sớm hơn giờ đi (so theo UTC khi biết múi giờ 2 đầu) thì là hôm sau.
  /// Theo UTC nên đúng cả chuyến bay về phía tây qua đường đổi ngày (NRT 17:00 → HNL 06:00 cùng ngày).
  static bool _arrivesNextDay(String depDate, DocTime dep, String? oTz, DocTime arr, String? dTz) {
    if (oTz == null || dTz == null || !TimeZones.isValid(oTz) || !TimeZones.isValid(dTz)) return arr.minutes < dep.minutes;
    final day = CivilDate.parse(depDate);
    final d = TimeZones.toUtc(CivilDateTime(day, CivilTime(dep.hour, dep.minute)), oTz).utc;
    final a = TimeZones.toUtc(CivilDateTime(day, CivilTime(arr.hour, arr.minute)), dTz).utc;
    return a.isBefore(d);
  }

  static double _min(List<double> v) => v.reduce((a, b) => a < b ? a : b);

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _addDay(String iso) {
    final d = DateTime.parse('${iso}T00:00:00Z').add(const Duration(days: 1));
    return _iso(d);
  }
}
