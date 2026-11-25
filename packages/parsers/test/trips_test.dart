import 'dart:io';

import 'package:remindme_parsers/remindme_parsers.dart';
import 'package:test/test.dart';

final airports = AirportIndex.parse(File('data/airports.tsv').readAsStringSync());

Candidate flight(String from, String to, String start, {String? end}) => Candidate(
      kind: CandidateKind.booking,
      bookingType: BookingType.flight,
      source: 'test',
      fields: CandidateFields(origin: Place(code: from), destination: Place(code: to), startsAt: LocalTime(start), endsAt: end == null ? null : LocalTime(end)),
    );

Candidate hotel(String inAt, String outAt) => Candidate(
      kind: CandidateKind.booking,
      bookingType: BookingType.hotel,
      source: 'test',
      fields: CandidateFields(title: 'H', checkIn: LocalTime(inAt), checkOut: LocalTime(outAt)),
    );

void main() {
  test('gom bay đi → khách sạn → bay về; vé sự kiện, việc không gom; chuyến sau cách xa thành chuyến riêng', () {
    final cs = [
      flight('HAN', 'SGN', '2026-12-24T19:00'),
      const Candidate(kind: CandidateKind.task, source: 'x', fields: CandidateFields(title: 'Mua quà', due: LocalTime('2026-12-20'))),
      flight('SGN', 'HAN', '2026-12-20T10:30', end: '2026-12-20T12:40'),
      hotel('2026-12-20T14:00', '2026-12-23T12:00'),
      const Candidate(kind: CandidateKind.event, bookingType: BookingType.eventTicket, source: 'x', fields: CandidateFields(title: 'Show', startsAt: LocalTime('2026-12-21T20:00'))),
      flight('SGN', 'NRT', '2027-02-10T23:00'),
    ];
    final t = suggestTrips(cs, airports: airports);
    expect(t, hasLength(2));
    expect(t[0].indices, [0, 2, 3]);
    expect((t[0].startsOn, t[0].endsOn, t[0].destination, t[0].confident), ('2026-12-20', '2026-12-24', 'Hanoi', true));
    expect(t[1].indices, [5]);
    expect((t[1].destination, t[1].confident), ('Tokyo', false), reason: '1 vé lẻ: gợi ý nhưng mặc định không gộp');
  });

  test('tàu/xe: nơi đến theo tên ga; không có từ điển sân bay thì nơi đến null', () {
    const train = Candidate(
      kind: CandidateKind.booking,
      bookingType: BookingType.train,
      source: 'x',
      fields: CandidateFields(origin: Place(name: 'Sài Gòn'), destination: Place(name: 'Đà Nẵng'), startsAt: LocalTime('2026-12-28T22:00')),
    );
    expect(suggestTrips([train]).single.destination, 'Đà Nẵng');
    expect(suggestTrips([flight('SGN', 'HAN', '2026-12-20T10:30')]).single.destination, isNull);
  });

  test('nhắc mặc định theo loại (reminder-engine §5)', () {
    expect(defaultReminders(flight('SGN', 'HAN', '2026-12-20T10:30'), airports: airports)!.offsets, [-1440, -180, -120]);
    expect(defaultReminders(flight('SGN', 'NRT', '2026-12-20T10:30'), airports: airports)!.offsets, [-1440, -240, -180]);
    expect(defaultReminders(flight('SGN', 'HAN', '2026-12-20T10:30'))!.offsets, [-1440, -240, -180], reason: 'không biết nước: như quốc tế');
    final h = defaultReminders(hotel('2026-12-20T14:00', '2026-12-23T12:00'))!;
    expect(h.offsets, isEmpty);
    expect(h.dayBeforeAt, 1080);
    expect(h.beforeEndMinutes, [60]);
    expect(defaultReminders(flight('SGN', 'HAN', '2026-12-20')), isNull, reason: 'chỉ có ngày');
    const slip = Candidate(kind: CandidateKind.appointment, source: 'x', fields: CandidateFields(startsAt: LocalTime('2027-01-07T08:30')));
    expect(defaultReminders(slip)!.offsets, [-1440, -60]);
    const show = Candidate(kind: CandidateKind.event, source: 'x', fields: CandidateFields(startsAt: LocalTime('2027-01-07T08:30')));
    expect(defaultReminders(show), isNull);
  });

  test('múi giờ theo sân bay cho vé chỉ có offset; offset không khớp thì giữ nguyên', () {
    Candidate f(String start, int off) => Candidate(
          kind: CandidateKind.booking,
          bookingType: BookingType.flight,
          source: 'jsonld',
          fields: CandidateFields(origin: const Place(code: 'JFK'), destination: const Place(code: 'LHR'), startsAt: LocalTime(start, utcOffsetMinutes: off)),
        );
    expect(withAirportTimeZones(f('2026-07-01T18:00', -240), airports).fields.startsAt.toString(), '2026-07-01T18:00[America/New_York]', reason: 'EDT');
    expect(withAirportTimeZones(f('2026-12-01T18:00', -300), airports).fields.startsAt!.tz, 'America/New_York', reason: 'EST');
    expect(withAirportTimeZones(f('2026-12-01T18:00', 420), airports).fields.startsAt!.tz, isNull, reason: '+07:00 không phải New York');
    final noOffset = withAirportTimeZones(flight('SGN', 'LHR', '2026-12-01T10:00', end: '2026-12-01T18:00'), airports).fields;
    expect((noOffset.startsAt!.tz, noOffset.endsAt!.tz), ('Asia/Ho_Chi_Minh', 'Europe/London'));
  });
}
