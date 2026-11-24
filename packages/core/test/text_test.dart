import 'package:remindme_core/remindme_core.dart';
import 'package:test/test.dart';

void main() {
  test('foldForSearch bỏ dấu, hạ chữ thường, gộp khoảng trắng', () {
    expect(foldForSearch('Công  Việc'), 'cong viec');
    expect(foldForSearch('ĐÀ LẠT'), 'da lat');
    expect(foldForSearch('Ñandú Straße'), 'nandu strasse');
    expect(foldForSearch('東京 旅行'), '東京 旅行');
    expect(foldForSearch('Khám thai #congviec'), 'kham thai #congviec');
    expect(foldForSearch('Vie\u0302\u0323t'), 'viet', reason: 'NFD');
  });
}
