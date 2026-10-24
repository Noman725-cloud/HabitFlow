import 'package:drift/drift.dart';

import '../../core/date_utils.dart';
import '../../domain/models/habit.dart';
import '../../domain/repositories/habit_repository.dart';
import '../database/app_database.dart';
import 'mappers.dart';

class DriftHabitRepository implements HabitRepository {
  DriftHabitRepository(this._db, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  @override
  Stream<List<Habit>> watchActive() {
    final query = _db.select(_db.habits)
      ..where((t) => t.deletedAt.isNull() & t.archivedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return query.watch().map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  @override
  Future<Habit?> getById(String id) async {
    final row = await (_db.select(_db.habits)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<void> create(Habit habit) async {
    await _db.into(_db.habits).insert(habit.toCompanion());
  }

  @override
  Future<void> update(Habit habit) => _db.transaction(() async {
        final now = _now();
        await (_db.update(_db.habits)..where((t) => t.id.equals(habit.id)))
            .write(habit.copyWith(updatedAt: now).toCompanion());
        // Today's entry follows the current goal; past entries keep their
        // snapshot so editing a goal never rewrites history.
        await (_db.update(_db.habitEntries)
              ..where((t) =>
                  t.habitId.equals(habit.id) &
                  t.date.equals(toDateKey(now)) &
                  t.deletedAt.isNull()))
            .write(HabitEntriesCompanion(
          target: Value(habit.targetValue),
          updatedAt: Value(now),
        ));
      });

  Future<void> _write(String id, HabitsCompanion changes) async {
    await (_db.update(_db.habits)..where((t) => t.id.equals(id)))
        .write(changes.copyWith(updatedAt: Value(_now())));
  }

  @override
  Future<void> archive(String id) =>
      _write(id, HabitsCompanion(archivedAt: Value(_now())));

  @override
  Future<void> unarchive(String id) =>
      _write(id, const HabitsCompanion(archivedAt: Value(null)));

  @override
  Future<void> delete(String id) =>
      _write(id, HabitsCompanion(deletedAt: Value(_now())));

  @override
  Future<void> restore(String id) =>
      _write(id, const HabitsCompanion(deletedAt: Value(null)));
}
