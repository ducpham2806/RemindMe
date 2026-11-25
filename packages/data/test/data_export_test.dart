import 'dart:convert';

import 'package:drift/native.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:test/test.dart';

import 'fake_server.dart';

void main() {
  late AppDatabase db;
  late ItemsRepository repo;
  final now = DateTime.utc(2026, 12, 1, 2);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    final engine = SyncEngine(db: db, api: FakeServer().apiFor('phone'), clock: HlcClock('phone', now: () => now.millisecondsSinceEpoch), deviceId: 'phone');
    repo = ItemsRepository(engine, now: () => now);
  });
  tearDown(() => db.close());

  test('JSON: export_version, mảng theo bảng, thời điểm ISO UTC, bỏ cột nội bộ và hàng đã xóa', () async {
    final keep = await repo.create(title: 'Khám răng', startsAt: DateTime.utc(2026, 12, 2, 1, 30), tz: 'Asia/Ho_Chi_Minh', reminderOffsets: const [-60], tags: const ['sức khỏe']);
    final gone = await repo.create(title: 'Bỏ');
    await repo.delete(gone);
    final j = jsonDecode(await DataExporter(db).json(now: now)) as Map<String, Object?>;
    expect(j['export_version'], 1);
    expect(j.keys, containsAll(['lists', 'trips', 'imports', 'items', 'recurrences', 'reminders', 'booking_details', 'occurrence_log']));
    final items = (j['items']! as List).cast<Map<String, Object?>>();
    expect(items.map((i) => i['id']), [keep]);
    expect(items.single['starts_at'], '2026-12-02T01:30:00.000Z');
    expect(items.single['tz'], 'Asia/Ho_Chi_Minh');
    expect(items.single['tags'], ['sức khỏe']);
    expect(items.single.keys, isNot(contains('field_clock')));
    expect(((j['reminders']! as List).single as Map)['offset_minutes'], -60);
  });

  test('ICS: VTODO giờ tường theo TZID, RRULE giữ nguyên, việc cả ngày VALUE=DATE, lặp âm lịch trải phẳng 2 năm', () async {
    await repo.create(title: 'Uống thuốc; sáng', startsAt: DateTime.utc(2026, 12, 1, 1), tz: 'Asia/Ho_Chi_Minh',
        recurrence: {'kind': 'rrule', 'rrule': 'FREQ=DAILY'}, recurrenceStart: DateTime.utc(2026, 12, 1, 1));
    await repo.create(title: 'Đóng tiền nhà', startDate: '2026-12-05', tz: 'Asia/Ho_Chi_Minh');
    await repo.create(title: 'Giỗ ông', startDate: '2026-12-01', tz: 'Asia/Ho_Chi_Minh',
        recurrence: {'kind': 'calendar', 'calendar': {'system': 'lunar_vi', 'day': 23, 'month': 10}}, recurrenceStart: DateTime.utc(2026, 11, 30, 17));
    final ics = await DataExporter(db).ics(now: now, deviceTz: 'Asia/Ho_Chi_Minh', prodId: '-//RemindMe//Export//EN');
    expect(ics, startsWith('BEGIN:VCALENDAR\r\nVERSION:2.0\r\n'));
    expect(ics, contains('DUE;TZID=Asia/Ho_Chi_Minh:20261201T080000\r\n'));
    expect(ics, contains(r'SUMMARY:Uống thuốc\; sáng'));
    expect(ics, contains('RRULE:FREQ=DAILY\r\n'));
    expect(ics, contains('DUE;VALUE=DATE:20261205\r\n'));
    // 23/10 âm: 1/12/2026 và 9/12/2027 (2 năm tới).
    expect(RegExp('SUMMARY:Giỗ ông').allMatches(ics), hasLength(2));
    expect(ics, contains('DUE;VALUE=DATE:20261201\r\n'));
    expect(ics.trimRight(), endsWith('END:VCALENDAR'));
    for (final line in ics.split('\r\n')) {
      expect(utf8.encode(line).length, lessThanOrEqualTo(75));
    }
  });
}
