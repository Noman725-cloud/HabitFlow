import '../../core/date_utils.dart';
import '../models/entry.dart';
import '../models/habit.dart';
import 'entry_index.dart';
import 'streak_calculator.dart';

class HabitOverview {
  const HabitOverview({
    required this.currentStreak,
    required this.bestStreak,
    required this.totalMet,
    required this.scheduledDays,
  });

  final int currentStreak;
  final int bestStreak;

  /// Scheduled days on which the goal was met.
  final int totalMet;

  /// Scheduled days so far. Today only counts if it is already met, so an
  /// unfinished today never lowers the rate.
  final int scheduledDays;

  double get completionRate => scheduledDays == 0 ? 0 : totalMet / scheduledDays;
}

class HabitOverviewCalculator {
  const HabitOverviewCalculator();

  HabitOverview calculate({
    required Habit habit,
    required Iterable<Entry> entries,
    required DateTime today,
  }) {
    final todayDate = dateOnly(today);
    final own = entries.where((e) => e.habitId == habit.id).toList();
    final index = EntryIndex(own);
    final streak = const StreakCalculator()
        .calculate(habit: habit, entries: own, today: todayDate);

    var floor = dateOnly(habit.createdAt);
    final earliest = index.earliestDate(habit.id);
    if (earliest != null && earliest.isBefore(floor)) floor = earliest;

    var scheduled = 0;
    var met = 0;
    for (var d = floor; !d.isAfter(todayDate); d = addDays(d, 1)) {
      if (!habit.isScheduledOn(d)) continue;
      final isMet = index.find(habit.id, toDateKey(d))?.isMet ?? false;
      if (isMet) {
        met++;
        scheduled++;
      } else if (d != todayDate) {
        scheduled++;
      }
    }

    return HabitOverview(
      currentStreak: streak.current,
      bestStreak: streak.best,
      totalMet: met,
      scheduledDays: scheduled,
    );
  }
}
