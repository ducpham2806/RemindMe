import 'package:remindme_core/remindme_core.dart';
import 'package:test/test.dart';

void main() {
  test('uuidV7 đúng version/variant và tăng dần theo thời gian', () {
    final a = uuidV7(nowMillis: 1764000000000);
    final b = uuidV7(nowMillis: 1764000000001);
    final re = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
    expect(re.hasMatch(a), isTrue);
    expect(a.compareTo(b) < 0, isTrue);
    expect(a.substring(0, 13), '019ab697-e800');
  });

  test('inboxListId khớp md5(uid || \':inbox\')::uuid của Postgres', () {
    // Giá trị lấy từ: select md5('3f2b8c1e-9a4d-4e6b-8c2f-1a2b3c4d5e6f'::uuid::text || ':inbox')::uuid
    expect(inboxListId('3f2b8c1e-9a4d-4e6b-8c2f-1a2b3c4d5e6f'), 'ac4ad265-9a9b-3046-36d4-b1654e236c3c');
    expect(inboxListId('3F2B8C1E-9A4D-4E6B-8C2F-1A2B3C4D5E6F'), 'ac4ad265-9a9b-3046-36d4-b1654e236c3c');
  });
}
