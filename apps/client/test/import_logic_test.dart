import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:remindme_client/features/import/candidate_editor.dart';
import 'package:remindme_client/features/import/import_decode.dart';
import 'package:remindme_client/features/import/import_mapper.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:remindme_parsers/remindme_parsers.dart';

const docs = '../../packages/parsers/fixtures/docs';
final packs = {for (final l in ['vi', 'en']) l: File('../../packages/parsers/nlu/packs/$l.yaml').readAsStringSync()};
final airportsTsv = File('../../packages/parsers/data/airports.tsv').readAsStringSync();

ImportRequest req(String path, {String? name, String? region = 'VN', String? dateOrder}) => ImportRequest(
      name: name ?? path.split('/').last,
      bytes: File(path).readAsBytesSync(),
      packSources: packs,
      airportsTsv: airportsTsv,
      now: DateTime(2026, 11, 24, 9),
      region: region,
      dateOrder: dateOrder,
    );

String code(String c) => 'code $c';
final labels = ImportNoteLabels(bookingCode: code, seat: (s) => 'seat $s', carriage: (c) => 'car $c', department: (d) => 'dept $d', queueNumber: (n) => 'no $n');

void main() {
  setUpAll(TimeZones.ensureInitialized);

  group('resolveLocalTime', () {
    test('ngày; giờ Z của .ics đổi sang múi giờ máy; tz IANA của nguồn giữ nguyên', () {
      expect(resolveLocalTime(const LocalTime('2026-12-08'), 'Asia/Ho_Chi_Minh')!.date, '2026-12-08');
      final z = resolveLocalTime(const LocalTime('2026-12-05T03:30', tz: 'Etc/UTC', utcOffsetMinutes: 0), 'Asia/Ho_Chi_Minh')!;
      expect((z.utc, z.tz), (DateTime.utc(2026, 12, 5, 3, 30), 'Asia/Ho_Chi_Minh'));
      final ny = resolveLocalTime(const LocalTime('2026-12-05T10:30', tz: 'America/New_York'), 'Asia/Ho_Chi_Minh')!;
      expect((ny.utc, ny.tz), (DateTime.utc(2026, 12, 5, 15, 30), 'America/New_York'));
      expect(ny.wall(), CivilDateTime(CivilDate(2026, 12, 5), CivilTime(10, 30)));
    });

    test('chỉ có offset: trùng giờ máy thì dùng giờ máy, khác thì Etc/GMT (đảo dấu), offset lẻ phút thì giờ máy', () {
      const t = LocalTime('2026-12-21T10:30', utcOffsetMinutes: 420);
      final same = resolveLocalTime(t, 'Asia/Ho_Chi_Minh')!;
      expect((same.utc, same.tz), (DateTime.utc(2026, 12, 21, 3, 30), 'Asia/Ho_Chi_Minh'));
      final other = resolveLocalTime(t, 'America/New_York')!;
      expect((other.utc, other.tz), (DateTime.utc(2026, 12, 21, 3, 30), 'Etc/GMT-7'));
      expect(other.wall().time, CivilTime(10, 30));
      final india = resolveLocalTime(const LocalTime('2026-12-21T10:30', utcOffsetMinutes: 330), 'Europe/London')!;
      expect((india.utc, india.tz), (DateTime.utc(2026, 12, 21, 5), 'Europe/London'));
    });

    test('không có tz/offset: giờ tường theo máy; ngày sai trả null', () {
      final r = resolveLocalTime(const LocalTime('2026-12-15T09:00'), 'Asia/Ho_Chi_Minh')!;
      expect((r.utc, r.tz), (DateTime.utc(2026, 12, 15, 2), 'Asia/Ho_Chi_Minh'));
      expect(resolveLocalTime(const LocalTime('2026-02-30'), 'Asia/Ho_Chi_Minh'), isNull);
    });
  });

  group('toImportedItem', () {
    test('vé máy bay: đặt chỗ, tên mặc định từ mã chuyến, mã đặt chỗ vào ghi chú; không có mặc định theo loại thì nhắc đúng giờ', () {
      final c = decodeImport(req('$docs/synthetic-jsonld-flight-0001/input.eml')).candidates.single;
      final title = fallbackTitle(c)!;
      expect(title, 'ZZ 245 · SGN → HAN');
      final i = toImportedItem(c, title: title, deviceTz: 'Asia/Ho_Chi_Minh', labels: labels);
      expect((i.kind, i.startsAt, i.tz, i.endsAt, i.notes),
          ('booking', DateTime.utc(2026, 12, 21, 3, 30), 'Asia/Ho_Chi_Minh', DateTime.utc(2026, 12, 21, 5, 40), 'code XQ7K2M\nseat 14C'));
      expect(i.reminderOffsets, [0]);
    });

    test('đặt chỗ: nhắc mặc định theo loại, booking_details không có tên hành khách; khách sạn nhắc 18:00 hôm trước + 1h trước trả phòng', () {
      final flight = decodeImport(req('$docs/synthetic-jsonld-flight-0001/input.eml'));
      final f = toImportedItem(flight.candidates.single, title: 'x', deviceTz: 'Europe/London', labels: labels, defaults: flight.reminderDefaults.single, tripIndex: 0);
      expect(f.reminderOffsets, [-1440, -180, -120]);
      expect(f.absoluteReminders, isEmpty);
      expect(f.tripIndex, 0);
      final b = f.booking!;
      expect((b['booking_type'], b['carrier_code'], (b['origin']! as Map)['tz'], b.containsKey('passengers')), ('flight', 'ZZ', 'Asia/Ho_Chi_Minh', false));
      expect((b['extraction_meta']! as Map)['source'], 'jsonld');

      final hotel = decodeImport(req('$docs/synthetic-email-hotel-0001/input.eml'));
      expect(hotel.trips.single.confident, isTrue);
      final h = toImportedItem(hotel.candidates.single, title: 'x', deviceTz: 'Asia/Ho_Chi_Minh', labels: labels, defaults: hotel.reminderDefaults.single);
      expect(h.reminderOffsets, isEmpty, reason: 'khách sạn chỉ có mốc tuyệt đối');
      expect(h.absoluteReminders, [DateTime.utc(2026, 12, 20, 11), DateTime.utc(2026, 12, 23, 4)]);
      expect((h.booking!['check_in_at'], h.booking!['check_out_at']), ('2026-12-21T07:00:00.000Z', '2026-12-23T05:00:00.000Z'));
    });

    test('đặt chỗ đã có: cùng mã + chặng + giờ là trùng; giờ khác là cập nhật; chặng khác là mới', () {
      final c = decodeImport(req('$docs/synthetic-email-flight-text-0001/input.eml', region: 'US')).candidates;
      final existing = [
        ExistingBooking(itemId: 'a', confirmationCode: 'k7pq2w', bookingType: 'flight', carrierCode: 'ZY', number: '1208', startsAt: DateTime.utc(2027, 1, 10, 4, 55), tripId: 't'),
        ExistingBooking(itemId: 'b', confirmationCode: 'K7PQ2W', bookingType: 'flight', carrierCode: 'ZY', number: '1213', startsAt: DateTime.utc(2027, 1, 17, 8)),
      ];
      final m = matchExistingBookings(c, existing, deviceTz: 'Asia/Ho_Chi_Minh');
      expect((m[0]!.itemId, m[0]!.duplicate, m[0]!.tripId), ('a', true, 't'));
      expect((m[1]!.itemId, m[1]!.duplicate), ('b', false), reason: 'LHR 09:40 = 09:40Z, đã lưu 08:00Z');
      expect(matchExistingBookings(c, [existing[0]], deviceTz: 'Asia/Ho_Chi_Minh')[1], isNull);
    });

    test('Markdown: việc cả ngày có lặp, việc con, đã xong, list', () {
      final cs = decodeImport(req('$docs/synthetic-md-todo-0001/input.md')).candidates;
      final bill = toImportedItem(cs[3], title: cs[3].fields.title!, deviceTz: 'Asia/Ho_Chi_Minh', labels: labels);
      expect((bill.startDate, bill.tz, bill.recurrenceStart, bill.listName), ('2026-12-05', 'Asia/Ho_Chi_Minh', DateTime.utc(2026, 12, 4, 17), 'Định kỳ'));
      expect(bill.recurrence, {'kind': 'rrule', 'rrule': 'FREQ=MONTHLY;BYMONTHDAY=5'});
      final gate = toImportedItem(cs[2], title: 'x', deviceTz: 'Asia/Ho_Chi_Minh', labels: labels);
      expect(gate.checklist, [(text: 'Mua sơn chống gỉ', done: false), (text: 'Mua cọ', done: false)]);
      expect(toImportedItem(cs[1], title: 'x', deviceTz: 'Asia/Ho_Chi_Minh', labels: labels).done, isTrue);
      final none = toImportedItem(const Candidate(kind: CandidateKind.task, source: 'md', fields: CandidateFields(title: 'a')),
          title: 'a', deviceTz: 'Asia/Ho_Chi_Minh', labels: labels);
      expect((none.startsAt, none.startDate, none.tz), (null, null, null));
      expect(none.reminderOffsets, isEmpty);
    });
  });

  group('decodeImport', () {
    test('nhận loại theo đuôi và theo nội dung khi mất đuôi', () {
      final ics = File('$docs/synthetic-ics-0001/input.ics').readAsBytesSync();
      final xlsx = File('$docs/synthetic-xlsx-todo-0001/input.xlsx').readAsBytesSync();
      final eml = File('$docs/synthetic-email-hotel-0001/input.eml').readAsBytesSync();
      expect(detectFormat('invite', ics), ImportFormat.ics);
      expect(detectFormat('download', xlsx), ImportFormat.xlsx);
      expect(detectFormat('message', eml), ImportFormat.email);
      expect(detectFormat('scan.PDF', Uint8List(0)), ImportFormat.unsupported);
      expect(detectFormat('notes.txt', Uint8List(0)), ImportFormat.text);
    });

    test('email: đặt phòng + PDF chưa đọc được; bảng: ngôn ngữ, thứ tự ngày; mỗi loại đúng imports.kind', () {
      final email = decodeImport(req('$docs/synthetic-email-hotel-0001/input.eml'));
      expect((email.recordKind, email.candidates.length, email.subject), ('email', 1, 'Xác nhận đặt phòng HB-48213'));
      expect(email.pendingAttachments, ['invoice.pdf']);
      final csv = decodeImport(req('$docs/synthetic-csv-todo-0001/input.csv'));
      expect((csv.recordKind, csv.docLanguage, csv.dateOrder, csv.dateOrderAmbiguous, csv.candidates.length), ('xlsx', 'vi', 'dmy', false, 4));
      final xlsx = decodeImport(req('$docs/synthetic-xlsx-todo-0001/input.xlsx'));
      expect((xlsx.docLanguage, xlsx.candidates.first.fields.title), ('en', 'Renew passport'));
      expect(xlsx.sheetNames, ['Trip prep']);
    });

    test('bảng mơ hồ: chọn lại thứ tự ngày; tệp chữ: mỗi dòng 1 việc qua NLU; PDF: chưa hỗ trợ', () {
      final dir = Directory.systemTemp.createTempSync('imp');
      addTearDown(() => dir.deleteSync(recursive: true));
      File('${dir.path}/a.csv').writeAsStringSync('Task,Due\nPay rent,03/04/2027\n');
      final amb = decodeImport(req('${dir.path}/a.csv', region: null));
      expect((amb.dateOrderAmbiguous, amb.candidates.single.fields.due!.local), (true, '2027-04-03'));
      final mdy = decodeImport(req('${dir.path}/a.csv', region: null, dateOrder: 'mdy'));
      expect(mdy.candidates.single.fields.due!.local, '2027-03-04');
      File('${dir.path}/b.txt').writeAsStringSync('Mua sữa\nHọp nhóm 9h sáng mai\n');
      final txt = decodeImport(req('${dir.path}/b.txt'));
      expect(txt.candidates.map((c) => (c.fields.title, c.fields.due?.local)), [('Mua sữa', null), ('Họp nhóm', '2026-11-25T09:00')]);
      File('${dir.path}/c.pdf').writeAsBytesSync([0x25, 0x50, 0x44, 0x46]);
      expect(decodeImport(req('${dir.path}/c.pdf')).format, ImportFormat.unsupported);
    });

    test('tầng luật T2: vé dạng chữ (.txt), email không có JSON-LD; giờ theo múi giờ sân bay', () {
      final txt = decodeImport(req('$docs/synthetic-flight-0001/input.txt'));
      expect((txt.docType, txt.recordKind), (DocType.flight, 'text'));
      final c = txt.candidates.single;
      expect(fallbackTitle(c), 'ZZ 245 · SGN → HAN');
      expect(c.fieldConfidence['starts_at'], lessThan(0.7));
      final i = toImportedItem(c, title: 'ZZ 245', deviceTz: 'Europe/London', labels: labels);
      expect((i.startsAt, i.tz, i.endsAt), (DateTime.utc(2026, 12, 21, 3, 30), 'Asia/Ho_Chi_Minh', DateTime.utc(2026, 12, 21, 5, 40)));

      final email = decodeImport(req('$docs/synthetic-email-flight-text-0001/input.eml', region: 'US'));
      expect((email.docType, email.subject), (DocType.flight, 'Your trip confirmation - ref K7PQ2W'));
      expect([for (final c in email.candidates) fallbackTitle(c)], ['ZY 1208 · JFK → LHR', 'ZY 1213 · LHR → JFK']);
      expect(email.candidates.first.fields.endsAt.toString(), '2027-01-10T12:05[Europe/London]');

      final hotel = decodeImport(req('$docs/synthetic-hotel-text-0001/input.txt'));
      expect((hotel.docType, hotel.candidates.single.fields.title), (DocType.hotel, 'Khách sạn Hoa Sen Hội An'));
    });

    test('cần kiểm tra chỉ tính trường form sửa được; T0 có cấu trúc thì không', () {
      final t2 = decodeImport(req('$docs/synthetic-flight-0001/input.txt')).candidates.single;
      expect(needsCheck(t2), isTrue);
      expect(t2.fieldConfidence['passenger_count'], lessThan(lowConfidence), reason: 'số khách thấp nhưng không lưu vào item');
      final confirmed = t2.copyWith(fieldConfidence: {...t2.fieldConfidence, for (final k in reviewKeys(t2)) k: 1.0});
      expect(needsCheck(confirmed), isFalse);
      expect(needsCheck(decodeImport(req('$docs/synthetic-jsonld-flight-0001/input.eml')).candidates.single), isFalse);
      final slip = decodeImport(req('$docs/synthetic-medical-text-0001/input.txt')).candidates.single;
      expect(reviewKeys(slip), containsAll(['department', 'queue_number', 'preparation', 'location_text']));
    });

    test('T2 tàu + lịch khám: ga theo tên làm địa điểm, chi tiết vào ghi chú, dặn dò lên đầu, giờ tường theo máy', () {
      final train = decodeImport(req('$docs/synthetic-train-text-0001/input.txt')).candidates.single;
      expect(fallbackTitle(train), 'SE3 · Sài Gòn → Đà Nẵng');
      final t = toImportedItem(train, title: 'SE3', deviceTz: 'Asia/Ho_Chi_Minh', labels: labels);
      expect((t.kind, t.locationText, t.notes, t.tz), ('booking', 'Sài Gòn', 'code TQ8L4P\ncar 5\nseat 23', 'Asia/Ho_Chi_Minh'));
      expect((t.startsAt, t.endsAt), (DateTime.utc(2026, 12, 28, 15), DateTime.utc(2026, 12, 29, 8, 40)));

      final slip = decodeImport(req('$docs/synthetic-medical-text-0001/input.txt'));
      expect(slip.docType, DocType.medical);
      final m = toImportedItem(slip.candidates.single, title: slip.candidates.single.fields.title!, deviceTz: 'Asia/Ho_Chi_Minh', labels: labels);
      expect((m.kind, m.title, m.startsAt), ('appointment', 'BỆNH VIỆN ĐA KHOA VÍ DỤ', DateTime.utc(2027, 1, 7, 1, 30)));
      expect(m.notes, 'Nhịn ăn 8 tiếng trước khi lấy máu\ndept Tim mạch\nno 015');
      expect(m.locationText, '1 Đường Ví Dụ, Quận 1, TP. Hồ Chí Minh');
    });
  });
}
