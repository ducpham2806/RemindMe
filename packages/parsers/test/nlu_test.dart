import 'dart:io';

import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_parsers/remindme_parsers.dart';
import 'package:remindme_parsers/src/nlu/eval.dart';
import 'package:test/test.dart';

GrammarPack pack(String lang) => GrammarPack.fromYaml(File('nlu/packs/$lang.yaml').readAsStringSync());

void main() {
  final vi = NluEngine([pack('vi')]);
  final en = NluEngine([pack('en')]);
  // thứ Ba 1/12/2026 10:00
  final ctx = NluContext(now: DateTime(2026, 12, 1, 10), region: 'VN');
  NluResult p(NluEngine e, String s, [NluContext? c]) => e.parse(s, c ?? ctx);

  group('bộ câu (ngưỡng cấp A, voice-and-text-input.md §7)', () {
    for (final lang in ['vi', 'en']) {
      test(lang, () {
        final r = evaluateNlu(NluEngine([pack(lang)]), File('fixtures/nlu/$lang.json').readAsStringSync());
        printOnFailure('$r');
        expect(r.total, greaterThanOrEqualTo(50));
        expect(r.accuracy, greaterThanOrEqualTo(0.92), reason: '$r');
        expect(r.dangerousRate, lessThanOrEqualTo(0.01), reason: '$r');
      });
    }
  });

  group('bẫy (mỗi bẫy phải có test, §5)', () {
    test('"Mai" là tên người khi viết hoa giữa câu; đầu câu vẫn là ngày mai', () {
      expect(p(vi, 'Gọi cho Mai').when, isNull);
      expect(p(vi, 'Mai gọi cho Lan').when, When(CivilDate(2026, 12, 2)));
      expect(p(vi, 'gọi cho bác sĩ mai lúc 9h tối').when, When(CivilDate(2026, 12, 2), CivilTime(21)), reason: 'viết thường = ngày mai');
    });

    test('"ăn sáng", "bữa tối" là bữa ăn, không phải buổi', () {
      expect(p(vi, 'Ăn sáng với Lan').when, isNull);
      expect(p(vi, 'đặt bàn bữa tối').when, isNull);
    });

    test('"2 giờ nữa" là sau 2 tiếng, không phải 2:00', () {
      expect(p(vi, '2 giờ nữa tắt bếp').when, When(CivilDate(2026, 12, 1), CivilTime(12)));
    });

    test('"3 giờ kém 15" (Bắc) = 2:45, chiều → 14:45', () {
      expect(p(vi, '3 giờ kém 15 chiều đón con').when!.time, CivilTime(14, 45));
    });

    test('en-GB "half seven" = 7:30, kèm chip sáng/tối', () {
      final r = p(en, 'half seven dinner');
      expect(r.when!.time!.minute, 30);
      expect(r.ambiguities.single.kind, AmbiguityKind.meridiem);
      expect(r.ambiguities.single.options.map((o) => o.time), [CivilTime(7, 30), CivilTime(19, 30)]);
    });

    test('số thập phân không phải giờ: "1.5 kg"', () {
      expect(p(en, 'weigh 1.5 kg flour').when, isNull);
    });

    test('03/04: theo vùng; không biết vùng thì hỏi', () {
      DateTime now() => DateTime(2026, 12, 1, 10);
      expect(p(en, 'meeting 03/04', NluContext(now: now(), region: 'US')).when!.date, CivilDate(2027, 3, 4));
      expect(p(en, 'meeting 03/04', NluContext(now: now(), region: 'GB')).when!.date, CivilDate(2027, 4, 3));
      final r = p(en, 'meeting 03/04', NluContext(now: now()));
      expect(r.ambiguities.single.kind, AmbiguityKind.dateOrder);
      expect(p(en, 'dentist 12/15', NluContext(now: now())).ambiguities, isEmpty, reason: '15 không thể là tháng');
    });

    test('"thứ 3" khi hôm nay là thứ 3: hỏi hôm nay hay tuần sau', () {
      final r = p(vi, 'thứ 3 nộp đơn');
      expect(r.ambiguities.single.kind, AmbiguityKind.sameWeekday);
      expect(r.ambiguities.single.options.map((o) => o.date), [CivilDate(2026, 12, 1), CivilDate(2026, 12, 8)]);
      // Có giờ còn ở phía trước hôm nay thì mặc định hôm nay.
      expect(p(vi, 'thứ 3 lúc 5 giờ chiều nộp đơn').when, When(CivilDate(2026, 12, 1), CivilTime(17)));
    });

    test('en "next Friday" khi thứ 6 còn trong tuần này: hỏi', () {
      final r = p(en, 'next Friday drinks');
      expect(r.ambiguities.single.kind, AmbiguityKind.nextWeekday);
      expect(r.when!.date, CivilDate(2026, 12, 11));
    });

    test('giờ đã qua hôm nay → ngày mai', () {
      expect(p(vi, 'họp 19h').when!.date, CivilDate(2026, 12, 1));
      expect(p(vi, 'chạy bộ 6h sáng').when!.date, CivilDate(2026, 12, 2));
    });

    test('liên từ: chỉ tách khi mỗi phần có thời điểm riêng', () {
      expect(en.parseAll('buy milk and eggs', ctx), hasLength(1));
      expect(en.parseAll('gym every Monday and Wednesday at 6am', ctx).single.recurrence!.rrule, 'FREQ=WEEKLY;BYDAY=MO,WE');
      final two = vi.parseAll('5h chiều đi bơi rồi 7h tối học bài', ctx);
      expect(two.map((r) => r.title), ['Đi bơi', 'Học bài']);
    });
  });

  test('câu pha 2 ngôn ngữ: gói chính vi + gói phụ en', () {
    final mixed = NluEngine([pack('vi'), pack('en')]);
    final r = mixed.parse('họp meeting với client 3pm thứ 6', ctx);
    expect(r.title, 'Họp meeting với client');
    expect(r.when, When(CivilDate(2026, 12, 4), CivilTime(15)));
    final r2 = mixed.parse('call khách tomorrow 9h sáng', ctx);
    expect(r2.when, When(CivilDate(2026, 12, 2), CivilTime(9)));
  });

  test('âm lịch ra dạng cột recurrences.calendar', () {
    expect(p(vi, 'đi chùa rằm').recurrence!.toPayload(), {
      'kind': 'calendar',
      'calendar': {'system': 'lunar_vi', 'day': 15},
    });
    expect(p(vi, 'giỗ ông 10/3 âm lịch').recurrence!.calendar, {'system': 'lunar_vi', 'month': 3, 'day': 10});
    expect(p(en, 'every full moon').recurrence, isNull, reason: 'gói en không có lunar_system');
  });

  test('span cho chip: mỗi phần đã hiểu có vị trí trong câu gốc', () {
    const s = 'Mai 8h sáng họp khách #congviec';
    final r = p(vi, s);
    final kinds = {for (final x in r.spans) s.substring(x.start, x.end).trim(): x.kind};
    expect(kinds['8h sáng'], SpanKind.time);
    expect(kinds['Mai'], SpanKind.date);
    expect(kinds['#congviec'], SpanKind.tag);
  });

  test('gói sai định dạng báo lỗi rõ', () {
    expect(() => GrammarPack.fromYaml('lang: xx\ntimes:\n  - {type: hm, re: "{nope:h}"}'), throwsFormatException);
    expect(() => GrammarPack.fromYaml('lang: xx\ntimes:\n  - {type: wat, re: "x"}'), throwsFormatException);
  });
}
