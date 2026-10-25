import 'dart:math' as math;

import '../../core/date_utils.dart';
import '../models/entry.dart';
import '../models/habit.dart';
import 'entry_index.dart';

class DayStats {
  const DayStats({
    required this.date,
    required this.scheduled,
    required this.met,
    required this.progress,
  });

  final DateTime date;

  /// Habits that were due this day (0 for future days).
  final int scheduled;
  final int met;

  /// Mean of per-habit progress (each clamped to 0..1). 0 if nothing due.
  final double progress;

  double get completionRate => scheduled == 0 ? 0 : met / scheduled;
}

class HabitWeekStats {
  const HabitWeekStats({
    required this.habitId,
    required this.scheduled,
    required this.met,
    required this.averageProgress,
  });

  final String habitId;
  final int scheduled;
  final int met;
  final double averageProgress;

  double get completionRate => scheduled == 0 ? 0 : met / scheduled;
}

class WeeklyStats {
  const WeeklyStats({
    required this.weekStart,
    required this.days,
    required this.habits,
  });

  final DateTime weekStart;
  final List<DayStats> days;
  final List<HabitWeekStats> habits;

  int get scheduled => days.fold(0, (s, d) => s + d.scheduled);
  int get met => days.fold(0, (s, d) => s + d.met);
  double get completionRate => scheduled == 0 ? 0 : met / scheduled;

  /// Day with the highest completion rate (earliest wins ties); null if
  /// nothing was due this week.
  DayStats? get bestDay {
    DayStats? best;
    for (final d in days) {
      if (d.scheduled == 0) continue;
      if (best == null || d.completionRate > best.completionRate) best = d;
    }
    return best;
  }
}

class StatsCalculator {
  const StatsCalculator();

  /// Headline metric is "goals met" (met / scheduled). Average progress is
  /// reported alongside so partial effort is visible.
  ///
  /// A habit is tracked on a day if it isn't deleted, the day is on/after its
  /// creation date, before its archive date, not in the future, and the day
  /// is in its schedule.
  WeeklyStats weekly({
    required Iterable<Habit> habits,
    required Iterable<Entry> entries,
    required DateTime weekStart,
    required DateTime today,
  }) {
    final start = dateOnly(weekStart);
    final todayDate = dateOnly(today);
    final index = EntryIndex(entries);
    final live = habits.where((h) => !h.isDeleted).toList();

    final perHabit = <String, _Acc>{for (final h in live) h.id: _Acc()};
    final days = <DayStats>[];

    for (var i = 0; i < 7; i++) {
      final day = addDays(start, i);
      final key = toDateKey(day);
      var scheduled = 0;
      var met = 0;
      var progressSum = 0.0;

      for (final h in live) {
        if (!_isTracked(h, day, todayDate)) continue;
        final entry = index.find(h.id, key);
        final p = entry?.progress ?? 0.0;
        final isMet = entry?.isMet ?? false;
        scheduled++;
        progressSum += p;
        if (isMet) met++;
        final acc = perHabit[h.id]!;
        acc.scheduled++;
        acc.progress += p;
        if (isMet) acc.met++;
      }

      days.add(DayStats(
        date: day,
        scheduled: scheduled,
        met: met,
        progress: scheduled == 0 ? 0 : progressSum / scheduled,
      ));
    }

    return WeeklyStats(
      weekStart: start,
      days: days,
      habits: [
        for (final h in live)
          HabitWeekStats(
            habitId: h.id,
            scheduled: perHabit[h.id]!.scheduled,
            met: perHabit[h.id]!.met,
            averageProgress: perHabit[h.id]!.scheduled == 0
                ? 0
                : math.min(
                    1.0,
                    perHabit[h.id]!.progress / perHabit[h.id]!.scheduled,
                  ),
          ),
      ],
    );
  }

  /// One [DayStats] per day of [month] (index 0 = the 1st).
  List<DayStats> forMonth({
    required Iterable<Habit> habits,
    required Iterable<Entry> entries,
    required DateTime month,
    required DateTime today,
  }) {
    final first = DateTime(month.year, month.month, 1);
    final count = DateTime(month.year, month.month + 1, 0).day;
    final habitList = habits.toList();
    final entryList = entries.toList();
    return [
      for (var i = 0; i < count; i++)
        forDay(
          habits: habitList,
          entries: entryList,
          date: addDays(first, i),
          today: today,
        ),
    ];
  }

  /// Stats for a single day (used by the Today summary). Same tracking rules
  /// as [weekly].
  DayStats forDay({
    required Iterable<Habit> habits,
    required Iterable<Entry> entries,
    required DateTime date,
    required DateTime today,
  }) {
    final d = dateOnly(date);
    final todayDate = dateOnly(today);
    final key = toDateKey(d);
    final index = EntryIndex(entries);
    var scheduled = 0;
    var met = 0;
    var progressSum = 0.0;
    for (final h in habits) {
      if (h.isDeleted || !_isTracked(h, d, todayDate)) continue;
      final entry = index.find(h.id, key);
      scheduled++;
      progressSum += entry?.progress ?? 0.0;
      if (entry?.isMet ?? false) met++;
    }
    return DayStats(
      date: d,
      scheduled: scheduled,
      met: met,
      progress: scheduled == 0 ? 0 : progressSum / scheduled,
    );
  }

  bool _isTracked(Habit h, DateTime day, DateTime today) =>
      !day.isAfter(today) && h.isTrackedOn(day);
}

class _Acc {
  int scheduled = 0;
  int met = 0;
  double progress = 0;
}
