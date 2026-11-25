import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_client/data/originals.dart';
import 'package:remindme_client/data/providers.dart';

import 'helpers.dart';

void main() {
  testWidgets('en: đổi tên chuyến đi ở màn chi tiết; xóa chuyến thì đặt chỗ vẫn còn', (tester) async {
    late String itemId;
    final c = await pumpApp(tester, size: const Size(390, 844), seed: (repo) async {
      itemId = await repo.create(title: 'Hotel Lisbon', kind: 'booking', startDate: '2099-01-02');
    });
    final tripId = (await tester.runAsync(() async {
      final trips = c.read(tripsRepositoryProvider);
      final id = await trips.create(title: 'Trip to Lisbon', startsOn: '2099-01-02', endsOn: '2099-01-04');
      await c.read(itemsRepositoryProvider).updateBooking(itemId, tripId: id);
      return id;
    }))!;
    await tester.tap(find.text('Trips').last);
    await tester.pumpAndSettle();
    expect(find.text('Trip to Lisbon'), findsOneWidget);
    await tester.tap(find.byKey(Key('trip-$tripId')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('tripSegment-$itemId')), findsOneWidget);

    await tester.tap(find.byKey(const Key('tripMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename trip'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('tripName')), '  Lisbon with family ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Lisbon with family'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tripMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete trip'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tripDeleteConfirm')));
    await tester.pumpAndSettle();
    final db = c.read(appDatabaseProvider);
    final (items, trips) = (await tester.runAsync(() async => (await db.select(db.items).get(), await db.select(db.trips).get())))!;
    expect(items.single.deletedAt, isNull);
    expect(items.single.tripId, isNull);
    expect(trips.single.deletedAt, isNotNull);
    expect(find.text('Lisbon with family'), findsNothing);
  });

  testWidgets('vi: khoảng trống > 3h giữa 2 chuyến bay → "Thêm hoạt động" tạo việc trong chuyến từ giờ tròn kế tiếp; khách sạn không chiếm giờ', (tester) async {
    final c = await pumpApp(tester, size: const Size(390, 844), locale: const Locale('vi'), region: 'VN');
    final ids = (await tester.runAsync(() async {
      final trips = c.read(tripsRepositoryProvider), items = c.read(itemsRepositoryProvider);
      final trip = await trips.create(title: 'Hà Nội', startsOn: '2099-01-02', endsOn: '2099-01-04');
      const tz = 'Asia/Ho_Chi_Minh';
      final out = await items.create(
          title: 'ZZ 245', kind: 'booking', startsAt: DateTime.utc(2099, 1, 2, 3, 30), tz: tz, endsAt: DateTime.utc(2099, 1, 2, 5, 40), endTz: tz,
          tripId: trip, booking: const {'booking_type': 'flight', 'destination': {'code': 'HAN', 'tz': tz}});
      final hotel = await items.create(
          title: 'Hoa Sen', kind: 'booking', startsAt: DateTime.utc(2099, 1, 2, 7), tz: tz, endsAt: DateTime.utc(2099, 1, 4, 5), endTz: tz,
          tripId: trip, booking: const {'booking_type': 'hotel'});
      final back = await items.create(
          title: 'ZZ 246', kind: 'booking', startsAt: DateTime.utc(2099, 1, 4, 10), tz: tz, tripId: trip, booking: const {'booking_type': 'flight'});
      return (trip, out, hotel, back);
    }))!;
    final (trip, out, hotel, back) = ids;
    await tester.tap(find.text('Chuyến đi').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('trip-$trip')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('tripAddActivity-$out')), findsOneWidget);
    expect(find.byKey(Key('tripAddActivity-$hotel')), findsNothing);
    expect(find.byKey(Key('tripAddActivity-$back')), findsNothing);

    await tester.tap(find.byKey(Key('tripAddActivity-$out')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('tripActivityName')), 'Bảo tàng');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settleReminders(tester);
    final db = c.read(appDatabaseProvider);
    final created = (await tester.runAsync(() async => (await db.select(db.items).get()).where((i) => i.title == 'Bảo tàng').single))!;
    expect((created.kind, created.tripId, created.tz), ('task', trip, 'Asia/Ho_Chi_Minh'));
    expect(DateTime.fromMillisecondsSinceEpoch(created.startsAt!, isUtc: true), DateTime.utc(2099, 1, 2, 6), reason: 'đến 12:40 → 13:00 giờ Hà Nội');
  });

  testWidgets('vi: tab Hành lý: danh sách gợi ý, đánh dấu, thêm món theo nhóm, sửa, bỏ + Hoàn tác (Figma 23)', (tester) async {
    final c = await pumpApp(tester, size: const Size(390, 1100), locale: const Locale('vi'), region: 'VN');
    final trip = (await tester.runAsync(() => c.read(tripsRepositoryProvider).create(title: 'Hà Nội', startsOn: '2099-01-02', endsOn: '2099-01-04')))!;
    await tester.tap(find.text('Chuyến đi').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('trip-$trip')));
    await tester.pumpAndSettle();
    expect(find.text('Hành lý'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tripTab-packing')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('packingEmpty')), findsOneWidget);

    await tester.tap(find.byKey(const Key('packingUseTemplate')));
    await tester.pumpAndSettle();
    expect(find.text('Hành lý · 0/6'), findsOneWidget);
    expect(find.text('Còn 6 món cần chuẩn bị.'), findsOneWidget);
    expect(find.text('Giấy tờ'), findsOneWidget);
    expect(find.text('Thiết bị'), findsOneWidget);

    await tester.tap(find.text('CCCD / Hộ chiếu'));
    await tester.pumpAndSettle();
    expect(find.text('Hành lý · 1/6'), findsOneWidget);
    expect(find.text('Còn 5 món cần chuẩn bị.'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.descendant(of: find.ancestor(of: find.text('CCCD / Hộ chiếu'), matching: find.byType(InkWell)).first, matching: find.byType(Checkbox))).value, isTrue);

    // Thêm món vào nhóm Quần áo.
    await tester.tap(find.byKey(const Key('packingAdd')));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.byKey(const Key('packingSave'))).onPressed, isNull);
    await tester.enterText(find.byKey(const Key('packingText')), ' Áo mưa ');
    await tester.tap(find.byKey(const Key('packingGroup-clothes')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('packingSave')));
    await tester.pumpAndSettle();
    expect(find.text('Quần áo'), findsOneWidget);
    expect(find.text('Áo mưa'), findsOneWidget);
    expect(find.text('Hành lý · 1/7'), findsOneWidget);

    // Sửa tên, rồi bỏ khỏi danh sách và hoàn tác.
    await tester.longPress(find.text('Áo mưa'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('packingText')), 'Áo mưa mỏng');
    await tester.tap(find.byKey(const Key('packingSave')));
    await tester.pumpAndSettle();
    expect(find.text('Áo mưa mỏng'), findsOneWidget);
    await tester.longPress(find.text('Pin dự phòng'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('packingRemove')));
    await tester.pumpAndSettle();
    expect(find.text('Pin dự phòng'), findsNothing);
    expect(find.text('Hành lý · 1/6'), findsOneWidget);
    await tester.tap(find.byKey(const Key('packingUndo')));
    await tester.pumpAndSettle();
    expect(find.text('Pin dự phòng'), findsOneWidget);

    final db = c.read(appDatabaseProvider);
    final row = (await tester.runAsync(() async => (await db.select(db.trips).get()).single))!;
    expect(row.packing, contains('Áo mưa mỏng'));
  });

  testWidgets('en: tab Documents: vé máy bay có tuyến + mã, đặt chỗ nhập ở máy khác thì "Xem chi tiết"; không đặt chỗ thì trống', (tester) async {
    final originals = MemoryOriginalsStore();
    final c = await pumpApp(tester, size: const Size(390, 1100), originals: originals);
    final ids = (await tester.runAsync(() async {
      final trips = c.read(tripsRepositoryProvider), items = c.read(itemsRepositoryProvider);
      final trip = await trips.create(title: 'Hanoi', startsOn: '2099-01-02', endsOn: '2099-01-04');
      const tz = 'Asia/Ho_Chi_Minh';
      final flight = await items.create(
          title: 'ZZ 245', kind: 'booking', startsAt: DateTime.utc(2099, 1, 2, 3, 30), tz: tz, tripId: trip, importId: 'imp-1',
          booking: const {'booking_type': 'flight', 'carrier_code': 'ZZ', 'number': '245', 'confirmation_code': 'ABC123',
            'origin': {'code': 'SGN'}, 'destination': {'code': 'HAN', 'tz': tz}});
      final hotel = await items.create(
          title: 'Lotus Hotel', kind: 'booking', startsAt: DateTime.utc(2099, 1, 2, 7), tz: tz, endsAt: DateTime.utc(2099, 1, 4, 5), endTz: tz,
          tripId: trip, importId: 'imp-2', booking: const {'booking_type': 'hotel', 'confirmation_code': 'HT2048'});
      await originals.save('imp-1', 'itinerary.pkpass', Uint8List(3));
      final empty = await trips.create(title: 'Empty', startsOn: '2099-02-02');
      return (trip, flight, hotel, empty);
    }))!;
    final (trip, flight, hotel, empty) = ids;
    await tester.tap(find.text('Trips').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('trip-$trip')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tripTab-docs')));
    await tester.pumpAndSettle();
    expect(find.text('Documents · 2'), findsOneWidget);
    expect(find.text('Flight ZZ245'), findsOneWidget);
    expect(find.textContaining('SGN → HAN'), findsOneWidget);
    expect(find.text('ABC123'), findsOneWidget);
    expect(find.text('HT2048'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('docsSummary'))).data, '2 bookings · 1 original file');
    expect(tester.widget<Text>(find.byKey(Key('docFile-$hotel'))).data, 'Original file not on this device');
    await tester.tap(find.byKey(Key('docOpen-$flight')));
    await tester.pumpAndSettle();
    expect(originals.opened, ['imp-1']);
    await tester.ensureVisible(find.byKey(Key('docDetails-$hotel')));
    await tester.tap(find.byKey(Key('docDetails-$hotel')));
    await tester.pumpAndSettle();
    expect(find.text('Lotus Hotel'), findsWidgets, reason: 'mở chi tiết đặt chỗ');

    GoRouter.of(tester.element(find.byType(Scaffold).last)).go('/trips/$empty?tab=docs');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('docsEmpty')), findsOneWidget);
    expect(find.byKey(const Key('docsAdd')), findsOneWidget);
  });
}
