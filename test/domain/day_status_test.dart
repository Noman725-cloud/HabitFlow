import 'package:flutter_test/flutter_test.dart';
import 'package:habitflow/domain/services/day_status.dart';

import '../helpers.dart';

void main() {
  final today = DateTime(2026, 10, 24, 18); // Saturday
  final habit = makeHabit(target: 8);

  DayStatus status(DateTime day, {entry, h}) => habitDayStatus(
        habit: h ?? habit,
        entry: entry,
        day: day,
        today: today,
      );

  test('met when the goal is reached', () {
    expect(
      status(DateTime(2026, 10, 20),
          entry: makeEntry(day: 20, value: 8, target: 8)),
      DayStatus.met,
    );
  });

  test('partial when there is progress but the goal is not reached', () {
    expect(
      status(DateTime(2026, 10, 20),
          entry: makeEntry(day: 20, value: 3, target: 8)),
      DayStatus.partial,
    );
  });

  test('missed for a past scheduled day with no progress', () {
    expect(status(DateTime(2026, 10, 20)), DayStatus.missed);
    expect(
      status(DateTime(2026, 10, 20),
          entry: makeEntry(day: 20, value: 0, target: 8)),
      DayStatus.missed,
    );
  });

  test('today with no progress is pending, never missed', () {
    expect(status(DateTime(2026, 10, 24)), DayStatus.pending);
  });

  test('today with progress or a met goal is reflected', () {
    expect(
      status(DateTime(2026, 10, 24),
          entry: makeEntry(day: 24, value: 2, target: 8)),
      DayStatus.partial,
    );
    expect(
      status(DateTime(2026, 10, 24),
          entry: makeEntry(day: 24, value: 8, target: 8)),
      DayStatus.met,
    );
  });

  test('future days are pending', () {
    expect(status(DateTime(2026, 10, 25)), DayStatus.pending);
  });

  test('unscheduled weekday is not tracked', () {
    final weekdays = makeHabit(days: {1, 2, 3, 4, 5});
    expect(status(DateTime(2026, 10, 18), h: weekdays), DayStatus.notTracked);
  });

  test('days before creation are not tracked', () {
    expect(status(DateTime(2026, 9, 30)), DayStatus.notTracked);
  });

  test('archived habits stop counting from the archive date', () {
    final archived = makeHabit(archivedAt: DateTime(2026, 10, 21));
    expect(status(DateTime(2026, 10, 20), h: archived), DayStatus.missed);
    expect(status(DateTime(2026, 10, 22), h: archived), DayStatus.notTracked);
  });

  test('soft-deleted entries are ignored', () {
    expect(
      status(DateTime(2026, 10, 20),
          entry: makeEntry(day: 20, value: 8, target: 8, deleted: true)),
      DayStatus.missed,
    );
  });

  test('Habit.isTrackedOn is false for deleted habits', () {
    final deleted = makeHabit(deletedAt: DateTime(2026, 10, 10));
    expect(deleted.isTrackedOn(DateTime(2026, 10, 5)), isFalse);
  });
}
