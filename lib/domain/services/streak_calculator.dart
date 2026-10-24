import '../../core/date_utils.dart';
import '../models/entry.dart';
import '../models/habit.dart';
import 'entry_index.dart';

class StreakResult {
  const StreakResult({required this.current, required this.best});
  final int current;
  final int best;
  static const zero = StreakResult(current: 0, best: 0);
}

/// Pure-Dart streak logic. Rules:
///
/// * Only scheduled days count; unscheduled days are skipped (neither extend
///   nor break a streak, even if an entry exists on one).
/// * A day is met when entry.value >= entry.target (the snapshot).
/// * A scheduled day with no entry, or partial progress, is a miss...
/// * ...except TODAY, which never breaks a streak while still in progress.
/// * History starts at the earlier of the habit's creation date and its
///   earliest entry (so backfilled days still count, but we never treat days
///   before the habit existed as misses).
/// * The current schedule is applied to all history (schedule edits are not
///   versioned). Documented limitation.
class StreakCalculator {
  const StreakCalculator();

  StreakResult calculate({
    required Habit habit,
    required Iterable<Entry> entries,
    required DateTime today,
  }) {
    final todayDate = dateOnly(today);
    final index = EntryIndex(entries.where((e) => e.habitId == habit.id));

    var floor = dateOnly(habit.createdAt);
    final earliest = index.earliestDate(habit.id);
    if (earliest != null && earliest.isBefore(floor)) floor = earliest;
    if (floor.isAfter(todayDate)) return StreakResult.zero;

    var run = 0;
    var best = 0;
    for (var d = floor; !d.isAfter(todayDate); d = addDays(d, 1)) {
      if (!habit.isScheduledOn(d)) continue;
      final met = index.find(habit.id, toDateKey(d))?.isMet ?? false;
      if (met) {
        run++;
        if (run > best) best = run;
      } else if (d != todayDate) {
        run = 0;
      }
      // Unmet today: leave `run` untouched (grace), it's still the current
      // streak as of yesterday.
    }
    return StreakResult(current: run, best: best);
  }
}
