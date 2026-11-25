import 'database.dart';

/// Tùy chọn chỉ của máy này (không đồng bộ), lưu trong bảng `sync_state` với khóa `pref.<tên>`.
class LocalPrefs {
  LocalPrefs(this._db);
  final AppDatabase _db;

  Future<String?> get(String name) async =>
      (await (_db.select(_db.syncState)..where((s) => s.key.equals('pref.$name'))).getSingleOrNull())?.value;

  Future<void> set(String name, String value) =>
      _db.into(_db.syncState).insertOnConflictUpdate(SyncStateCompanion.insert(key: 'pref.$name', value: value));

  /// Tập chuỗi (mỗi dòng 1 giá trị).
  Future<Set<String>> getSet(String name) async => {...?(await get(name))?.split('\n').where((s) => s.isNotEmpty)};

  Future<void> addToSet(String name, String value) async => set(name, ({...await getSet(name), value}.toList()..sort()).join('\n'));
}
