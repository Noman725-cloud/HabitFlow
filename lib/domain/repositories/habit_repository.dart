import '../models/habit.dart';

abstract interface class HabitRepository {
  /// Non-deleted, non-archived habits, oldest first.
  Stream<List<Habit>> watchActive();

  /// Every non-deleted habit INCLUDING archived ones (needed for history).
  Stream<List<Habit>> watchAll();

  /// Archived, non-deleted habits, most recently archived first.
  Stream<List<Habit>> watchArchived();

  Future<Habit?> getById(String id);

  Future<void> create(Habit habit);
  Future<void> update(Habit habit);

  Future<void> archive(String id);
  Future<void> unarchive(String id);

  /// Soft delete (tombstone). Entries are kept so the delete can be undone.
  Future<void> delete(String id);
  Future<void> restore(String id);
}
