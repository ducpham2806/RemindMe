import 'package:drift/drift.dart';
import 'package:remindme_core/remindme_core.dart';

import 'database.dart';
import 'items_repository.dart';
import 'lists_repository.dart';
import 'sync_engine.dart';

/// 1 việc/sự kiện đã qua màn Xem lại, sẵn sàng ghi (thời điểm đã đổi sang UTC + tz IANA ở tầng app).
class ImportedItem {
  const ImportedItem({
    required this.title,
    this.kind = 'task',
    this.startsAt,
    this.tz,
    this.startDate,
    this.endsAt,
    this.endTz,
    this.endDate,
    this.priority = 0,
    this.tags = const [],
    this.notes,
    this.locationText,
    this.checklist = const [],
    this.done = false,
    this.recurrence,
    this.recurrenceStart,
    this.reminderOffsets = const [],
    this.listName,
  });

  final String title;
  final String kind;
  final DateTime? startsAt;
  final String? tz;
  final String? startDate;
  final DateTime? endsAt;
  final String? endTz;
  final String? endDate;
  final int priority;
  final List<String> tags;
  final String? notes;
  final String? locationText;
  final List<({String text, bool done})> checklist;
  final bool done;
  /// Dạng hàng `recurrences` (kind + rrule/calendar).
  final Map<String, Object?>? recurrence;
  final DateTime? recurrenceStart;
  final List<int> reminderOffsets;
  /// Tên list đề xuất: khớp list có sẵn (không dấu, bỏ khoảng trắng) hoặc tạo mới.
  final String? listName;
}

/// Thông tin của lần nhập (hàng `imports`). [kind] theo cột `imports.kind`: image, pdf, xlsx, md, email, ics, pkpass...
class ImportRecord {
  const ImportRecord({required this.kind, this.mime, this.bytes, this.sha256, this.docType, this.docLanguage, this.tierUsed = 't0'});
  final String kind;
  final String? mime;
  final int? bytes;
  final String? sha256;
  final String? docType;
  final String? docLanguage;
  final String tierUsed;
}

class ImportResult {
  const ImportResult({required this.importId, required this.itemIds, required this.createdListIds, required this.pendingQuota});
  final String importId;
  final List<String> itemIds;
  final List<String> createdListIds;
  /// Vượt `smart_imports_per_month` khi chưa kiểm được với server: item lưu ở `pending_quota` (ADR-008).
  final bool pendingQuota;
}

/// Ghi kết quả màn Xem lại: 1 hàng `imports` + các item trỏ về nó (`import_id`). Luôn qua [SyncEngine] (ADR-012).
class ImportsRepository {
  ImportsRepository(this.engine, this.items, this.lists, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final SyncEngine engine;
  final ItemsRepository items;
  final ListsRepository lists;
  final DateTime Function() _now;

  AppDatabase get _db => engine.db;

  /// Loại tính vào `smart_imports_per_month` (giống `app.usage_for` trên server; .ics, .pkpass, .md không tính).
  static const smartKinds = {'image', 'pdf', 'xlsx', 'email'};

  /// Lượt nhập thông minh trong tháng hiện tại theo [deviceTz], tính cả bản đã xóa, trừ `failed` (như server).
  Future<int> smartImportsThisMonth(String deviceTz) async {
    final wall = TimeZones.toWall(_now(), deviceTz);
    final first = TimeZones.toUtc(CivilDateTime(CivilDate(wall.date.year, wall.date.month, 1)), deviceTz).utc;
    final rows = await (_db.select(_db.imports)
          ..where((t) =>
              t.kind.isIn(smartKinds) &
              (t.status.isNull() | t.status.isNotValue('failed')) &
              t.createdAt.isBiggerOrEqualValue(first.millisecondsSinceEpoch)))
        .get();
    return rows.length;
  }

  Future<ImportResult> commit(
    ImportRecord record,
    List<ImportedItem> drafts, {
    required String deviceTz,
    String? defaultListId,
    QuotaStatus? quota,
  }) async {
    var pending = false;
    if (quota != null && smartKinds.contains(record.kind) && !quota.isUnlimited(EntitlementKey.smartImportsPerMonth)) {
      final used = await smartImportsThisMonth(deviceTz);
      pending = used + 1 > quota.limit(EntitlementKey.smartImportsPerMonth);
    }
    final nowMs = _now().millisecondsSinceEpoch;
    final importId = uuidV7(nowMillis: nowMs);
    await engine.edit(SyncTable.imports, importId, {
      'kind': record.kind,
      'status': 'committed',
      'tier_used': record.tierUsed,
      'mime': ?record.mime,
      'bytes': ?record.bytes,
      'sha256': ?record.sha256,
      'doc_type': ?record.docType,
      'doc_language': ?record.docLanguage,
    });
    // created_at do server đặt (không đồng bộ từ máy); local cần để đếm hạn mức trước khi sync.
    await (_db.update(_db.imports)..where((t) => t.id.equals(importId))).write(ImportsCompanion(createdAt: Value(nowMs)));

    final listIds = <String, String>{};
    final created = <String>[];
    Future<String?> listFor(String? name) async {
      final n = name?.trim();
      if (n == null || n.isEmpty) return defaultListId;
      final key = foldForSearch(n).replaceAll(' ', '');
      if (listIds[key] case final id?) return id;
      var id = await lists.matchTag(n);
      if (id == null) {
        id = await lists.create(n);
        created.add(id);
      }
      return listIds[key] = id;
    }

    final ids = <String>[];
    for (final d in drafts) {
      if (d.title.trim().isEmpty) continue;
      ids.add(await items.create(
        title: d.title,
        kind: d.kind,
        listId: await listFor(d.listName),
        startsAt: d.startsAt,
        tz: d.tz,
        startDate: d.startDate,
        endsAt: d.endsAt,
        endTz: d.endTz,
        endDate: d.endDate,
        priority: d.priority.clamp(0, 3),
        tags: d.tags,
        source: _itemSource(record.kind),
        notes: d.notes,
        location: d.locationText == null ? null : {'name': d.locationText},
        checklist: [for (final c in d.checklist) {'text': c.text, 'done': c.done}],
        status: pending ? 'pending_quota' : (d.done ? 'done' : 'open'),
        recurrence: d.recurrence,
        recurrenceStart: d.recurrenceStart,
        reminderOffsets: d.done ? const [] : d.reminderOffsets,
        importId: importId,
      ));
    }
    return ImportResult(importId: importId, itemIds: ids, createdListIds: created, pendingQuota: pending);
  }

  /// `imports.kind` → `items.source` (2 enum khác nhau trên server).
  static String _itemSource(String kind) => switch (kind) {
        'image' || 'pdf' || 'xlsx' || 'md' || 'email' || 'ics' || 'pkpass' || 'voice' => kind,
        _ => 'manual',
      };
}
