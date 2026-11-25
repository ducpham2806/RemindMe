import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_client/data/providers.dart';
import 'package:remindme_data/remindme_data.dart';
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

Future<void> openImport(WidgetTester tester, {required String me, required String row}) async {
  await tester.tap(find.text(me).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(row));
  await tester.pumpAndSettle();
}

void main() {
  // Giải mã đồng bộ (không Isolate.run) để chạy trong fake-async của widget test.
  final syncDecoder = importDecoderProvider.overrideWithValue((req) async => decodeImport(req));

  testWidgets('csv tiếng Việt: xem lại, bỏ chọn, đổi tên, thêm → việc + hàng imports trong DB', (tester) async {
    final c = await pumpApp(tester, size: phone, locale: const Locale('vi'), region: 'VN', overrides: [
      syncDecoder,
      filePickerProvider.overrideWithValue(picker([fixture('synthetic-csv-todo-0001', 'input.csv')])),
    ]);
    await openImport(tester, me: 'Tôi', row: 'Nhập từ tệp');
    expect(find.text('Chọn tệp'), findsOneWidget);
    await tester.tap(find.byKey(const Key('importPick')));
    await tester.pumpAndSettle();

    expect(find.text('Xem lại'), findsOneWidget);
    expect(find.text('Tìm thấy 4 mục'), findsOneWidget);
    expect(find.text('Đã xong'), findsOneWidget, reason: 'việc đã xong trong tệp có nhãn và mặc định không chọn');
    expect(find.text('Thêm 3 mục'), findsOneWidget);

    await tester.tap(find.byKey(const Key('importCheck-1')));
    await tester.pump();
    expect(find.text('Thêm 2 mục'), findsOneWidget);

    await tester.tap(find.text('Nộp báo cáo quý 4'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('importName')), 'Nộp báo cáo Q4');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Nộp báo cáo Q4'), findsOneWidget);

    await tester.tap(find.byKey(const Key('importAdd')));
    await settleReminders(tester);
    expect(find.text('Đã thêm 2 mục'), findsOneWidget);
    expect(find.text('Nhập từ tệp'), findsOneWidget, reason: 'quay về Tôi');

    final db = c.read(appDatabaseProvider);
    final (items, imports) = (await tester.runAsync(() async => (await db.select(db.items).get(), await db.select(db.imports).get())))!;
    expect(items.map((i) => i.title).toSet(), {'Nộp báo cáo Q4', 'Mua quà sinh nhật mẹ'});
    final report = items.firstWhere((i) => i.title == 'Nộp báo cáo Q4');
    expect((report.startsAt, report.tz, report.priority, report.notes, report.importId, report.source),
        (DateTime.utc(2026, 12, 15, 2).millisecondsSinceEpoch, 'Asia/Ho_Chi_Minh', 3, 'Gửi chị Lan duyệt trước', imports.single.id, 'xlsx'));
    expect((imports.single.kind, imports.single.docLanguage, imports.single.docType), ('xlsx', 'vi', 'todo_list'));
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
    expect(find.byIcon(Icons.flight), findsOneWidget);
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
    expect(find.textContaining('Đọc từ chữ trên tài liệu, hãy kiểm tra lại'), findsOneWidget);
    expect(find.byIcon(Icons.flight), findsOneWidget);
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
    expect(find.byTooltip('Read automatically, please check'), findsNWidgets(3), reason: 'bắt đầu, kết thúc, số chuyến 0,6; mã, ghế 0,8 thì không');
    expect(find.byKey(const Key('importField-location_text')), findsNothing, reason: 'chuyến bay: địa điểm là sân bay đi');

    await tester.enterText(find.byKey(const Key('importField-seat')), '15A');
    await tester.enterText(find.byKey(const Key('importField-number')), 'zz246');
    for (final slot in ['starts_at', 'ends_at']) {
      await tester.tap(find.byKey(Key('importEdit-$slot-time')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }
    expect(find.byTooltip('Read automatically, please check'), findsNothing);
    await tester.tap(find.byKey(const Key('importEditSave')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('importWarn-0')), findsNothing, reason: 'người dùng đã xác nhận mọi trường cần kiểm tra');
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
    final c = await pumpApp(tester, size: phone, locale: const Locale('vi'), region: 'VN', overrides: [
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

    await tester.tap(find.text('Chuyến đi').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('1 đặt chỗ'), findsOneWidget);
    await tester.tap(find.byKey(Key('trip-${trips.single.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('tripSegment-${items.single.id}')), findsOneWidget);
    expect(find.text('14:00 → 12:00'), findsOneWidget, reason: 'nhận phòng → trả phòng theo giờ nơi ở');
    expect(find.byIcon(Icons.hotel), findsOneWidget);

    await openImport(tester, me: 'Tôi', row: 'Nhập từ tệp');
    await tester.tap(find.byKey(const Key('importPick')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Đã có, sẽ bỏ qua'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byKey(const Key('importCheck-0'))).value, isFalse);
    expect(tester.widget<DropdownButton<String>>(find.byKey(const Key('importTrip-0'))).value, trips.single.id);
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
              'status': {'plan': 'free', 'limits': {'max_active_trips': 1}, 'usage': {'max_active_trips': 1}, 'features': {}},
            }),
          ));
    });
    await openImport(tester, me: 'Me', row: 'Import from file');
    await tester.tap(find.byKey(const Key('importPick')));
    await tester.pumpAndSettle();
    expect(tester.widget<DropdownButton<String>>(find.byKey(const Key('importTrip-0'))).value, 'none');
    expect(find.text('Your plan includes 1 active trip. Delete a trip or upgrade to add another.'), findsOneWidget);
    final items = tester.widget<DropdownButton<String>>(find.byKey(const Key('importTrip-0'))).items!;
    expect(items.firstWhere((i) => i.value == 'new').enabled, isFalse);
    await tester.tap(find.byKey(const Key('importAdd')));
    await settleReminders(tester);
    final (saved, trips) = (await tester.runAsync(() async => (await db.select(db.items).get(), await db.select(db.trips).get())))!;
    expect(saved.single.tripId, isNull);
    expect(trips.map((t) => t.title), ['Lisbon']);
  });

  testWidgets('bảng mơ hồ 03/04 khi không biết vùng: hỏi thứ tự ngày, chọn lại thì đọc lại tệp', (tester) async {
    await pumpApp(tester, size: phone, region: null, overrides: [
      syncDecoder,
      filePickerProvider.overrideWithValue(picker([(name: 'rent.csv', bytes: Uint8List.fromList(utf8.encode('Task,Due\nPay rent,03/04/2027\n')))])),
    ]);
    await openImport(tester, me: 'Me', row: 'Import from file');
    await tester.tap(find.byKey(const Key('importPick')));
    await tester.pumpAndSettle();
    expect(find.text('How are dates written in this file?'), findsOneWidget);
    expect(tester.widget<ChoiceChip>(find.byKey(const Key('importOrder-dmy'))).selected, isTrue);
    final before = tester.widget<Text>(find.descendant(of: find.byKey(const Key('importItem-0')), matching: find.byType(Text)).at(1)).data;
    await tester.tap(find.byKey(const Key('importOrder-mdy')));
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(find.byKey(const Key('importOrder-mdy'))).selected, isTrue);
    final after = tester.widget<Text>(find.descendant(of: find.byKey(const Key('importItem-0')), matching: find.byType(Text)).at(1)).data;
    expect(after, isNot(before));
    expect(after, contains('Mar'));
  });

  testWidgets('pseudo-locale + chữ lớn ở 320dp: màn Xem lại không vỡ bố cục', (tester) async {
    await pumpApp(tester, size: const Size(320, 640), locale: const Locale('en', 'XA'), textScale: 1.3, overrides: [
      syncDecoder,
      filePickerProvider.overrideWithValue(picker([fixture('synthetic-email-hotel-0001', 'input.eml')])),
    ]);
    await tester.tap(find.byKey(const Key('nav-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.upload_file_outlined));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('importPick')));
    await tester.tap(find.byKey(const Key('importPick')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.hotel), findsOneWidget);
    expect(find.byIcon(Icons.attach_file), findsOneWidget);
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
}
