import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_data/remindme_data.dart';

import 'helpers.dart';
import 'quick_add_test.dart' show openQuickAdd;

const phone = Size(390, 844);
const vi = Locale('vi');

void main() {
  Future<void> openLists(WidgetTester tester) async {
    await tester.tap(find.text('Tôi').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Danh sách'));
    await tester.pumpAndSettle();
  }

  testWidgets('tạo list, đếm việc, mở list, đổi tên, xóa → việc về Hộp thư', (tester) async {
    await pumpApp(tester, size: phone, locale: vi, region: 'VN', seed: (r) async => r.create(title: 'Gọi mẹ'));
    await openLists(tester);
    expect(find.text('Hộp thư'), findsOneWidget);
    expect(find.text('1 mục đang mở'), findsOneWidget);
    await tester.tap(find.byKey(const Key('newList')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('listName')), 'Công việc');
    await tester.tap(find.text('Lưu'));
    await settleReminders(tester);
    expect(find.text('Công việc'), findsOneWidget);
    expect(find.text('Không có mục đang mở'), findsOneWidget);

    // Chuyển "Gọi mẹ" sang list mới từ màn chi tiết.
    await tester.tap(find.text('Hộp thư'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gọi mẹ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('itemList')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Công việc').last);
    await settleReminders(tester);
    expect(find.descendant(of: find.byKey(const Key('itemList')), matching: find.text('Công việc')), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back).last);
    await tester.pumpAndSettle();
    expect(find.text('Danh sách này chưa có mục nào đang mở'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back).last);
    await tester.pumpAndSettle();

    // Đổi tên rồi xóa list.
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đổi tên'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('listName')), 'Việc công ty');
    await tester.tap(find.text('Lưu'));
    await settleReminders(tester);
    expect(find.text('Việc công ty'), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa danh sách').last);
    await tester.pumpAndSettle();
    expect(find.text('Các mục trong danh sách sẽ chuyển về Hộp thư.'), findsOneWidget);
    await tester.tap(find.text('Xóa'));
    await settleReminders(tester);
    expect(find.text('Việc công ty'), findsNothing);
    expect(find.text('1 mục đang mở'), findsOneWidget);
  });

  testWidgets('Quick Add "#congviec" vào list "Công việc"', (tester) async {
    await pumpApp(tester, size: phone, locale: vi, region: 'VN', seed: (r) async {
      final lists = ListsRepository(r.engine);
      await lists.create('Công việc');
    });
    await openQuickAdd(tester, 'Gửi báo giá #congviec');
    await tester.tap(find.byKey(const Key('quickAddSave')));
    await settleReminders(tester);
    await openLists(tester);
    expect(find.descendant(of: find.byKey(const Key('list-inbox')), matching: find.text('Không có mục đang mở')), findsOneWidget);
    expect(find.text('1 mục đang mở'), findsOneWidget);
  });

  testWidgets('tìm kiếm không dấu từ Hôm nay; không khớp thì báo', (tester) async {
    await pumpApp(tester, size: phone, locale: vi, region: 'VN', seed: (r) async {
      await r.create(title: 'Đặt vé đi Đà Lạt');
      await r.create(title: 'Mua sữa', notes: 'loại không đường');
    });
    await tester.tap(find.byKey(const Key('openSearch')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('searchField')), 'da lat');
    await settleReminders(tester);
    expect(find.text('Đặt vé đi Đà Lạt'), findsOneWidget);
    expect(find.text('Mua sữa'), findsNothing);
    await tester.enterText(find.byKey(const Key('searchField')), 'khong duong');
    await settleReminders(tester);
    expect(find.text('Mua sữa'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('searchField')), 'xyz');
    await settleReminders(tester);
    expect(find.text('Không có mục nào khớp'), findsOneWidget);
  });
}
