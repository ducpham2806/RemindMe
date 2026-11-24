import 'package:drift/drift.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Lists, Trips, Imports, Items, Recurrences, Reminders, BookingDetails, OccurrenceLog, Outbox, SyncState, SyncIssues])
class AppDatabase extends _$AppDatabase {
  /// Executor do app cấp: `drift_flutter` trên mobile/desktop, `NativeDatabase.memory()` trong test.
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
