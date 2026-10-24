import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Habits, HabitEntries])
class AppDatabase extends _$AppDatabase {
  /// Production database (file-backed, on-device).
  AppDatabase() : super(driftDatabase(name: 'habitflow'));

  /// For tests: pass `NativeDatabase.memory()`.
  AppDatabase.forTesting(super.e);

  /// Bump on every schema change and add a migration step below.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Example for the future:
          // if (from < 2) await m.addColumn(habits, habits.someNewColumn);
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
