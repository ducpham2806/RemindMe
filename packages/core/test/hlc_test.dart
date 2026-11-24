import 'package:remindme_core/remindme_core.dart';
import 'package:test/test.dart';

void main() {
  group('Hlc', () {
    test('pack/parse khớp định dạng server', () {
      final h = Hlc(1764000000000, 1, 'ios-7f3a');
      expect(h.pack(), '1764000000000:0001:ios-7f3a');
      expect(Hlc.parse(h.pack()), h);
    });

    test('so sánh logic trùng so sánh chuỗi theo byte (collate "C")', () {
      final clocks = [
        Hlc(5, 0, 'b'), Hlc(5, 0, 'a'), Hlc(5, 12, 'a'), Hlc(1764000000000, 0, 'z'), Hlc(40, 9999, 'x'),
      ];
      final byLogic = [...clocks]..sort();
      final byString = [...clocks]..sort((a, b) => a.pack().compareTo(b.pack()));
      expect(byLogic.map((h) => h.pack()), byString.map((h) => h.pack()));
    });

    test('node không hợp lệ bị từ chối (không được có dấu :)', () {
      expect(() => Hlc(1, 0, 'a:b'), throwsArgumentError);
      expect(() => Hlc.parse('1:2:3'), throwsFormatException);
    });
  });

  group('HlcClock', () {
    test('send tăng dần kể cả khi giờ máy đứng yên hoặc lùi', () {
      var wall = 1000;
      final clock = HlcClock('dev', now: () => wall);
      final a = clock.send();
      final b = clock.send();
      wall = 900; // người dùng chỉnh giờ lùi
      final c = clock.send();
      expect(a < b && b < c, isTrue);
      expect(c.millis, 1000);
      expect(c.counter, 2);
    });

    test('receive vượt clock từ xa để sửa sau luôn thắng', () {
      final clock = HlcClock('dev', now: () => 1000);
      final remote = Hlc(5000, 3, 'other');
      clock.receive(remote);
      expect(clock.send() > remote, isTrue);
    });

    test('receive báo lệch giờ quá ngưỡng', () {
      final clock = HlcClock('dev', now: () => 0, maxDriftMs: 1000);
      expect(clock.receive(Hlc(500, 0, 'x')), isFalse);
      expect(clock.receive(Hlc(5000, 0, 'x')), isTrue);
    });

    test('counter tràn thì nhảy sang ms kế tiếp', () {
      final clock = HlcClock('dev', now: () => 10, last: Hlc(10, Hlc.maxCounter, 'dev'));
      final next = clock.send();
      expect(next.millis, 11);
      expect(next.counter, 0);
    });
  });
}
