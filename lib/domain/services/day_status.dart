import '../../core/date_utils.dart';
import '../models/entry.dart';
import '../models/habit.dart';

enum DayStatus {
  /// Habit doesn't apply this day (unscheduled, before creation, archived).
  notTracked,

  /// Future day, or today with no progress yet. Never a miss.
  pending,

  /// Past scheduled day with no progress.
  missed,

  /// Some progress, goal not reached.
  partial,

  /// Goal reached.
  met,
}

DayStatus habitDayStatus({
  required Habit habit,
  required Entry? entry,
  required DateTime day,
  required DateTime today,
}) {
  final d = dateOnly(day);
  final t = dateOnly(today);
  if (!habit.isTrackedOn(d)) return DayStatus.notTracked;

  final live = (entry == null || entry.isDeleted) ? null : entry;
  if (live != null && live.isMet) return DayStatus.met;
  if (d.isAfter(t)) return DayStatus.pending;
  if (live != null && live.progress > 0) return DayStatus.partial;
  return d == t ? DayStatus.pending : DayStatus.missed;
}
