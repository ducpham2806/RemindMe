import 'dart:io';

import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_parsers/remindme_parsers.dart';
import 'package:test/test.dart';

final vi = GrammarPack.fromYaml(File('nlu/packs/vi.yaml').readAsStringSync());
final en = GrammarPack.fromYaml(File('nlu/packs/en.yaml').readAsStringSync());
final airports = AirportIndex.parse(File('data/airports.tsv').readAsStringSync());
final ref = DateTime(2026, 11, 24);

RuleExtraction run(String text, {String? lang, String? region, List<ProviderTemplate> templates = const [], String? sender}) =>
    RuleEngine(packs: [vi, en], airports: airports, region: region, templates: templates)
        .extract(TextDocument.fromText(text, language: lang, senderDomain: sender), reference: ref);

void main() {
  group('anchor', () {
    test('không dấu, không phân biệt hoa thường, chịu lỗi OCR, trọn từ', () {
      final doc = TextDocument.fromText('MA DAT CHO: AB12CD\nBookinq c0de - XY34ZW\nSeats: 4\n予約番号ABC123');
      expect(doc.findAnchor('Mã đặt chỗ').single.line, 0);
      final fuzzy = doc.findAnchor('Booking code').single;
      expect((fuzzy.line, fuzzy.score < 1), (1, true));
      expect(doc.findAnchor('seat'), isEmpty, reason: '"Seats" không phải "seat"');
      expect(doc.findAnchor('予約番号').single.line, 3, reason: 'CJK không có ranh giới từ');
    });

    test('vị trí trả về theo chuỗi gốc (chữ có dấu dạng NFD)', () {
      const nfd = 'Ghế: 12A'; // "Ghế" viết NFD
      final hit = TextDocument.fromText(nfd).findAnchor('ghế').single;
      expect(nfd.substring(hit.end), ': 12A');
    });

    test('bbox: giá trị ở cột bên phải hoặc dòng bên dưới', () {
      final doc = TextDocument([
        const TextLine('Seat', box: TextBox(0.05, 0.40, 0.15, 0.43)),
        const TextLine('Gate', box: TextBox(0.50, 0.40, 0.60, 0.43)),
        const TextLine('12F', box: TextBox(0.05, 0.44, 0.12, 0.47)),
        const TextLine('B7', box: TextBox(0.50, 0.44, 0.56, 0.47)),
        const TextLine('Booking code', box: TextBox(0.05, 0.10, 0.30, 0.13)),
        const TextLine('Q8RT2Z', box: TextBox(0.60, 0.10, 0.80, 0.13)),
      ]);
      final seat = doc.findAnchor('seat').single;
      expect(doc.below(seat).map(doc.regionText).first, '12F', reason: 'dòng dưới cùng cột, không lấy "B7"');
      final code = doc.findAnchor('booking code').single;
      expect(doc.rightOf(code).map(doc.regionText), ['', 'Q8RT2Z']);
    });
  });

  group('giá trị', () {
    test('ngày theo gói và theo vùng', () {
      final r = ValueReader([vi, en], language: 'vi');
      String iso(String s, ValueReader r) => r.dates(s).single.iso(ref);
      expect(iso('Ngày 21 tháng 12 năm 2026', r), '2026-12-21');
      expect(iso('Thứ Hai, 21/12/2026', r), '2026-12-21');
      expect(iso('Sat, Jan 9, 2027', r), '2027-01-09');
      expect(iso('20 December 2026', r), '2026-12-20');
      expect(iso('2026-12-05T10:30', r), '2026-12-05');
      expect(iso('03/04/2027', ValueReader([vi, en], region: 'US', language: 'en')), '2027-03-04');
      expect(iso('03/04/2027', ValueReader([vi, en], region: 'GB', language: 'en')), '2027-04-03');
      final unknown = ValueReader([vi, en], language: 'en').dates('03/04/2027').single;
      expect(unknown.orderAmbiguous, isTrue);
      expect(ValueReader([vi, en], language: 'en').dates('13/04/2027').single.orderAmbiguous, isFalse);
      expect(iso('Dec 2', r), '2026-12-02', reason: 'thiếu năm: lần gần nhất từ ngày tham chiếu');
      expect(iso('Jan 9', r), '2027-01-09');
    });

    test('giờ: 24h, 10h30, am/pm; bỏ "at 10" và phần chồng lên ngày', () {
      final r = ValueReader([vi, en], language: 'vi');
      List<String> hm(String s) => [for (final t in r.times(s)) t.hm];
      expect(hm('10:30 → 12:40'), ['10:30', '12:40']);
      expect(hm('Giờ khởi hành 10h30, có mặt lúc 9 giờ'), ['10:30', '09:00']);
      expect(hm('11:55 PM -> 12:05 AM'), ['23:55', '00:05']);
      expect(hm('meet at 10'), isEmpty);
      expect(hm('21.12.2026'), isEmpty);
    });

    test('tiền: phân cách theo đồng tiền, ký hiệu mơ hồ thì bỏ', () {
      final r = ValueReader([vi, en]);
      List<String> money(String s) => [for (final m in r.money(s)) '${m.price.amount} ${m.price.currency}'];
      expect(money('Tổng tiền: 1.890.000 VND'), ['1890000 VND']);
      expect(money('2.450.000₫'), ['2450000 VND']);
      expect(money('€1.234,50'), ['1234.50 EUR']);
      expect(money('US\$1,284.60'), ['1284.60 USD']);
      expect(money('12,5 EUR'), ['12.50 EUR']);
      expect(money('¥12,000'), isEmpty, reason: '¥ có thể là JPY hoặc CNY');
      expect(money('\$1,234.50'), isEmpty, reason: '\$ một mình không đoán USD');
      expect(money('JPY 12,000'), ['12000 JPY']);
    });

    test('mã sân bay: trong ngoặc, thành cặp, đứng một mình phải có trong từ điển; mã tiền tệ đứng một mình bỏ', () {
      final r = ValueReader([vi, en], airports: airports);
      List<String> codes(String s) => [for (final m in r.airportsIn(TextDocument.fromText(s), 0)) '${m.code}${m.strong ? '!' : ''}'];
      expect(codes('Hồ Chí Minh (SGN) 10:30 → Hà Nội (HAN)'), ['SGN!', 'HAN!']);
      expect(codes('MAD-BCN 07:00'), ['MAD!', 'BCN!']);
      expect(codes('SGN 10:30 HAN 12:40'), ['SGN', 'HAN']);
      expect(codes('Total 100 USD, THE END'), isEmpty);
      expect(airports['HAN']!.tz, 'Asia/Ho_Chi_Minh', reason: 'nước 1 múi giờ lấy theo zone.tab');
    });

    test('dữ liệu sân bay: mọi múi giờ có trong tzdata', () {
      expect(airports.length, greaterThan(7000));
      final zones = File('data/airports.tsv').readAsLinesSync().where((l) => !l.startsWith('#')).map((l) => l.split('\t')[2]).toSet();
      expect([for (final z in zones) if (!TimeZones.isValid(z)) z], isEmpty);
    });
  });

  group('phân loại', () {
    test('khách sạn, khám bệnh, không đủ tín hiệu', () {
      final c = DocClassifier([vi, en]);
      expect(c.classify(TextDocument.fromText('Ngày nhận phòng 05/01\nNgày trả phòng 07/01\nLoại phòng: Deluxe')).type, DocType.hotel);
      expect(c.classify(TextDocument.fromText('PHIẾU HẸN TÁI KHÁM\nBệnh viện Ví Dụ - Phòng khám Nội\nSố thứ tự: 12')).type, DocType.medical);
      expect(c.classify(TextDocument.fromText('Mua sữa, gọi cho mẹ')).type, DocType.unknown);
    });
  });

  group('extractor chung', () {
    test('qua đêm không có "+1": suy theo UTC, cảnh báo', () {
      final r = run('Flight ZY 88  Dec 20, 2026\nLos Angeles (LAX) 11:00 PM -> New York (JFK) 7:30 AM', lang: 'en', region: 'US');
      final c = r.candidates.single;
      expect(c.fields.endsAt.toString(), '2026-12-21T07:30[America/New_York]');
      expect(c.issues, contains('arrival_next_day'));
      expect(c.fieldConfidence['ends_at'], Slot.inferred);
    });

    test('bay về phía tây qua đường đổi ngày: đến "sớm hơn" vẫn cùng ngày', () {
      final r = run('Flight ZY 5  Dec 20, 2026\nTokyo (NRT) 9:00 PM -> Honolulu (HNL) 9:30 AM', lang: 'en', region: 'US');
      expect(r.candidates.single.fields.endsAt!.local, '2026-12-20T09:30');
    });

    test('sân bay đi = đến thì bỏ; thiếu ngày thì không đoán', () {
      expect(run('Flight ZY 1 Dec 20, 2026\n(SGN) 10:00 -> (SGN) 11:00').candidates, isEmpty);
      expect(run('Flight ZY 1\n(SGN) 10:00 -> (HAN) 12:00').candidates, isEmpty);
    });

    test('ngày đã qua: vẫn đề xuất, kèm cảnh báo', () {
      final c = run('Chuyến bay ZZ 245  01/11/2026\nTP. Hồ Chí Minh (SGN) 10:30 → Hà Nội (HAN) 12:40', lang: 'vi', region: 'VN').candidates.single;
      expect(c.issues, contains('past_date'));
    });

    test('khách sạn: trả phòng trước nhận phòng thì bỏ trả phòng; tên chỉ lấy sau nhãn', () {
      final c = run('Khách sạn: Biển Xanh\nNhận phòng: 05/01/2027\nTrả phòng: 03/01/2027\nLoại phòng: Deluxe', lang: 'vi').candidates.single;
      expect((c.fields.checkIn!.local, c.fieldConfidence['check_in']), ('2027-01-05T14:00', Slot.inferred), reason: 'thiếu giờ: 14:00');
      expect(c.fields.checkOut, isNull);
      expect(c.issues, contains('check_out_before_check_in'));
      final text = run('Cảm ơn quý khách đã đặt phòng tại Khách sạn Biển Xanh.\nMã đặt phòng: HB-48213\nNhận phòng: 21/12/2026 14:00\n'
          'Trả phòng: 23/12/2026 12:00', lang: 'vi').candidates.single;
      expect(text.fields.title, isNull, reason: '"tại Khách sạn ..." trong câu văn không phải nhãn');
      expect(text.fields.confirmationCode, 'HB-48213');
      expect(text.fields.checkOut!.local, '2026-12-23T12:00');
    });
  });

  group('tàu, xe, lịch khám, sự kiện', () {
    test('tàu không có nhãn ga: dòng có mũi tên; đến sớm hơn giờ đi thì hôm sau (cảnh báo)', () {
      final c = run('VÉ TÀU - Đường sắt Ví Dụ\nTàu: SE1   Ngày đi: 01/01/2027\nHà Nội 19:30 → Vinh 01:10\nToa 3 Giường 12', lang: 'vi').candidates.single;
      expect((c.bookingType, c.fields.number, c.fields.origin!.name, c.fields.destination!.name), (BookingType.train, 'SE1', 'Hà Nội', 'Vinh'));
      expect((c.fields.startsAt!.local, c.fields.endsAt!.local), ('2027-01-01T19:30', '2027-01-02T01:10'));
      expect(c.issues, contains('arrival_next_day'));
      expect((c.fields.carriage, c.fields.seat), ('3', '12'));
    });

    test('xe: điểm đón = điểm trả thì bỏ', () {
      expect(run('Nhà xe: Ví Dụ\nBến xe khách\nĐiểm đón: Bến xe A, 07:30 ngày 03/01/2027\nĐiểm trả: Bến xe A', lang: 'vi').candidates, isEmpty);
    });

    test('lịch khám: ngày sinh không bao giờ là ngày hẹn, kể cả khi ngày hẹn không có nhãn', () {
      final c = run('PHÒNG KHÁM VÍ DỤ\nPhiếu hẹn - Bệnh nhân: NGUYEN VAN A\nNgày sinh: 01/02/1990\nTái khám 05/01/2027 lúc 9:00\nBác sĩ dặn: không ăn sáng',
              lang: 'vi')
          .candidates
          .single;
      expect((c.kind, c.fields.title, c.fields.startsAt!.local), (CandidateKind.appointment, 'PHÒNG KHÁM VÍ DỤ', '2027-01-05T09:00'));
      expect(c.fields.preparation, 'Bác sĩ dặn: không ăn sáng');
      expect(c.fieldConfidence['starts_at'], Slot.pattern);
      expect(c.toJson().toString(), isNot(contains('NGUYEN')), reason: 'không trả tên bệnh nhân');
    });

    test('sự kiện cần tên hoặc nơi tổ chức', () {
      expect(run('Showtime: 19 Dec 2026, 7:15 PM\nSeat: G12\nCinema ticket', lang: 'en').candidates, isEmpty);
    });

    test('anchor mờ không nhận nhầm nhãn của trường khác ("điểm đón" ≠ "điểm đến")', () {
      final hits = AnchorReader(TextDocument.fromText('Điểm đón: A\nĐiểm đến: B'), [vi]).hitsFor('destination');
      expect(hits.map((h) => h.line), [1]);
    });
  });

  group('mẫu nhà cung cấp', () {
    final template = ProviderTemplate.parse(File('test/templates/zz.eticket.v1.json').readAsStringSync());
    const ticket = 'ZZ AIR e-ticket\nRecord locator\nQWE7RT\nSegment 1\nZZ 101  (SGN) - (BKK)\nDate 01/02/2027\n'
        'Departs 08:15   Arrives 09:45\nSeat 3A\nSegment 2\nZZ 102  (BKK) - (SGN)\nDate 01/09/2027\nDeparts 18:00   Arrives 19:30';

    test('khớp mẫu: mỗi khối 1 chặng, trường đầu tài liệu dùng chung, thứ tự ngày của mẫu', () {
      final r = run(ticket, templates: [template]);
      expect(r.templateId, 'zz.eticket.v1@3');
      expect(r.candidates, hasLength(2));
      final [a, b] = r.candidates;
      expect((a.source, a.confidence), ('template:zz.eticket.v1', Slot.template));
      expect([a.fields.confirmationCode, b.fields.confirmationCode], ['QWE7RT', 'QWE7RT']);
      expect('${a.fields.carrierCode}${a.fields.number} ${a.fields.origin!.code}-${a.fields.destination!.code} ${a.fields.startsAt}',
          'ZZ101 SGN-BKK 2027-01-02T08:15[Asia/Ho_Chi_Minh]');
      expect('${b.fields.number} ${b.fields.startsAt} → ${b.fields.endsAt}', '102 2027-01-09T18:00[Asia/Bangkok] → 2027-01-09T19:30[Asia/Ho_Chi_Minh]');
      expect([a.fields.seat, b.fields.seat], ['3A', null]);
    });

    test('không đủ điểm thì dùng extractor chung', () {
      final r = run('Chuyến bay ZZ 245  21/12/2026\nTP. Hồ Chí Minh (SGN) 10:30 → Hà Nội (HAN) 12:40', templates: [template]);
      expect((r.templateId, r.candidates.single.source), (null, 'generic'));
    });

    test('tên miền người gửi cộng điểm; trường lạ trong mẫu bị từ chối', () {
      expect(template.score(TextDocument.fromText('ZZ 101', senderDomain: 'mail.zzair.example')), 3);
      expect(() => ProviderTemplate.parse('{"id":"x","doc_type":"flight","version":1,"fields":{"pnr":{}}}'), throwsFormatException);
    });
  });
}
