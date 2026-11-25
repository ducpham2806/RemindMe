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
    expect(find.text('Những việc bạn vừa thêm'), findsOneWidget);
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
    await tester.longPress(find.text('Công việc'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('listRename')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('listName')), 'Việc công ty');
    await tester.tap(find.text('Lưu'));
    await settleReminders(tester);
    expect(find.text('Việc công ty'), findsOneWidget);
    await tester.longPress(find.text('Việc công ty'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('listDelete')));
    await tester.pumpAndSettle();
    expect(find.text('Các mục trong danh sách sẽ chuyển về Hộp thư.'), findsOneWidget);
    await tester.tap(find.text('Xóa'));
    await settleReminders(tester);
    expect(find.text('Việc công ty'), findsNothing);
    expect(find.text('Những việc bạn vừa thêm'), findsOneWidget, reason: 'việc về Hộp thư');
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

  testWidgets('list: đếm quá hạn/hôm nay trên thẻ, nhóm trong list, "Thêm vào" đưa việc mới vào list', (tester) async {
    await pumpApp(tester, size: phone, locale: vi, region: 'VN', seed: (r) async {
      final work = await ListsRepository(r.engine).create('Công việc');
      await r.create(title: 'Gửi báo giá', listId: work, startsAt: testNow.toUtc().subtract(const Duration(days: 1)), tz: 'Asia/Ho_Chi_Minh');
      await r.create(title: 'Họp nhóm', listId: work, startsAt: testNow.toUtc().add(const Duration(minutes: 30)), tz: 'Asia/Ho_Chi_Minh');
    });
    await openLists(tester);
    expect(find.descendant(of: find.byKey(const Key('list-inbox')), matching: find.text('Không có mục đang mở')), findsOneWidget);
    expect(find.text('1 quá hạn · 1 việc hôm nay'), findsOneWidget);
    await tester.tap(find.text('Công việc'));
    await tester.pumpAndSettle();
    expect(find.text('2 việc đang chờ · 1 quá hạn'), findsOneWidget);
    expect(find.text('Quá hạn'), findsOneWidget);
    await tester.tap(find.byKey(const Key('listAddBottom')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Viết báo cáo');
    await tester.pump();
    await tester.tap(find.byKey(const Key('quickAddSave')));
    await settleReminders(tester);
    expect(find.text('Viết báo cáo'), findsOneWidget, reason: 'việc mới vào đúng list đang xem');
    expect(find.text('Chưa đặt giờ'), findsOneWidget);
  });

  testWidgets('tìm kiếm: gợi ý khi chưa gõ, đếm kết quả, lọc theo list, nhóm Đã xong', (tester) async {
    await pumpApp(tester, size: phone, locale: vi, region: 'VN', seed: (r) async {
      final work = await ListsRepository(r.engine).create('Công việc');
      await r.create(title: 'Họp nhóm', listId: work);
      final done = await r.create(title: 'Họp tổng kết');
      await r.setDone(done, done: true);
    });
    await tester.tap(find.byKey(const Key('openSearch')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('searchTip')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('searchField')), 'hop');
    await settleReminders(tester);
    expect(find.text('2 kết quả cho “hop”'), findsOneWidget);
    expect(find.text('Đã xong'), findsOneWidget);
    await tester.tap(find.byKey(const Key('searchFilter-inbox')));
    await tester.pumpAndSettle();
    expect(find.text('1 kết quả cho “hop”'), findsOneWidget);
    expect(find.text('Họp nhóm'), findsNothing);
  });

  testWidgets('Hôm nay trống: câu mẫu mở Thêm nhanh điền sẵn và đã phân tích', (tester) async {
    await pumpApp(tester, size: phone, locale: vi, region: 'VN');
    expect(find.byKey(const Key('todayEmpty')), findsOneWidget);
    await tester.tap(find.byKey(const Key('todayTryHabit')));
    await tester.pumpAndSettle();
    expect(find.text('Uống vitamin mỗi ngày lúc 20:00'), findsOneWidget);
    expect(find.byKey(const Key('chipRepeat')), findsOneWidget);
  });
}
