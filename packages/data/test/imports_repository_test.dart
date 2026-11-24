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
  late ListsRepository lists;
  var now = DateTime.utc(2026, 11, 24, 3);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    final engine = SyncEngine(db: db, api: FakeServer().apiFor('p'), clock: HlcClock('p'), deviceId: 'p');
    lists = ListsRepository(engine, now: () => now);
    imports = ImportsRepository(engine, ItemsRepository(engine, now: () => now), lists, now: () => now);
  });
  tearDown(() => db.close());

  Future<List<Item>> allItems() => db.select(db.items).get();

  test('1 hàng imports + item trỏ về nó; list theo tên (khớp có sẵn không dấu, tạo mới 1 lần), checklist, địa điểm, đã xong', () async {
    final existing = await lists.create('Sửa chữa');
    final r = await imports.commit(
      const ImportRecord(kind: 'md', mime: 'text/markdown', bytes: 420, docLanguage: 'vi'),
      [
        ImportedItem(title: 'Sơn cổng', listName: 'SUA CHUA', startDate: '2026-12-12', checklist: [(text: 'Mua sơn', done: false), (text: 'Mua cọ', done: true)]),
        ImportedItem(title: 'Gọi thợ', listName: 'Sửa chữa', done: true, reminderOffsets: [0], startsAt: DateTime.utc(2026, 11, 20, 2), tz: 'Asia/Ho_Chi_Minh'),
        const ImportedItem(title: 'Đóng tiền điện', listName: 'Định kỳ', locationText: 'EVN', priority: 7),
        const ImportedItem(title: '   '),
      ],
      deviceTz: 'Asia/Ho_Chi_Minh',
    );
    expect(r.itemIds, hasLength(3));
    expect(r.createdListIds, hasLength(1));
    expect(r.pendingQuota, isFalse);
    final imp = await (db.select(db.imports)..where((t) => t.id.equals(r.importId))).getSingle();
    expect((imp.kind, imp.status, imp.tierUsed, imp.docLanguage, imp.createdAt), ('md', 'committed', 't0', 'vi', now.millisecondsSinceEpoch));
    final rows = await allItems();
    expect(rows.every((i) => i.importId == r.importId && i.source == 'md'), isTrue);
    final byTitle = {for (final i in rows) i.title: i};
    expect(byTitle['Sơn cổng']!.listId, existing);
    expect(jsonDecode(byTitle['Sơn cổng']!.checklist!), [
      {'text': 'Mua sơn', 'done': false},
      {'text': 'Mua cọ', 'done': true},
    ]);
    expect((byTitle['Gọi thợ']!.status, byTitle['Gọi thợ']!.completedAt != null), ('done', true));
    expect(await db.select(db.reminders).get(), isEmpty, reason: 'việc đã xong không lập nhắc');
    expect(byTitle['Đóng tiền điện']!.listId, r.createdListIds.single);
    expect(jsonDecode(byTitle['Đóng tiền điện']!.location!), {'name': 'EVN'});
    expect(byTitle['Đóng tiền điện']!.priority, 3);
  });

  test('sự kiện có giờ kết thúc, lặp, nhắc; list mặc định khi không có tên list', () async {
    final inbox = await lists.create('Nhập');
    await imports.commit(
      const ImportRecord(kind: 'ics'),
      [
        ImportedItem(
          title: 'Họp',
          kind: 'event',
          startsAt: DateTime.utc(2026, 12, 5, 3, 30),
          tz: 'Asia/Ho_Chi_Minh',
          endsAt: DateTime.utc(2026, 12, 5, 4, 30),
          endTz: 'Asia/Ho_Chi_Minh',
          recurrence: const {'kind': 'rrule', 'rrule': 'FREQ=WEEKLY;BYDAY=SA'},
          recurrenceStart: DateTime.utc(2026, 12, 5, 3, 30),
          reminderOffsets: const [15, 1440],
        ),
      ],
      deviceTz: 'Asia/Ho_Chi_Minh',
      defaultListId: inbox,
    );
    final i = (await allItems()).single;
    expect((i.kind, i.source, i.listId, i.endsAt), ('event', 'ics', inbox, DateTime.utc(2026, 12, 5, 4, 30).millisecondsSinceEpoch));
    expect((await db.select(db.recurrences).get()).single.rrule, 'FREQ=WEEKLY;BYDAY=SA');
    expect((await db.select(db.reminders).get()).length, 2);
  });

  test('hạn mức nhập thông minh: đếm theo tháng của múi giờ máy, .md không tính; vượt thì item pending_quota', () async {
    QuotaStatus quota(int limit) => QuotaStatus(
        plan: 'free', limits: {EntitlementKey.smartImportsPerMonth: limit}, usage: const {}, features: const {}, fetchedAt: now);
    now = DateTime.utc(2026, 10, 31, 18); // 1/11 01:00 ở Việt Nam
    await imports.commit(const ImportRecord(kind: 'xlsx'), const [ImportedItem(title: 'a')], deviceTz: 'Asia/Ho_Chi_Minh', quota: quota(2));
    now = DateTime.utc(2026, 11, 24);
    await imports.commit(const ImportRecord(kind: 'md'), const [ImportedItem(title: 'b')], deviceTz: 'Asia/Ho_Chi_Minh', quota: quota(2));
    expect(await imports.smartImportsThisMonth('Asia/Ho_Chi_Minh'), 1);
    expect(await imports.smartImportsThisMonth('America/New_York'), 0, reason: 'ở New York lần đầu thuộc tháng 10');
    final ok = await imports.commit(const ImportRecord(kind: 'email'), const [ImportedItem(title: 'c')], deviceTz: 'Asia/Ho_Chi_Minh', quota: quota(2));
    expect(ok.pendingQuota, isFalse);
    final over = await imports.commit(const ImportRecord(kind: 'xlsx'), const [ImportedItem(title: 'd')], deviceTz: 'Asia/Ho_Chi_Minh', quota: quota(2));
    expect(over.pendingQuota, isTrue);
    expect((await allItems()).firstWhere((i) => i.title == 'd').status, 'pending_quota');
    final unlimited = await imports.commit(const ImportRecord(kind: 'xlsx'), const [ImportedItem(title: 'e')],
        deviceTz: 'Asia/Ho_Chi_Minh', quota: quota(-1));
    expect(unlimited.pendingQuota, isFalse);
  });
}
