import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:test/test.dart';

import 'fake_server.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late ItemsRepository items;
  late ListsRepository lists;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    final engine = SyncEngine(db: db, api: FakeServer().apiFor('p'), clock: HlcClock('p'), deviceId: 'p');
    items = ItemsRepository(engine);
    lists = ListsRepository(engine);
  });
  tearDown(() => db.close());

  test('Inbox ảo (chưa có list server) + list người dùng, đếm việc đang mở', () async {
    final work = await lists.create('  Công việc ');
    await items.create(title: 'A');
    await items.create(title: 'B', listId: work);
    final done = await items.create(title: 'C', listId: work);
    await items.setDone(done, done: true);
    final all = await lists.watchLists().first;
    expect(all.map((l) => (l.isInbox, l.name, l.openCount)), [(true, null, 1), (false, 'Công việc', 1)]);
    expect((await lists.watchItems(null).first).single.title, 'A');
    expect((await lists.watchItems(work).first).single.title, 'B');
  });

  test('đếm việc quá hạn / hôm nay theo ngày đang xem (có giờ và cả ngày)', () async {
    final work = await lists.create('Công việc');
    // Ngày 1/12/2026 giờ UTC+7: [30/11 17:00Z, 1/12 17:00Z).
    final day = DayWindow(startUtc: DateTime.utc(2026, 11, 30, 17), endUtc: DateTime.utc(2026, 12, 1, 17), localDate: '2026-12-01');
    await items.create(title: 'trễ', listId: work, startsAt: DateTime.utc(2026, 11, 30, 10), tz: 'Asia/Ho_Chi_Minh');
    await items.create(title: 'trễ cả ngày', listId: work, startDate: '2026-11-29');
    await items.create(title: 'hôm nay', listId: work, startsAt: DateTime.utc(2026, 12, 1, 3), tz: 'Asia/Ho_Chi_Minh');
    await items.create(title: 'hôm nay cả ngày', listId: work, startDate: '2026-12-01');
    await items.create(title: 'mai', listId: work, startsAt: DateTime.utc(2026, 12, 1, 18), tz: 'Asia/Ho_Chi_Minh');
    await items.create(title: 'chưa hẹn', listId: work);
    final w = (await lists.watchLists(today: day).first).last;
    expect((w.openCount, w.overdue, w.today), (6, 2, 2));
    expect((await lists.watchLists().first).last.overdue, 0, reason: 'không truyền ngày thì không đếm');
  });

  test('Inbox từ server (is_inbox) gộp với việc không có list', () async {
    await db.into(db.lists).insert(ListsCompanion.insert(id: 'inbox', isInbox: const Value(true)));
    await items.create(title: 'A');
    await items.create(title: 'B', listId: 'inbox');
    final all = await lists.watchLists().first;
    expect(all.single.id, 'inbox');
    expect(all.single.openCount, 2);
    expect((await lists.watchItems('inbox').first).map((i) => i.title).toSet(), {'A', 'B'});
  });

  test('đổi tên, chuyển việc sang list, xóa list → việc về Inbox', () async {
    final l = await lists.create('Nhà');
    final a = await items.create(title: 'Sửa vòi nước');
    await items.setList(a, l);
    expect((await lists.watchItems(l).first).single.id, a);
    await lists.rename(l, 'Việc nhà');
    expect((await lists.watchLists().first).last.name, 'Việc nhà');
    await lists.delete(l);
    expect((await lists.watchLists().first), hasLength(1));
    expect((await lists.watchItems(null).first).single.id, a);
    expect(() => lists.create(' '), throwsArgumentError);
  });

  test('#tag khớp tên list không dấu, không khoảng trắng', () async {
    final work = await lists.create('Công việc');
    expect(await lists.matchTag('congviec'), work);
    expect(await lists.matchTag('CongViec'), work);
    expect(await lists.matchTag('nha'), isNull);
  });
}
