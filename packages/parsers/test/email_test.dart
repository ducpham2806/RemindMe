import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:remindme_parsers/remindme_parsers.dart';
import 'package:test/test.dart';

final ref = DateTime.utc(2026, 11, 24);

List<int> bytes(String s) => utf8.encode(s.replaceAll('\n', '\r\n'));

void main() {
  group('MIME', () {
    test('tiêu đề RFC 2047 (B, Q, nhiều từ liền nhau), UTF-8 thô, ngày RFC 5322', () {
      expect(decodeHeaderWords('=?UTF-8?B?WMOhYyBuaOG6rW4=?= =?utf-8?Q?_=C4=91=E1=BA=B7t_ph=C3=B2ng?='), 'Xác nhận đặt phòng');
      expect(decodeHeaderWords('=?iso-8859-1?Q?R=E9servation?= confirmée'), 'Réservation confirmée');
      expect(decodeHeaderWords(String.fromCharCodes(utf8.encode('Đặt chỗ'))), 'Đặt chỗ');
      expect(parseRfc5322Date('Mon, 23 Nov 2026 09:15:00 +0700'), DateTime.utc(2026, 11, 23, 2, 15));
      expect(parseRfc5322Date('23 Nov 26 09:15 GMT'), DateTime.utc(2026, 11, 23, 9, 15));
      expect(parseRfc5322Date('hôm qua'), isNull);
    });

    test('multipart lồng, quoted-printable, base64, charset windows-1252, tên file RFC 2231 nhiều đoạn', () {
      final msg = MimeMessage.parse(bytes('''From: =?utf-8?q?Nh=C3=A0_xe?= <a@example.com>
Subject: Test
Content-Type: multipart/mixed; boundary="AAA"

preamble
--AAA
Content-Type: multipart/alternative; boundary=BBB

--BBB
Content-Type: text/plain; charset=windows-1252
Content-Transfer-Encoding: quoted-printable

Caf=E9 =93ng=E0y=94 =
n=F3i d=E0i
--BBB
Content-Type: text/html; charset=utf-8
Content-Transfer-Encoding: base64

PHA+WGluIGNow6BvPC9wPg==
--BBB--
--AAA
Content-Type: application/octet-stream
Content-Disposition: attachment;
 filename*0*=utf-8''v%C3%A9-;
 filename*1="xe.csv"
Content-Transfer-Encoding: base64

YSxiCjEsMgo=
--AAA--
epilogue
'''));
      expect(msg.from, 'Nhà xe <a@example.com>');
      expect(msg.plainBody, 'Café “ngày” nói dài');
      expect(msg.htmlBodies, ['<p>Xin chào</p>']);
      expect(msg.attachments, hasLength(1));
      expect(msg.attachments.single.filename, 'vé-xe.csv');
      expect(utf8.decode(msg.attachments.single.body), 'a,b\n1,2\n');
    });

    test('htmlToText: bỏ script/style, khối thành dòng, ô bảng thành tab, thực thể', () {
      expect(
        htmlToText('<html><head><style>p{}</style></head><body><p>Mã&nbsp;đặt&#x20;chỗ</p>'
            '<table><tr><td>Giờ</td><td>08:00 &amp; 09:00</td></tr></table><script>x()</script>Hết&hellip;</body></html>'),
        'Mã đặt chỗ\nGiờ\t08:00 & 09:00\nHết…',
      );
    });
  });

  group('EmailDecoder', () {
    test('mẫu khách sạn: JSON-LD trong HTML quoted-printable, .ics đính kèm trùng thì gộp, PDF chờ tầng sau', () {
      final r = const EmailDecoder().decode(File('fixtures/docs/synthetic-email-hotel-0001/input.eml').readAsBytesSync(), reference: ref);
      expect(r.subject, 'Xác nhận đặt phòng HB-48213');
      expect(r.from, 'Biển Xanh Booking <no-reply@example.com>');
      expect(r.sentAt, DateTime.utc(2026, 11, 23, 2, 15));
      expect(r.text, contains('Mã đặt phòng: HB-48213'));
      expect(r.candidates, hasLength(1));
      expect(r.candidates.single.bookingType, BookingType.hotel);
      expect(r.candidates.single.fields.price!.amount, '2450000');
      expect(r.pending.map((p) => (p.filename, p.mediaType)), [('invoice.pdf', 'application/pdf')]);
    });

    test('email chuyển tiếp dạng đính kèm message/rfc822 có .pkpass; lời mời lịch text/calendar trong alternative', () {
      final pass = {
        'formatVersion': 1,
        'organizationName': 'ZZ Air',
        'description': 'Boarding pass',
        'boardingPass': {'transitType': 'PKTransitTypeAir'},
        'barcodes': [
          {'format': 'PKBarcodeFormatPDF417', 'message': 'M1EXAMPLE/TRAVELER    EXQ7K2M SGNHANZZ 0245 355Y014C0001 100', 'messageEncoding': 'iso-8859-1'},
        ],
      };
      final zip = ZipEncoder().encodeBytes(Archive()..add(ArchiveFile.bytes('pass.json', utf8.encode(jsonEncode(pass)))));
      final inner = '''From: ZZ Air <no-reply@example.com>
Subject: Your boarding pass
Date: Sat, 19 Dec 2026 20:00:00 +0700
Content-Type: multipart/mixed; boundary=in

--in
Content-Type: text/plain

See attached.
--in
Content-Type: application/vnd.apple.pkpass
Content-Disposition: attachment; filename=pass.pkpass
Content-Transfer-Encoding: base64

${base64.encode(zip)}
--in--
''';
      final outer = '''From: me@example.org
Subject: Fwd: Your boarding pass
Content-Type: multipart/mixed; boundary=out

--out
Content-Type: multipart/alternative; boundary=alt

--alt
Content-Type: text/plain; charset=utf-8

Chuyển tiếp vé.
--alt
Content-Type: text/calendar; charset=utf-8; method=REQUEST

BEGIN:VCALENDAR
BEGIN:VEVENT
SUMMARY:Họp nhóm
DTSTART;TZID=Asia/Ho_Chi_Minh:20261222T090000
END:VEVENT
END:VCALENDAR
--alt--
--out
Content-Type: message/rfc822

$inner
--out--
''';
      final r = const EmailDecoder().decode(bytes(outer), reference: ref);
      expect(r.candidates.map((c) => c.source), ['ics', 'pkpass+bcbp']);
      expect(r.candidates[0].fields.title, 'Họp nhóm');
      final flight = r.candidates[1].fields;
      expect((flight.carrierCode, flight.number, flight.origin!.code, flight.destination!.code, flight.seat), ('ZZ', '245', 'SGN', 'HAN', '14C'));
      expect(flight.startsAt!.local, '2026-12-21');
      expect(r.text, allOf(contains('Chuyển tiếp vé.'), contains('See attached.')));
      expect(r.pending, isEmpty);
    });

    test('ảnh logo nhúng (Content-ID) không chuyển sang OCR; ảnh đính kèm có tên thì có', () {
      final r = const EmailDecoder().decode(bytes('''Content-Type: multipart/related; boundary=r

--r
Content-Type: text/html

<img src="cid:logo">
--r
Content-Type: image/png
Content-ID: <logo>
Content-Transfer-Encoding: base64

iVBORw0KGgo=
--r
Content-Type: image/jpeg; name="ve-tau.jpg"
Content-Transfer-Encoding: base64

/9j/4AAQ
--r--
'''), reference: ref);
      expect(r.pending.map((p) => p.filename), ['ve-tau.jpg']);
    });
  });
}
