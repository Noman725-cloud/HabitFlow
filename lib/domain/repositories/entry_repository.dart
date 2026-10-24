import '../models/entry.dart';
import '../models/habit.dart';

abstract interface class EntryRepository {
  Stream<List<Entry>> watchForDate(String dateKey);

  /// Inclusive range of 'yyyy-MM-dd' keys.
  Stream<List<Entry>> watchRange(String startKey, String endKey);

  Stream<List<Entry>> watchForHabit(String habitId);

  /// Sets progress for [habit] on [date] (upsert; negative values clamp to 0).
  ///
  /// Target snapshot rule: a new entry snapshots [habit.targetValue]. An
  /// existing entry for a PAST day keeps its original target; an entry for
  /// TODAY refreshes to the current target (so editing a goal mid-day applies
  /// to today but never rewrites history). Future dates throw [ArgumentError].
  Future<void> setValue({
    required Habit habit,
    required String date,
    required int value,
  });
}
