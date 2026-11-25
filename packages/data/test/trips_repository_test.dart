import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:test/test.dart';

import 'fake_server.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late ImportsRepository imports;
  late TripsRepository trips;
  final now = DateTime.utc(2026, 11, 24, 3);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    final engine = SyncEngine(db: db, api: FakeServer().apiFor('p'), clock: HlcClock('p'), deviceId: 'p');
    trips = TripsRepository(engine, now: () => now);
    imports = ImportsRepository(engine, ItemsRepository(engine, now: () => now), ListsRepository(engine, now: () => now), trips: trips, now: () => now);
  });
  tearDown(() => db.close());

  ImportedItem flight(String number, DateTime at, {String code = 'XQ7K2M', int? trip, String? update}) => ImportedItem(
        title: 'ZZ $number',
        kind: 'booking',
        startsAt: at,
        tz: 'Asia/Ho_Chi_Minh',
        reminderOffsets: const [-1440, -180, -120],
        tripIndex: trip,
        updateItemId: update,
        booking: {
          'booking_type': 'flight',
          'confirmation_code': code,
          'carrier_code': 'ZZ',
          'number': number,
          'origin': {'code': 'SGN', 'tz': 'Asia/Ho_Chi_Minh'},
          'destination': {'code': 'HAN', 'tz': 'Asia/Ho_Chi_Minh'},
          'extraction_meta': {'tier': 't2', 'field_confidence': {'starts_at': 0.6}},
        },
      );

  test('đặt chỗ: item booking + booking_details; chuyến mới gom 2 mục; nhắc tuyệt đối', () async {
    final r = await imports.commit(
      const ImportRecord(kind: 'email', docType: 'flight', tierUsed: 't1t2'),
      [
        flight('245', DateTime.utc(2026, 12, 21, 3, 30), trip: 0),
        ImportedItem(
          title: 'Hoa Sen',
          kind: 'booking',
          startsAt: DateTime.utc(2026, 12, 21, 7),
          tz: 'Asia/Ho_Chi_Minh',
          endsAt: DateTime.utc(2026, 12, 23, 5),
          endTz: 'Asia/Ho_Chi_Minh',
          absoluteReminders: [DateTime.utc(2026, 12, 20, 11), DateTime.utc(2026, 12, 23, 4)],
          tripIndex: 0,
          booking: const {'booking_type': 'hotel', 'confirmation_code': 'HS-1'},
        ),
      ],
      deviceTz: 'Asia/Ho_Chi_Minh',
      trips: const [TripDraft(title: 'Hà Nội', destination: 'Hanoi', startsOn: '2026-12-21', endsOn: '2026-12-23')],
    );
    final trip = (await trips.trips()).single;
    expect((trip.id, trip.title, trip.destination, trip.startsOn, trip.endsOn, trip.itemCount), (r.tripIds.single, 'Hà Nội', 'Hanoi', '2026-12-21', '2026-12-23', 2));
    final items = await db.select(db.items).get();
    expect(items.map((i) => (i.kind, i.tripId)).toSet(), {('booking', trip.id)});
    final b = await (db.select(db.bookingDetails)..where((t) => t.itemId.equals(r.itemIds.first))).getSingle();
    expect((b.bookingType, b.confirmationCode, b.number, jsonDecode(b.origin!)['code'], b.passengers), ('flight', 'XQ7K2M', '245', 'SGN', null));
    expect(jsonDecode(b.extractionMeta!)['tier'], 't2');
    final rem = await db.select(db.reminders).get();
    expect(rem.where((x) => x.triggerKind == 'absolute').map((x) => x.at).toSet(),
        {DateTime.utc(2026, 12, 20, 11).millisecondsSinceEpoch, DateTime.utc(2026, 12, 23, 4).millisecondsSinceEpoch});
    expect(rem.where((x) => x.triggerKind == 'offset').map((x) => x.offsetMinutes).toSet(), {-1440, -180, -120});

    final segs = await trips.segments(trip.id);
    expect(segs.map((s) => (s.item.title, s.bookingType)), [('ZZ 245', 'flight'), ('Hoa Sen', 'hotel')]);
    expect(segs.first.origin?['code'], 'SGN');
  });

  test('tìm đặt chỗ theo mã; vé đổi giờ cập nhật item cũ, gộp vào chuyến có sẵn và nới ngày; xóa chuyến giữ đặt chỗ', () async {
    final first = await imports.commit(const ImportRecord(kind: 'email'), [flight('245', DateTime.utc(2026, 12, 21, 3, 30), trip: 0)],
        deviceTz: 'Asia/Ho_Chi_Minh', trips: const [TripDraft(title: 'HN', startsOn: '2026-12-21', endsOn: '2026-12-21')]);
    final found = await trips.bookingsWithCodes(['xq7k2m', 'NOPE']);
    expect((found.single.itemId, found.single.number, found.single.originCode, found.single.startsAt, found.single.tripId),
        (first.itemIds.single, '245', 'SGN', DateTime.utc(2026, 12, 21, 3, 30), first.tripIds.single));

    final second = await imports.commit(
      const ImportRecord(kind: 'email'),
      [
        flight('245', DateTime.utc(2026, 12, 21, 5), update: first.itemIds.single, trip: 0),
        flight('246', DateTime.utc(2026, 12, 24, 10), trip: 0),
      ],
      deviceTz: 'Asia/Ho_Chi_Minh',
      trips: [TripDraft(existingTripId: first.tripIds.single, startsOn: '2026-12-21', endsOn: '2026-12-24')],
    );
    expect(second.updatedItemIds, first.itemIds);
    expect(second.itemIds, hasLength(1));
    expect(second.tripIds, first.tripIds);
    final moved = await (db.select(db.items)..where((t) => t.id.equals(first.itemIds.single))).getSingle();
    expect(moved.startsAt, DateTime.utc(2026, 12, 21, 5).millisecondsSinceEpoch);
    expect(await db.select(db.items).get(), hasLength(2), reason: 'không tạo bản trùng');
    final trip = (await trips.trips()).single;
    expect((trip.endsOn, trip.itemCount, trip.overlaps('2026-12-25', '2026-12-26'), trip.overlaps('2026-12-27', '2026-12-28')), ('2026-12-24', 2, true, false));
    expect(trip.activeOn('2026-12-24'), isTrue);
    expect(trip.activeOn('2026-12-25'), isFalse);

    await trips.delete(trip.id);
    expect(await trips.trips(), isEmpty);
    expect((await db.select(db.items).get()).map((i) => i.tripId).toSet(), {null});
  });

  test('tier_used/kind sai bị chặn ngay ở máy (server sẽ từ chối cả lần nhập)', () async {
    expect(() => imports.commit(const ImportRecord(kind: 'email', tierUsed: 't2'), const [], deviceTz: 'Asia/Ho_Chi_Minh'), throwsArgumentError);
    expect(() => imports.commit(const ImportRecord(kind: 'csv'), const [], deviceTz: 'Asia/Ho_Chi_Minh'), throwsArgumentError);
  });
}
