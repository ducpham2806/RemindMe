import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:remindme_parsers/remindme_parsers.dart';
import 'package:test/test.dart';

final ref = DateTime.utc(2026, 11, 24);

// Ví dụ chuẩn trong IATA BCBP Implementation Guide (dữ liệu giả).
const bcbp1 = 'M1DESMARAIS/LUC       EABC123 YULFRAAC 0834 326J001A0025 100';

void main() {
  group('ics', () {
    const ics = 'BEGIN:VCALENDAR\r\nVERSION:2.0\r\n'
        'BEGIN:VEVENT\r\nUID:1\r\nSUMMARY:Họp khách\\, quý 4\r\n'
        'DTSTART;TZID=Asia/Ho_Chi_Minh:20261205T103000\r\nDTEND;TZID=Asia/Ho_Chi_Minh:20261205T113000\r\n'
        'LOCATION:Tầng 3\\nPhòng A\r\nDESCRIPTION:Mang hợp đồng và báo cáo d\r\n oanh thu\r\n'
        'RRULE:FREQ=WEEKLY;BYDAY=SA\r\n'
        'BEGIN:VALARM\r\nACTION:DISPLAY\r\nTRIGGER:-PT15M\r\nEND:VALARM\r\n'
        'BEGIN:VALARM\r\nACTION:DISPLAY\r\nTRIGGER;RELATED=START:-P1D\r\nEND:VALARM\r\n'
        'END:VEVENT\r\n'
        'BEGIN:VEVENT\r\nSUMMARY:Sinh nhật\r\nDTSTART;VALUE=DATE:20261208\r\nEND:VEVENT\r\n'
        'BEGIN:VEVENT\r\nSUMMARY:Call\r\nDTSTART:20261205T033000Z\r\nDURATION:PT1H30M\r\nEND:VEVENT\r\n'
        'BEGIN:VEVENT\r\nSUMMARY:Đã hủy\r\nSTATUS:CANCELLED\r\nDTSTART:20261205T033000Z\r\nEND:VEVENT\r\n'
        'BEGIN:VTODO\r\nSUMMARY:Nộp thuế\r\nDUE;VALUE=DATE:20261231\r\nEND:VTODO\r\n'
        'END:VCALENDAR\r\n';

    test('VEVENT có TZID, escape, dòng gấp, RRULE, VALARM; cả ngày; UTC + DURATION; bỏ sự kiện đã hủy; VTODO', () {
      final c = const IcsDecoder().decode(ics);
      expect(c, hasLength(4));
      final meeting = c[0];
      expect(meeting.kind, CandidateKind.event);
      expect(meeting.fields.title, 'Họp khách, quý 4');
      expect(meeting.fields.locationText, 'Tầng 3\nPhòng A');
      expect(meeting.notes, 'Mang hợp đồng và báo cáo doanh thu');
      expect(meeting.fields.startsAt!.toJson(), {'local': '2026-12-05T10:30', 'tz': 'Asia/Ho_Chi_Minh'});
      expect(meeting.fields.endsAt!.local, '2026-12-05T11:30');
      expect(meeting.rrule, 'FREQ=WEEKLY;BYDAY=SA');
      expect(meeting.reminderOffsetsMinutes, [-1440, -15]);
      expect(c[1].fields.startsAt!.toJson(), {'local': '2026-12-08', 'tz': null});
      expect(c[2].fields.startsAt!.toJson(), {'local': '2026-12-05T03:30', 'tz': 'Etc/UTC'});
      expect(c[2].fields.endsAt!.local, '2026-12-05T05:00');
      expect(c[3].kind, CandidateKind.task);
      expect(c[3].fields.due!.local, '2026-12-31');
    });

    test('rác không làm hỏng', () {
      expect(const IcsDecoder().decode('hello\nworld'), isEmpty);
    });
  });

  group('BCBP', () {
    test('1 chặng: PNR, sân bay, hãng, số hiệu, ngày Julian, ghế; không trả tên hành khách', () {
      final c = const BcbpDecoder().decode(bcbp1, reference: ref)!.single;
      expect(c.fields.toJson(), {
        'confirmation_code': 'ABC123',
        'carrier_code': 'AC',
        'number': '834',
        'origin': {'code': 'YUL'},
        'destination': {'code': 'FRA'},
        'starts_at': {'local': '2026-11-22', 'tz': null},
        'seat': '1A',
      });
      expect(jsonEncode(c.toJson()), isNot(contains('DESMARAIS')));
    });

    test('2 chặng (phần điều kiện của chặng 1 có độ dài khác 0)', () {
      // Chặng 1: điều kiện dài 0x18 = 24 ký tự; chặng 2 nối sau.
      final cond1 = '>5180  ${' ' * 17}';
      final data = 'M2DOE/JANE            EXQ7K2M SGNHANVN 0245 355Y014C0012 1${24.toRadixString(16).padLeft(2, '0').toUpperCase()}$cond1'
          'XQ7K2M HANNRTVN 0310 356Y022K0005 100';
      final legs = const BcbpDecoder().decode(data, reference: ref)!;
      expect(legs.map((l) => '${l.fields.origin!.code}-${l.fields.destination!.code} ${l.fields.number} ${l.fields.startsAt!.local} ${l.fields.seat}'),
          ['SGN-HAN 245 2026-12-21 14C', 'HAN-NRT 310 2026-12-22 22K']);
    });

    test('năm suy theo ngày gần nhất: Julian 005 quét cuối tháng 12 → tháng 1 năm sau', () {
      final c = const BcbpDecoder().decode(bcbp1.replaceFirst('326', '005'), reference: DateTime.utc(2026, 12, 30))!.single;
      expect(c.fields.startsAt!.local, '2027-01-05');
    });

    test('không phải BCBP', () {
      expect(const BcbpDecoder().decode('https://example.com/x', reference: ref), isNull);
      expect(const BcbpDecoder().decode('M1${'x' * 70}', reference: ref), isNull);
    });
  });

  group('JSON-LD trong email', () {
    test('FlightReservation trong @graph, giữ giờ địa phương + offset; email entity HTML', () {
      final html = '''<html><body><p>Cảm ơn quý khách</p>
<script type="application/ld+json">{"@context":"https://schema.org","@graph":[{"@type":"FlightReservation","reservationNumber":"XQ7K2M",
"reservationStatus":"https://schema.org/ReservationConfirmed","underName":{"@type":"Person","name":"Nguyen Van A"},
"reservationFor":{"@type":"Flight","flightNumber":"245","airline":{"@type":"Airline","name":"ZZ Air","iataCode":"ZZ"},
"departureAirport":{"@type":"Airport","name":"Tan Son Nhat","iataCode":"SGN"},"departureTerminal":"1",
"arrivalAirport":{"@type":"Airport","name":"Noi Bai","iataCode":"HAN"},
"departureTime":"2026-12-21T10:30:00+07:00","arrivalTime":"2026-12-21T12:40:00+07:00"},
"airplaneSeat":"14C","airplaneSeatClass":"Economy","totalPrice":"1890000","priceCurrency":"VND"}]}</script></body></html>''';
      final c = const JsonLdDecoder().decodeHtml(html).single;
      expect(c.bookingType, BookingType.flight);
      final f = c.fields.toJson();
      expect(f['confirmation_code'], 'XQ7K2M');
      expect((f['carrier_code'], f['number'], f['seat'], f['class']), ('ZZ', '245', '14C', 'Economy'));
      expect(f['origin'], {'code': 'SGN', 'name': 'Tan Son Nhat', 'terminal': '1'});
      expect(c.fields.startsAt!.local, '2026-12-21T10:30');
      expect(c.fields.startsAt!.utcOffsetMinutes, 420);
      expect(f['price'], {'amount': '1890000', 'currency': 'VND'});
      expect(jsonEncode(f), isNot(contains('Nguyen')), reason: 'không lấy tên hành khách');
    });

    test('Lodging, Train, Event, Restaurant; bỏ đặt chỗ đã hủy; JSON hỏng không lỗi', () {
      final json = jsonEncode([
        {
          '@type': 'LodgingReservation', 'reservationNumber': 'H1',
          'reservationFor': {'@type': 'LodgingBusiness', 'name': 'Hotel Sample', 'address': {'streetAddress': '1 Main St', 'addressLocality': 'Da Lat'}},
          'checkinTime': '2026-12-21T14:00:00+07:00', 'checkoutTime': '2026-12-23T12:00:00+07:00',
        },
        {
          '@type': 'TrainReservation', 'reservationNumber': 'T9',
          'reservationFor': {'@type': 'TrainTrip', 'trainNumber': 'SE1', 'departureStation': {'name': 'Ga Sài Gòn'}, 'arrivalStation': {'name': 'Ga Nha Trang'},
            'departureTime': '2026-12-24T19:00:00+07:00'},
          'reservedTicket': {'ticketedSeat': {'seatNumber': '12', 'seatSection': '5'}},
        },
        {'@type': 'EventReservation', 'reservationFor': {'@type': 'Event', 'name': 'Concert', 'startDate': '2026-12-31T20:00:00Z', 'location': {'name': 'Opera House'}}},
        {'@type': 'FoodEstablishmentReservation', 'startTime': '2026-12-25T19:30:00+07:00', 'partySize': 4, 'reservationFor': {'name': 'Quán Ngon'}},
        {'@type': 'FlightReservation', 'reservationStatus': 'http://schema.org/ReservationCancelled', 'reservationNumber': 'X'},
      ]);
      final c = const JsonLdDecoder().decodeJson(json);
      expect(c.map((x) => x.bookingType), [BookingType.hotel, BookingType.train, BookingType.eventTicket, BookingType.restaurant]);
      expect(c[0].fields.checkIn!.local, '2026-12-21T14:00');
      expect(c[0].fields.locationText, '1 Main St, Da Lat');
      expect((c[1].fields.number, c[1].fields.seat, c[1].fields.carriage, c[1].fields.origin!.name), ('SE1', '12', '5', 'Ga Sài Gòn'));
      expect(c[2].fields.startsAt!.toJson(), {'local': '2026-12-31T20:00', 'tz': 'Etc/UTC'});
      expect(c[3].fields.passengerCount, 4);
      expect(const JsonLdDecoder().decodeJson('{oops'), isEmpty);
    });
  });

  group('pkpass', () {
    List<int> zip(Map<String, Object?> pass) {
      final a = Archive()..addFile(ArchiveFile.bytes('pass.json', utf8.encode(jsonEncode(pass))));
      return ZipEncoder().encodeBytes(a);
    }

    test('thẻ lên máy bay có BCBP: lấy BCBP, bổ sung giờ cùng ngày, cổng, nhà ga', () {
      final bytes = zip({
        'formatVersion': 1,
        'organizationName': 'Sample Air',
        'relevantDate': '2026-11-22T08:15:00-05:00',
        'barcodes': [{'format': 'PKBarcodeFormatPDF417', 'message': bcbp1}],
        'boardingPass': {
          'transitType': 'PKTransitTypeAir',
          'primaryFields': [{'key': 'origin', 'label': 'Montreal', 'value': 'YUL'}, {'key': 'destination', 'label': 'Frankfurt', 'value': 'FRA'}],
          'auxiliaryFields': [{'key': 'gate', 'label': 'GATE', 'value': 'B12'}, {'key': 'terminal', 'label': 'TERMINAL', 'value': '3'}],
        },
      });
      final c = const PkpassDecoder().decodeZip(bytes, reference: ref).single;
      expect(c.source, 'pkpass+bcbp');
      expect(c.fields.startsAt!.local, '2026-11-22T08:15');
      expect(c.fields.startsAt!.utcOffsetMinutes, -300);
      expect(c.fields.origin!.toJson(), {'code': 'YUL', 'terminal': '3', 'gate': 'B12'});
      expect((c.fields.confirmationCode, c.fields.seat, c.fields.provider), ('ABC123', '1A', 'Sample Air'));
    });

    test('vé tàu không có BCBP; vé sự kiện; zip hỏng', () {
      final train = const PkpassDecoder().decodePassJson(
          jsonEncode({
            'organizationName': 'Rail Co',
            'relevantDate': '2026-12-24T19:00:00+07:00',
            'boardingPass': {
              'transitType': 'PKTransitTypeTrain',
              'primaryFields': [{'key': 'from', 'label': 'Sài Gòn', 'value': 'SGN'}, {'key': 'to', 'label': 'Nha Trang', 'value': 'NTR'}],
              'secondaryFields': [{'key': 'coach', 'label': 'Coach', 'value': '5'}, {'key': 'seat', 'label': 'Seat', 'value': '12'}],
              'backFields': [{'key': 'pnr', 'label': 'Booking reference', 'value': 'T9'}],
            },
          }),
          reference: ref);
      expect(train.single.bookingType, BookingType.train);
      expect((train.single.fields.carriage, train.single.fields.seat, train.single.fields.confirmationCode), ('5', '12', 'T9'));
      final event = const PkpassDecoder().decodePassJson(
          jsonEncode({
            'description': 'Year-end concert',
            'relevantDate': '2026-12-31T20:00:00Z',
            'eventTicket': {'secondaryFields': [{'key': 'venue', 'label': 'Venue', 'value': 'Opera House'}]},
          }),
          reference: ref);
      expect((event.single.bookingType, event.single.fields.title, event.single.fields.locationText),
          (BookingType.eventTicket, 'Year-end concert', 'Opera House'));
      expect(const PkpassDecoder().decodeZip([1, 2, 3], reference: ref), isEmpty);
    });
  });
}
