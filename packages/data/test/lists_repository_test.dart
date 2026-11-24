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
