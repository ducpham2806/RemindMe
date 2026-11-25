import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
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
}
