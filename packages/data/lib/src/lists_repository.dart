import 'package:drift/drift.dart';
import 'package:remindme_core/remindme_core.dart';

import 'database.dart';
import 'items_repository.dart';
import 'sync_engine.dart';

/// Một list kèm số việc đang mở. [id] null = Inbox khi chưa có list Inbox từ server (item không thuộc list nào).
class ListSummary {
  const ListSummary({required this.id, required this.name, required this.isInbox, required this.openCount});
  final String? id;
  /// Tên do người dùng đặt; Inbox không có tên (UI dùng chuỗi đã dịch).
  final String? name;
  final bool isInbox;
  final int openCount;
}

/// List (S2). Inbox là list mặc định: id `inboxListId(user)` do `profile_init` tạo trên server; trước khi đăng nhập,
/// việc không có list cũng tính là Inbox. Giới hạn số list theo `plan_entitlements.max_lists` do server kiểm (không tính Inbox).
class ListsRepository {
  ListsRepository(this.engine, {DateTime Function()? now}) : _now = now ?? DateTime.now;
  final SyncEngine engine;
  final DateTime Function() _now;
  AppDatabase get _db => engine.db;

  Stream<List<ListSummary>> watchLists() async* {
    final changes = _db.tableUpdates(TableUpdateQuery.onAllTables([_db.lists, _db.items]));
    yield await _lists();
    await for (final _ in changes) {
      yield await _lists();
    }
  }

  Future<List<ListSummary>> _lists() async {
    final lists = await (_db.select(_db.lists)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.id)]))
        .get();
    final counts = <String?, int>{};
    for (final row in await _db
        .customSelect(
          "SELECT list_id, COUNT(*) AS n FROM items WHERE deleted_at IS NULL AND status IN ('open','pending_quota') GROUP BY list_id",
          readsFrom: {_db.items},
        )
        .get()) {
      counts[row.data['list_id'] as String?] = row.data['n']! as int;
    }
    final inbox = lists.where((l) => l.isInbox ?? false).firstOrNull;
    return [
      ListSummary(id: inbox?.id, name: null, isInbox: true, openCount: (counts[null] ?? 0) + (inbox == null ? 0 : counts[inbox.id] ?? 0)),
      for (final l in lists)
        if (!(l.isInbox ?? false)) ListSummary(id: l.id, name: l.name ?? '', isInbox: false, openCount: counts[l.id] ?? 0),
    ];
  }

  /// Việc đang mở của list [listId] (null hoặc id Inbox = Inbox).
  Stream<List<ItemView>> watchItems(String? listId) async* {
    final changes = _db.tableUpdates(TableUpdateQuery.onAllTables([_db.lists, _db.items]));
    yield await _items(listId);
    await for (final _ in changes) {
      yield await _items(listId);
    }
  }

  Future<List<ItemView>> _items(String? listId) async {
    final inboxId = (await (_db.select(_db.lists)..where((t) => t.isInbox.equals(true) & t.deletedAt.isNull())).getSingleOrNull())?.id;
    final isInbox = listId == null || listId == inboxId;
    final rows = await (_db.select(_db.items)
          ..where((t) =>
              t.deletedAt.isNull() &
              t.status.isIn(const ['open', 'pending_quota']) &
              (isInbox
                  ? (t.listId.isNull() | (inboxId == null ? const Constant(false) : t.listId.equals(inboxId)))
                  : t.listId.equals(listId))))
        .get();
    final views = rows.map(ItemView.fromRow).toList()
      ..sort((a, b) {
        // Có thời điểm trước (sớm trước), rồi ưu tiên cao, rồi thứ tự tạo.
        final ta = a.startsAt?.millisecondsSinceEpoch ?? (a.startDate == null ? null : DateTime.parse(a.startDate!).millisecondsSinceEpoch);
        final tb = b.startsAt?.millisecondsSinceEpoch ?? (b.startDate == null ? null : DateTime.parse(b.startDate!).millisecondsSinceEpoch);
        if (ta != tb) return ta == null ? 1 : (tb == null ? -1 : ta.compareTo(tb));
        if (a.priority != b.priority) return b.priority.compareTo(a.priority);
        return a.id.compareTo(b.id);
      });
    return views;
  }

  Future<String> create(String name) async {
    final n = name.trim();
    if (n.isEmpty) throw ArgumentError.value(name, 'name', 'không được rỗng');
    final id = uuidV7(nowMillis: _now().millisecondsSinceEpoch);
    final maxOrder = (await _db.customSelect('SELECT MAX(sort_order) AS m FROM lists WHERE deleted_at IS NULL', readsFrom: {_db.lists}).getSingle())
            .data['m'] as int? ??
        0;
    await engine.edit(SyncTable.lists, id, {'name': n, 'sort_order': maxOrder + 1, 'is_inbox': false});
    return id;
  }

  Future<void> rename(String id, String name) {
    final n = name.trim();
    if (n.isEmpty) throw ArgumentError.value(name, 'name', 'không được rỗng');
    return engine.edit(SyncTable.lists, id, {'name': n});
  }

  /// Xóa list: việc trong list chuyển về Inbox (không mất việc).
  Future<void> delete(String id) async {
    final items = await (_db.select(_db.items)..where((t) => t.listId.equals(id) & t.deletedAt.isNull())).get();
    for (final i in items) {
      await engine.edit(SyncTable.items, i.id, {'list_id': null});
    }
    await engine.delete(SyncTable.lists, id);
  }

  /// List có tên khớp [tag] (không phân biệt hoa thường/dấu, bỏ khoảng trắng): "#congviec" → list "Công việc".
  Future<String?> matchTag(String tag) async {
    final key = foldForSearch(tag).replaceAll(' ', '');
    for (final l in await (_db.select(_db.lists)..where((t) => t.deletedAt.isNull())).get()) {
      if (l.isInbox ?? false) continue;
      if (foldForSearch(l.name ?? '').replaceAll(' ', '') == key) return l.id;
    }
    return null;
  }
}
