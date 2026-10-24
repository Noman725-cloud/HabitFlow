import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/date_utils.dart';
import '../../domain/models/entry.dart';
import '../../domain/models/habit.dart';
import '../../domain/repositories/entry_repository.dart';
import '../database/app_database.dart';
import 'mappers.dart';

class DriftEntryRepository implements EntryRepository {
  DriftEntryRepository(this._db, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;
  static const _uuid = Uuid();

  Stream<List<Entry>> _watch(
    Expression<bool> Function($HabitEntriesTable t) filter,
  ) {
    final query = _db.select(_db.habitEntries)
      ..where((t) => t.deletedAt.isNull() & filter(t));
    return query.watch().map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  @override
  Stream<List<Entry>> watchForDate(String dateKey) =>
      _watch((t) => t.date.equals(dateKey));

  @override
  Stream<List<Entry>> watchRange(String startKey, String endKey) =>
      _watch((t) => t.date.isBetweenValues(startKey, endKey));

  @override
  Stream<List<Entry>> watchForHabit(String habitId) =>
      _watch((t) => t.habitId.equals(habitId));

  @override
  Future<void> setValue({
    required Habit habit,
    required String date,
    required int value,
  }) {
    final now = _now();
    final todayKey = toDateKey(now);
    if (date.compareTo(todayKey) > 0) {
      throw ArgumentError.value(date, 'date', 'Cannot log future dates');
    }
    final clamped = value < 0 ? 0 : value;

    return _db.transaction(() async {
      final existing = await (_db.select(_db.habitEntries)
            ..where((t) => t.habitId.equals(habit.id) & t.date.equals(date)))
          .getSingleOrNull();

      if (existing == null) {
        await _db.into(_db.habitEntries).insert(
              HabitEntriesCompanion.insert(
                id: _uuid.v4(),
                habitId: habit.id,
                date: date,
                value: clamped,
                target: habit.targetValue,
                updatedAt: now,
              ),
            );
        return;
      }

      final target = date == todayKey ? habit.targetValue : existing.target;
      await (_db.update(_db.habitEntries)
            ..where((t) => t.id.equals(existing.id)))
          .write(
        HabitEntriesCompanion(
          value: Value(clamped),
          target: Value(target),
          updatedAt: Value(now),
          deletedAt: const Value(null), // revive if previously tombstoned
        ),
      );
    });
  }
}
