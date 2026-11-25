import 'package:drift/drift.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Lists, Trips, Imports, Items, Recurrences, Reminders, BookingDetails, OccurrenceLog, Outbox, SyncState, SyncIssues, ScheduledNotifications])
class AppDatabase extends _$AppDatabase {
  /// Executor do app cấp: `drift_flutter` trên mobile/desktop, `NativeDatabase.memory()` trong test.
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          // v2 (S3): bảng scheduled_notifications cho rolling window.
          if (from < 2) await m.createTable(scheduledNotifications);
          // v3: checklist hành lý trên trips.
          if (from < 3) await m.addColumn(trips, trips.packing);
        },
      );
}
