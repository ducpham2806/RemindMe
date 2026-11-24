import 'package:drift/drift.dart';

// Bảng client mirror bảng server, cùng tên bảng/cột (data-model.md §3, §5). Drift đổi getter camelCase thành snake_case.
// Kiểu: uuid/text → TEXT; timestamptz → INTEGER epoch ms UTC; date → TEXT 'YYYY-MM-DD'; jsonb/mảng → TEXT JSON; bool → INTEGER.
// Cột ngoài khóa đều nullable: dữ liệu đến từng phần (merge theo trường), ràng buộc thật nằm ở server.

mixin SyncCols on Table {
  IntColumn get version => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();
  TextColumn get deviceId => text().nullable()();
  TextColumn get fieldClock => text().withDefault(const Constant('{}'))();
}

@DataClassName('TaskList')
class Lists extends Table with SyncCols {
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  IntColumn get sortOrder => integer().nullable()();
  BoolColumn get isInbox => boolean().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class Trips extends Table with SyncCols {
  TextColumn get id => text()();
  TextColumn get title => text().nullable()();
  TextColumn get destination => text().nullable()();
  TextColumn get startsOn => text().nullable()();
  TextColumn get endsOn => text().nullable()();
  TextColumn get coverUrl => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class Imports extends Table with SyncCols {
  TextColumn get id => text()();
  TextColumn get kind => text().nullable()();
  TextColumn get sha256 => text().nullable()();
  TextColumn get mime => text().nullable()();
  IntColumn get bytes => integer().nullable()();
  TextColumn get status => text().nullable()();
  TextColumn get docType => text().nullable()();
  TextColumn get docLanguage => text().nullable()();
  TextColumn get templateId => text().nullable()();
  IntColumn get templateVersion => integer().nullable()();
  TextColumn get tierUsed => text().nullable()();
  TextColumn get originalPath => text().nullable()();
  TextColumn get error => text().nullable()();
  IntColumn get createdAt => integer().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class Items extends Table with SyncCols {
  TextColumn get id => text()();
  TextColumn get listId => text().nullable()();
  TextColumn get tripId => text().nullable()();
  TextColumn get importId => text().nullable()();
  TextColumn get kind => text().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text().nullable()();
  TextColumn get archivedReason => text().nullable()();
  IntColumn get priority => integer().nullable()();
  IntColumn get startsAt => integer().nullable()();
  IntColumn get endsAt => integer().nullable()();
  BoolColumn get allDay => boolean().nullable()();
  TextColumn get startDate => text().nullable()();
  TextColumn get endDate => text().nullable()();
  TextColumn get tz => text().nullable()();
  TextColumn get endTz => text().nullable()();
  TextColumn get timeMode => text().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get tags => text().nullable()();
  TextColumn get source => text().nullable()();
  TextColumn get sourceRef => text().nullable()();
  TextColumn get checklist => text().nullable()();
  IntColumn get completedAt => integer().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class Recurrences extends Table with SyncCols {
  TextColumn get itemId => text()();
  TextColumn get kind => text().nullable()();
  TextColumn get rrule => text().nullable()();
  TextColumn get calendar => text().nullable()();
  IntColumn get intervalDays => integer().nullable()();
  TextColumn get workdaysRegion => text().nullable()();
  IntColumn get dtstart => integer().nullable()();
  IntColumn get until => integer().nullable()();
  TextColumn get exdates => text().nullable()();
  @override
  Set<Column> get primaryKey => {itemId};
}

class Reminders extends Table with SyncCols {
  TextColumn get id => text()();
  TextColumn get itemId => text().nullable()();
  TextColumn get triggerKind => text().nullable()();
  IntColumn get at => integer().nullable()();
  IntColumn get offsetMinutes => integer().nullable()();
  TextColumn get geofence => text().nullable()();
  TextColumn get channel => text().nullable()();
  BoolColumn get isAlarm => boolean().nullable()();
  IntColumn get snoozedUntil => integer().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class BookingDetails extends Table with SyncCols {
  TextColumn get itemId => text()();
  TextColumn get bookingType => text().nullable()();
  TextColumn get provider => text().nullable()();
  TextColumn get confirmationCode => text().nullable()();
  TextColumn get carrierCode => text().nullable()();
  TextColumn get number => text().nullable()();
  TextColumn get origin => text().nullable()();
  TextColumn get destination => text().nullable()();
  TextColumn get seat => text().nullable()();
  TextColumn get class_ => text().named('class').nullable()();
  TextColumn get passengers => text().nullable()();
  IntColumn get checkInAt => integer().nullable()();
  IntColumn get checkOutAt => integer().nullable()();
  TextColumn get price => text().nullable()();
  TextColumn get extractionMeta => text().nullable()();
  @override
  Set<Column> get primaryKey => {itemId};
}

class OccurrenceLog extends Table with SyncCols {
  TextColumn get itemId => text()();
  IntColumn get occurrenceAt => integer()();
  TextColumn get status => text().nullable()();
  @override
  Set<Column> get primaryKey => {itemId, occurrenceAt};
}

// ---- Bảng chỉ có ở client (data-model.md §5)

@DataClassName('OutboxEntry')
class Outbox extends Table {
  IntColumn get seq => integer().autoIncrement()();
  /// JSON của `Mutation` (đúng định dạng gửi `sync_push`).
  TextColumn get mutation => text()();
  IntColumn get createdAt => integer()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
}

@DataClassName('SyncStateEntry')
class SyncState extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

/// Kết quả server từ chối (quota, invalid) hoặc xung đột ghi chú, chờ UI xử lý (paywall, màn chọn bản UX §3.6).
@DataClassName('SyncIssue')
class SyncIssues extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get tableName_ => text().named('table_name')();
  TextColumn get rowId => text()();
  /// quota_exceeded | invalid | notes_conflict | deleted
  TextColumn get kind => text()();
  TextColumn get detail => text().nullable()();
  IntColumn get createdAt => integer()();
}
