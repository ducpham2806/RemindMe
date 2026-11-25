import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_client/core/theme/app_icons.dart';
import 'package:remindme_client/data/originals.dart';
import 'package:remindme_client/data/providers.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:remindme_parsers/remindme_parsers.dart' show TableField;
import 'package:remindme_client/features/import/import_decode.dart';
import 'package:remindme_client/features/import/import_providers.dart';

import 'helpers.dart';

const phone = Size(390, 844);
const docs = '../../packages/parsers/fixtures/docs';

/// Bộ chọn tệp giả: trả lần lượt các tệp trong [files].
Future<PickedFile?> Function() picker(List<PickedFile> files) {
  var i = 0;
  return () async => i < files.length ? files[i++] : null;
}

PickedFile fixture(String dir, String name) => (name: name, bytes: File('$docs/$dir/$name').readAsBytesSync());

/// Icon SVG của app (AppIcon) theo loại.
Finder appIcon(AppIcons icon) => find.byWidgetPredicate((w) => w is AppIcon && w.icon == icon);

/// Lựa chọn đang hiện trên thẻ gộp chuyến thứ [k].
String? tripChoice(WidgetTester tester, int k) => tester.widget<Text>(find.byKey(Key('importTripChoice-$k'))).data;

Future<void> openImport(WidgetTester tester, {required String me, required String row}) async {
  await tester.tap(find.text(me).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(row));
  await tester.pumpAndSettle();
}

void main() {
  // Giải mã đồng bộ (không Isolate.run) để chạy trong fake-async của widget test.
  final syncDecoder = importDecoderProvider.overrideWithValue((req) async => decodeImport(req));

  testWidgets('csv tiếng Việt: màn Ghép cột (Figma 18), đổi cột, nhập → việc + imports; lần sau tự dùng cách ghép đã nhớ', (tester) async {
    final csv = fixture('synthetic-csv-todo-0001', 'input.csv');
    final c = await pumpApp(tester, size: const Size(390, 1400), locale: const Locale('vi'), region: 'VN', overrides: [
      syncDecoder,
      filePickerProvider.overrideWithValue(picker([csv, csv])),
    ]);
    await openImport(tester, me: 'Tôi', row: 'Nhập từ tệp');
    expect(find.text('Chọn tệp'), findsOneWidget);
    await tester.tap(find.byKey(const Key('importPick')));
    await tester.pumpAndSettle();

    expect(find.text('Ghép cột bảng tính'), findsOneWidget);
    expect(find.text('4 dòng'), findsOneWidget);
    expect(find.text('Ngày/tháng/năm'), findsOneWidget);
    expect(find.text('Công việc'), findsOneWidget, reason: 'tên cột trong tệp');
    expect(tester.widget<DropdownButton<TableField?>>(find.byKey(const Key('importColumn-1'))).value, TableField.title);
    expect(tester.widget<DropdownButton<TableField?>>(find.byKey(const Key('importColumn-0'))).value, isNull, reason: 'cột STT bị bỏ qua');
    expect(tester.widget<Text>(find.byKey(const Key('importMapValid'))).data, '4 hợp lệ');
    expect(find.text('Nhập 3 việc'), findsOneWidget, reason: 'việc đã xong trong tệp mặc định không nhập');
    expect(find.text('15/12'), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);

    // Cột Ghi chú → Bỏ qua.
    await tester.tap(find.byKey(const Key('importColumn-6')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bỏ qua').last);
    await tester.pumpAndSettle();
    expect(tester.widget<DropdownButton<TableField?>>(find.byKey(const Key('importColumn-6'))).value, isNull);
    // Chọn "Tên việc" cho cột Ghi chú rồi đổi lại: tên việc chuyển cột, cột cũ thành Bỏ qua.
    await tester.tap(find.byKey(const Key('importColumn-6')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tên việc').last);
    await tester.pumpAndSettle();
    expect(tester.widget<DropdownButton<TableField?>>(find.byKey(const Key('importColumn-1'))).value, isNull);
    expect(tester.widget<Text>(find.byKey(const Key('importMapValid'))).data, '2 hợp lệ', reason: 'chỉ 2 dòng có ghi chú');
    await tester.tap(find.byKey(const Key('importColumn-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tên việc').last);
    await tester.pumpAndSettle();
    expect(tester.widget<DropdownButton<TableField?>>(find.byKey(const Key('importColumn-6'))).value, isNull);

    expect(tester.widget<Checkbox>(find.byKey(const Key('importRemember'))).value, isTrue);
    await tester.tap(find.byKey(const Key('importAdd')));
    await settleReminders(tester);
    expect(find.text('Đã thêm 3 mục'), findsOneWidget);
    await tester.tap(find.byKey(const Key('importDone')));
    await tester.pumpAndSettle();
    expect(find.text('Nhập từ tệp'), findsOneWidget, reason: 'quay về Tôi');

    final db = c.read(appDatabaseProvider);
    final (items, imports) = (await tester.runAsync(() async => (await db.select(db.items).get(), await db.select(db.imports).get())))!;
    expect(items.map((i) => i.title).toSet(), {'Nộp báo cáo quý 4', 'Gia hạn bảo hiểm xe máy', 'Mua quà sinh nhật mẹ'});
    final report = items.firstWhere((i) => i.title == 'Nộp báo cáo quý 4');
    expect((report.startsAt, report.tz, report.priority, report.notes, report.importId, report.source),
        (DateTime.utc(2026, 12, 15, 2).millisecondsSinceEpoch, 'Asia/Ho_Chi_Minh', 3, null, imports.single.id, 'xlsx'));
    expect((imports.single.kind, imports.single.docLanguage, imports.single.docType), ('xlsx', 'vi', 'todo_list'));

    // Lần 2 cùng dòng tiêu đề: tự dùng cách ghép đã nhớ (Ghi chú bỏ qua).
    await tester.tap(find.text('Nhập từ tệp'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('importPick')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('importRemembered')), findsOneWidget);
    expect(tester.widget<DropdownButton<TableField?>>(find.byKey(const Key('importColumn-6'))).value, isNull);

    // Tắt "Dòng 1 là tiêu đề": dòng tiêu đề thành 1 dòng dữ liệu, cột hiện theo chữ cái.
    await tester.tap(find.byKey(const Key('importHeader')));
    await tester.pumpAndSettle();
    expect(find.text('Cột B'), findsOneWidget);
    expect(find.text('5 dòng'), findsOneWidget);
    expect(find.byKey(const Key('importRemember')), findsNothing, reason: 'không có tiêu đề thì không nhớ được');
  });

  testWidgets('en: PDF chưa hỗ trợ → chọn tệp khác; email vé máy bay có tên mặc định và mã đặt chỗ', (tester) async {
    final c = await pumpApp(tester, size: phone, overrides: [
      syncDecoder,
      filePickerProvider.overrideWithValue(picker([
        (name: 'scan.pdf', bytes: Uint8List.fromList(utf8.encode('%PDF-1.4'))),
        fixture('synthetic-jsonld-flight-0001', 'input.eml'),
      ])),
    ]);
    await openImport(tester, me: 'Me', row: 'Import from file');
    await tester.tap(find.byKey(const Key('importPick')));
    await tester.pumpAndSettle();
    expect(find.textContaining('can’t be read yet'), findsOneWidget);
    expect(find.text('Choose another file'), findsOneWidget);
    await tester.tap(find.byKey(const Key('importPick')));
    await tester.pumpAndSettle();

    expect(find.text('ZZ 245 · SGN → HAN'), findsOneWidget);
    expect(find.textContaining('Booking code: XQ7K2M'), findsOneWidget);
    expect(appIcon(AppIcons.plane), findsOneWidget, reason: 'tuyến SGN ✈ HAN');
    expect(find.byKey(const Key('importNeedsCheck')), findsNothing, reason: 'JSON-LD: không có trường phải kiểm tra');
    await tester.tap(find.byKey(const Key('importAdd')));
    await settleReminders(tester);

    final db = c.read(appDatabaseProvider);
    final (items, reminders) = (await tester.runAsync(() async => (await db.select(db.items).get(), await db.select(db.reminders).get())))!;
    expect((items.single.kind, items.single.title, items.single.notes, items.single.source),
        ('booking', 'ZZ 245 · SGN → HAN', 'Booking code: XQ7K2M\nSeat: 14C', 'email'));
    expect(reminders.map((r) => r.offsetMinutes).toSet(), {-1440, -180, -120}, reason: 'bay nội địa SGN → HAN: 24h, 3h, 2h trước (reminder-engine §5)');
  });

  testWidgets('vi: vé dạng chữ đọc bằng luật T2 → gợi ý kiểm tra lại, cảnh báo ngày đã qua', (tester) async {
    final past = File('$docs/synthetic-flight-0001/input.txt').readAsStringSync().replaceAll('21/12/2026', '21/10/2026');
    await pumpApp(tester, size: phone, locale: const Locale('vi'), region: 'VN', overrides: [
      syncDecoder,
      filePickerProvider.overrideWithValue(picker([(name: 've.txt', bytes: Uint8List.fromList(utf8.encode(past)))])),
    ]);
    await openImport(tester, me: 'Tôi', row: 'Nhập từ tệp');
    await tester.tap(find.byKey(const Key('importPick')));
    await tester.pumpAndSettle();
    expect(find.text('ZZ 245 · SGN → HAN'), findsOneWidget);
    expect(find.textContaining('Mã đặt chỗ: XQ7K2M'), findsOneWidget);
    expect(find.textContaining('Ngày này đã qua'), findsOneWidget);
    expect(find.text('Có 1 mục cần bạn kiểm tra'), findsOneWidget);
    expect(find.text('Cần kiểm tra: Bắt đầu, Kết thúc, Số hiệu chuyến bay'), findsOneWidget);
    expect(appIcon(AppIcons.plane), findsOneWidget);

    // Nút chính chưa lưu: mở form của mục cần kiểm tra; "Đúng, giữ nguyên" xác nhận mọi trường tô vàng (Figma 15 → 16 → 15b).
    expect(find.text('Kiểm tra để tiếp tục'), findsOneWidget);
    await tester.tap(find.byKey(const Key('importAdd')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bắt đầu, Kết thúc, Số hiệu chuyến bay'), findsOneWidget);
    await tester.tap(find.byKey(const Key('importConfirmAll')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('importConfirmCard')), findsNothing);
    await tester.tap(find.byKey(const Key('importEditSave')));
    await tester.pumpAndSettle();
    expect(find.text('Đã xác nhận đủ thông tin'), findsOneWidget);
    expect(find.text('Đã kiểm tra: Bắt đầu, Kết thúc, Số hiệu chuyến bay'), findsOneWidget);
    expect(find.text('Thêm 1 mục'), findsOneWidget);
  });

  testWidgets('en: sửa từng trường ở form (E5.1): trường độ tin cậy thấp có dấu, xác nhận giờ thì hết dấu, giá trị mới vào DB', (tester) async {
    final c = await pumpApp(tester, size: phone, overrides: [
      syncDecoder,
      filePickerProvider.overrideWithValue(picker([fixture('synthetic-flight-0001', 'input.txt')])),
    ]);
    await openImport(tester, me: 'Me', row: 'Import from file');
    await tester.tap(find.byKey(const Key('importPick')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('importWarn-0')), findsOneWidget);

    await tester.tap(find.text('ZZ 245 · SGN → HAN'));
    await tester.pumpAndSettle();
    expect(find.text('Edit item'), findsOneWidget);
    expect(find.textContaining('read from the document text: Starts, Ends, Flight number.'), findsOneWidget,
        reason: 'bắt đầu, kết thúc, số chuyến 0,6; mã, ghế 0,8 thì không');
    expect(find.byKey(const Key('importField-location_text')), findsNothing, reason: 'chuyến bay: địa điểm là sân bay đi');
    final form = find.descendant(of: find.byKey(const Key('importEditForm')), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.byKey(const Key('importField-seat')), 100, scrollable: form);

    await tester.enterText(find.byKey(const Key('importField-seat')), '15A');
    await tester.enterText(find.byKey(const Key('importField-number')), 'zz246');
    for (final slot in ['starts_at', 'ends_at']) {
      await tester.scrollUntilVisible(find.byKey(Key('importEdit-$slot-time')), -100, scrollable: form);
      await tester.tap(find.byKey(Key('importEdit-$slot-time')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('importConfirmCard')), findsNothing);
    await tester.tap(find.byKey(const Key('importEditSave')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('importWarn-0')), findsNothing, reason: 'người dùng đã xác nhận mọi trường cần kiểm tra');
    expect(find.byKey(const Key('importChecked-0')), findsOneWidget);
    expect(find.text('ZZ 245 · SGN → HAN'), findsOneWidget);
    expect(find.textContaining('Read from the text'), findsNothing);

    await tester.tap(find.byKey(const Key('importAdd')));
    await settleReminders(tester);
    final db = c.read(appDatabaseProvider);
    final items = (await tester.runAsync(() => db.select(db.items).get()))!;
    expect((items.single.notes, items.single.tz, items.single.startsAt),
        ('Booking code: XQ7K2M\nSeat: 15A', 'Asia/Ho_Chi_Minh', DateTime.utc(2026, 12, 21, 3, 30).millisecondsSinceEpoch));
    expect(items.single.title, 'ZZ 245 · SGN → HAN', reason: 'tên đã hiện giữ nguyên dù sửa số chuyến');
  });

  testWidgets('vi: đặt phòng → chuyến đi mới, tab Chuyến đi + timeline; nhập lại cùng email: "Đã có", gộp vào chuyến có sẵn', (tester) async {
    final hotel = fixture('synthetic-email-hotel-0001', 'input.eml');
    final originals = MemoryOriginalsStore();
    final c = await pumpApp(tester, size: phone, locale: const Locale('vi'), region: 'VN', originals: originals, overrides: [
      syncDecoder,
      filePickerProvider.overrideWithValue(picker([hotel, hotel])),
    ]);
    await openImport(tester, me: 'Tôi', row: 'Nhập từ tệp');
    await tester.tap(find.byKey(const Key('importPick')));
    await tester.pumpAndSettle();
    expect(find.text('Gộp vào chuyến đi'), findsOneWidget);
    expect(find.text('Chuyến mới: Chuyến đi ngày 21 thg 12'), findsOneWidget, reason: 'khách sạn: mặc định gộp, chưa biết thành phố');
    await tester.tap(find.byKey(const Key('importAdd')));
    await settleReminders(tester);

    final db = c.read(appDatabaseProvider);
    final (items, trips, reminders) =
        (await tester.runAsync(() async => (await db.select(db.items).get(), await db.select(db.trips).get(), await db.select(db.reminders).get())))!;
    expect((items.single.kind, items.single.tripId, trips.single.title), ('booking', trips.single.id, 'Chuyến đi ngày 21 thg 12'));
    expect(reminders.map((r) => r.triggerKind).toSet(), {'absolute'}, reason: 'khách sạn: 18:00 hôm trước + 1h trước trả phòng');
    expect(find.byKey(const Key('importOpenTrip')), findsOneWidget, reason: 'màn Đã lưu có nút mở chuyến vừa tạo');
    await tester.tap(find.byKey(const Key('importDone')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chuyến đi').last);
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byKey(Key('trip-${trips.single.id}')), matching: find.textContaining(items.single.title!)), findsOneWidget);
    await tester.tap(find.byKey(Key('trip-${trips.single.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('tripSegment-${items.single.id}')), findsOneWidget);
    expect(find.text('14:00 · Nhận phòng'), findsOneWidget, reason: 'nhận phòng và trả phòng theo giờ nơi ở');
    expect(find.text('12:00 · Trả phòng'), findsOneWidget);

    // Bản gốc giữ trên máy, tab Tài liệu (Figma 22) hiện tên tệp và mở bằng app của hệ điều hành.
    final importId = items.single.importId!;
    expect(originals.files[importId]?.$1, 'input.eml');
    expect(find.text('Tài liệu · 1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tripTab-docs')));
    await tester.pumpAndSettle();
    expect(find.text('Xác nhận đặt phòng'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(Key('docFile-${items.single.id}'))).data, 'input.eml');
    expect(tester.widget<Text>(find.byKey(const Key('docsSummary'))).data, '1 đặt chỗ · 1 tệp gốc');
    await tester.tap(find.byKey(Key('docOpen-${items.single.id}')));
    await tester.pumpAndSettle();
    expect(originals.opened, [importId]);

    await openImport(tester, me: 'Tôi', row: 'Nhập từ tệp');
    await tester.tap(find.byKey(const Key('importPick')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Đã có, sẽ bỏ qua'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byKey(const Key('importCheck-0'))).value, isFalse);
    expect(tripChoice(tester, 0), 'Chuyến đi ngày 21 thg 12', reason: 'gộp vào chuyến có sẵn');
  });

  testWidgets('en: hết lượt chuyến đi theo cache quota_status → không gộp, "chuyến mới" bị khóa, có dòng giải thích', (tester) async {
    final c = await pumpApp(tester, size: phone, overrides: [
      syncDecoder,
      filePickerProvider.overrideWithValue(picker([fixture('synthetic-email-hotel-0001', 'input.eml')])),
    ]);
    final db = c.read(appDatabaseProvider);
    await tester.runAsync(() async {
      await c.read(tripsRepositoryProvider).create(title: 'Lisbon', startsOn: '2099-01-01');
      await db.into(db.syncState).insert(SyncStateCompanion.insert(
            key: 'quota_status',
            value: jsonEncode({
              'fetched_at': '2026-11-25T00:00:00Z',
              'status': {
                'plan': 'free',
                'limits': {'max_active_trips': 1, 'max_active_appointments': 10},
                'usage': {'max_active_trips': 1, 'max_active_appointments': 3},
                'features': {},
              },
            }),
          ));
    });
    await openImport(tester, me: 'Me', row: 'Import from file');
    await tester.tap(find.byKey(const Key('importPick')));
    await tester.pumpAndSettle();
    expect(tripChoice(tester, 0), 'Don’t add to a trip');
    expect(find.text('Your plan includes 1 active trip. Delete a trip or upgrade to add another.'), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('importQuota')), 100, scrollable: find.byType(Scrollable).first);
    expect(find.text('Your plan has room for 7 more appointments'), findsOneWidget, reason: 'số lấy từ cache quota_status');
    expect(find.text('1 selected · 6 left after saving.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('importTrip-0')));
    await tester.pumpAndSettle();
    expect(tester.widget<ListTile>(find.byKey(const Key('importTripOption-0-new'))).enabled, isFalse);
    await tester.tap(find.byKey(const Key('importTripOption-0-none')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('importAdd')));
    await settleReminders(tester);
    final (saved, trips) = (await tester.runAsync(() async => (await db.select(db.items).get(), await db.select(db.trips).get())))!;
    expect(saved.single.tripId, isNull);
    expect(trips.map((t) => t.title), ['Lisbon']);
  });

  testWidgets('bảng mơ hồ 03/04 khi không biết vùng: chip báo cần chọn thứ tự ngày, chọn lại thì đọc lại tệp', (tester) async {
    await pumpApp(tester, size: phone, region: null, overrides: [
      syncDecoder,
      filePickerProvider.overrideWithValue(picker([(name: 'rent.csv', bytes: Uint8List.fromList(utf8.encode('Task,Due\nPay rent,03/04/2027\n')))])),
    ]);
    await openImport(tester, me: 'Me', row: 'Import from file');
    await tester.tap(find.byKey(const Key('importPick')));
    await tester.pumpAndSettle();
    expect(find.text('Choose date order'), findsOneWidget);
    expect(find.text('4/3'), findsOneWidget, reason: 'đọc tạm theo ngày trước: 3 tháng 4, hiện kiểu en M/d');
    await tester.tap(find.byKey(const Key('importDateOrder')));
    await tester.pumpAndSettle();
    expect(find.text('How are dates written in this file?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('importOrder-mdy')));
    await tester.pumpAndSettle();
    expect(find.text('Month/day/year'), findsOneWidget);
    expect(find.text('Choose date order'), findsNothing);
    expect(find.text('3/4'), findsOneWidget, reason: 'đọc lại: tháng 3 ngày 4');
    expect(find.text('4/3'), findsNothing);
  });

  testWidgets('pseudo-locale + chữ lớn ở 320dp: màn Xem lại không vỡ bố cục', (tester) async {
    await pumpApp(tester, size: const Size(320, 640), locale: const Locale('en', 'XA'), textScale: 1.3, overrides: [
      syncDecoder,
      filePickerProvider.overrideWithValue(picker([fixture('synthetic-email-hotel-0001', 'input.eml')])),
    ]);
    await tester.tap(find.byKey(const Key('nav-3')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('me-file')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('me-file')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('importPick')), 100, scrollable: find.byType(Scrollable).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('importPick')));
    await tester.pumpAndSettle();
    expect(appIcon(AppIcons.hotel), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Form sửa (E5.1): khách sạn có nhận/trả phòng, địa điểm, mã.
    // Thẻ cao hơn vùng nhìn thấy ở cỡ này: cuộn tới rồi chạm phần đầu thẻ (tên).
    await tester.ensureVisible(find.byKey(const Key('importItem-0')));
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getTopLeft(find.byKey(const Key('importItem-0'))) + const Offset(120, 16));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('importEdit-check_in-date')), findsOneWidget);
    expect(find.byKey(const Key('importEdit-check_out-time')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('màn nhập: chụp/thư viện "Sắp có"; tệp không đọc được → màn 25 (không tạo gì), chọn tệp khác', (tester) async {
    await pumpApp(tester, size: const Size(390, 1000), locale: const Locale('vi'), region: 'VN', overrides: [
      syncDecoder,
      filePickerProvider.overrideWithValue(picker([(name: 'scan.pdf', bytes: Uint8List.fromList(utf8.encode('%PDF-1.4')))])),
    ]);
    await openImport(tester, me: 'Tôi', row: 'Nhập từ tệp');
    expect(find.text('Bớt nhập tay. Nhớ đủ mọi chặng.'), findsOneWidget);
    expect(find.textContaining('Sắp có · Vé, giấy hẹn'), findsOneWidget);
    await tester.tap(find.byKey(const Key('importPick')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('importUnread')), findsOneWidget);
    expect(find.text('scan.pdf'), findsOneWidget);
    expect(find.text('Chưa tạo mục nào · Không tính lượt nhập'), findsOneWidget);
    expect(find.byKey(const Key('importPick')), findsOneWidget, reason: 'chọn tệp khác');
  });

  testWidgets('đang đọc: hiện tên tệp, Hủy thì bỏ kết quả và về màn chọn nguồn', (tester) async {
    final gate = Completer<ImportPreview>();
    await pumpApp(tester, size: const Size(390, 1000), locale: const Locale('vi'), region: 'VN', overrides: [
      importDecoderProvider.overrideWithValue((req) => gate.future),
      filePickerProvider.overrideWithValue(picker([fixture('synthetic-csv-todo-0001', 'input.csv')])),
    ]);
    await openImport(tester, me: 'Tôi', row: 'Nhập từ tệp');
    await tester.tap(find.byKey(const Key('importPick')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('importReading')), findsOneWidget);
    expect(find.text('input.csv'), findsOneWidget);
    await tester.tap(find.byKey(const Key('importCancel')));
    await tester.pump();
    gate.completeError(StateError('giải mã xong sau khi đã hủy'));
    await tester.pumpAndSettle();
    expect(find.text('Bớt nhập tay. Nhớ đủ mọi chặng.'), findsOneWidget);
  });
}
