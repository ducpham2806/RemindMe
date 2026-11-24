import 'dart:io';

import 'package:remindme_parsers/remindme_parsers.dart';
import 'package:test/test.dart';

final now = DateTime(2026, 11, 24, 9);
final vi = GrammarPack.fromYaml(File('nlu/packs/vi.yaml').readAsStringSync());
final en = GrammarPack.fromYaml(File('nlu/packs/en.yaml').readAsStringSync());

void main() {
  test('mẫu Obsidian: list theo heading, việc con, đã xong/đã hủy, ưu tiên, lặp, tag front-matter + inline, NLU', () {
    final c = MarkdownDecoder(nlu: NluEngine([vi, en]), region: 'VN')
        .decode(File('fixtures/docs/synthetic-md-todo-0001/input.md').readAsStringSync(), now: now);
    expect(c.map((e) => e.fields.title), ['Thay bóng đèn hành lang', 'Gọi thợ sửa máy giặt', 'Sơn lại cổng', 'Đóng tiền điện', 'Tưới cây', 'Đi siêu thị']);
    expect(c.map((e) => e.listName), ['Sửa chữa', 'Sửa chữa', 'Sửa chữa', 'Định kỳ', 'Định kỳ', 'Định kỳ']);
    expect(c.map((e) => e.done), [false, true, false, false, false, false]);
    expect(c[0].priority, 3);
    expect(c[2].checklist.map((e) => '$e'), ['[ ] Mua sơn chống gỉ', '[ ] Mua cọ']);
    expect(c[3].rrule, 'FREQ=MONTHLY;BYMONTHDAY=5');
    expect(c[5].tags, ['nhà', 'muasam']);
    expect(c.every((e) => e.source == 'md' && e.kind == CandidateKind.task), isTrue);
  });

  test('không có ô checkbox: mọi gạch đầu dòng là việc, thụt lề là việc con; bỏ khối code, định dạng inline, link', () {
    final c = const MarkdownDecoder().decode('''
Ghi chú tự do không phải việc.

* **Gửi** hồ sơ cho [phòng nhân sự](https://example.com)
    * bản sao CCCD
1. Đặt lịch [[Nha khoa Ánh Dương|nha sĩ]] _sớm_
```
- [ ] không phải việc
```
''', now: now);
    expect(c.map((e) => e.fields.title), ['Gửi hồ sơ cho phòng nhân sự', 'Đặt lịch nha sĩ sớm']);
    expect(c.first.checklist.single.text, 'bản sao CCCD');
    expect(c.first.confidence, lessThan(0.9));
  });

  test('front-matter due cho việc không có ngày; emoji có biến thể U+FE0F; ⏰ kèm ngày', () {
    final c = const MarkdownDecoder().decode('---\ndue: 2026-12-31\ntags: work, q4\n---\n'
        '- [ ] Viết tổng kết năm\n- [ ] Họp tổng kết ⏰️ 2026-12-20 14:00 🔼️\n', now: now);
    expect(c.map((e) => e.fields.due!.local), ['2026-12-31', '2026-12-20T14:00']);
    expect(c[1].priority, 2);
    expect(c[0].tags, ['work', 'q4']);
  });

  test('lặp Obsidian → RRULE; không hiểu thì giữ nguyên văn trong ghi chú', () {
    expect(obsidianRecurrenceToRrule('every day'), 'FREQ=DAILY');
    expect(obsidianRecurrenceToRrule('every 2 weeks'), 'FREQ=WEEKLY;INTERVAL=2');
    expect(obsidianRecurrenceToRrule('every weekday'), 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR');
    expect(obsidianRecurrenceToRrule('every week on Monday, Friday'), 'FREQ=WEEKLY;BYDAY=MO,FR');
    expect(obsidianRecurrenceToRrule('every Tuesday and Thursday when done'), 'FREQ=WEEKLY;BYDAY=TU,TH');
    expect(obsidianRecurrenceToRrule('every month on the last'), 'FREQ=MONTHLY;BYMONTHDAY=-1');
    expect(obsidianRecurrenceToRrule('every 3 months on the 1st'), 'FREQ=MONTHLY;INTERVAL=3;BYMONTHDAY=1');
    expect(obsidianRecurrenceToRrule('every year'), 'FREQ=YEARLY');
    expect(obsidianRecurrenceToRrule('mỗi tuần'), isNull);
    final c = const MarkdownDecoder().decode('- [ ] Tập thể dục 🔁 every second Tuesday 📅 2026-12-01', now: now);
    expect((c.single.rrule, c.single.notes, c.single.fields.title), (null, '🔁 every second Tuesday', 'Tập thể dục'));
  });

  test('NLU tiếng Anh trong dòng: giờ, lặp, ưu tiên', () {
    final c = MarkdownDecoder(nlu: NluEngine([en])).decode('- [ ] Call mom every Sunday at 7pm !!', now: now);
    expect((c.single.fields.title, c.single.rrule, c.single.priority), ('Call mom', 'FREQ=WEEKLY;BYDAY=SU', 2));
  });
}
