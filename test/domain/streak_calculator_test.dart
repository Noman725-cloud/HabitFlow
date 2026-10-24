import 'package:flutter_test/flutter_test.dart';
import 'package:habitflow/domain/models/entry.dart';
import 'package:habitflow/domain/models/habit.dart';
import 'package:habitflow/domain/services/streak_calculator.dart';

import '../helpers.dart';

void main() {
  const calc = StreakCalculator();
  // Saturday, 24 Oct 2026.
  final today = DateTime(2026, 10, 24, 15, 30);

  StreakResult run(Habit habit, List<Entry> entries, {DateTime? at}) =>
      calc.calculate(habit: habit, entries: entries, today: at ?? today);

  test('no entries -> 0 / 0', () {
    final r = run(makeHabit(), []);
    expect(r.current, 0);
    expect(r.best, 0);
  });

  test('consecutive days ending today', () {
    final r = run(makeHabit(), [
      makeEntry(day: 22),
      makeEntry(day: 23),
      makeEntry(day: 24),
    ]);
    expect(r.current, 3);
    expect(r.best, 3);
  });

  test('today still in progress does not break the streak', () {
    final r = run(makeHabit(), [makeEntry(day: 22), makeEntry(day: 23)]);
    expect(r.current, 2);
  });

  test('partial progress today does not break the streak', () {
    final habit = makeHabit(target: 8);
    final r = run(habit, [
      makeEntry(day: 22, value: 8, target: 8),
      makeEntry(day: 23, value: 8, target: 8),
      makeEntry(day: 24, value: 5, target: 8),
    ]);
    expect(r.current, 2);
  });

  test('a missed past day breaks the streak', () {
    final r = run(makeHabit(), [makeEntry(day: 22), makeEntry(day: 24)]);
    expect(r.current, 1); // 23rd missed
  });

  test('missed yesterday and nothing today -> current 0', () {
    final r = run(makeHabit(), [makeEntry(day: 22)]);
    expect(r.current, 0);
    expect(r.best, 1);
  });

  test('partial progress on a past day counts as a miss', () {
    final habit = makeHabit(target: 8);
    final r = run(habit, [
      makeEntry(day: 22, value: 8, target: 8),
      makeEntry(day: 23, value: 5, target: 8),
      makeEntry(day: 24, value: 8, target: 8),
    ]);
    expect(r.current, 1);
  });

  test('unscheduled days are skipped, not misses', () {
    // Mon-Fri habit; today is Monday 26 Oct. Weekend 24-25 is skipped.
    final habit = makeHabit(days: {1, 2, 3, 4, 5});
    final r = run(
      habit,
      [makeEntry(day: 22), makeEntry(day: 23), makeEntry(day: 26)],
      at: DateTime(2026, 10, 26, 9),
    );
    expect(r.current, 3);
  });

  test('today unscheduled, previous scheduled days met', () {
    // Today is Saturday; habit is Mon-Fri.
    final habit = makeHabit(days: {1, 2, 3, 4, 5});
    final r = run(habit, [makeEntry(day: 22), makeEntry(day: 23)]);
    expect(r.current, 2);
  });

  test('entry on an unscheduled day does not extend the streak', () {
    final habit = makeHabit(days: {1, 2, 3, 4, 5});
    final r = run(habit, [makeEntry(day: 23), makeEntry(day: 24)]);
    expect(r.current, 1); // Fri 23 only; Sat 24 unscheduled
  });

  test('over-achievement counts as met', () {
    final habit = makeHabit(target: 8);
    final r = run(habit, [makeEntry(day: 24, value: 12, target: 8)]);
    expect(r.current, 1);
  });

  test('target snapshot protects history after the goal changes', () {
    // Habit goal was raised to 10, but yesterday was logged against 8.
    final habit = makeHabit(target: 10);
    final r = run(habit, [
      makeEntry(day: 23, value: 8, target: 8),
      makeEntry(day: 24, value: 10, target: 10),
    ]);
    expect(r.current, 2);
  });

  test('best streak can exceed current', () {
    final r = run(makeHabit(), [
      for (var d = 1; d <= 5; d++) makeEntry(day: d),
      makeEntry(day: 7),
    ]);
    expect(r.best, 5);
    expect(r.current, 0);
  });

  test('soft-deleted entries are ignored', () {
    final r = run(makeHabit(), [
      makeEntry(day: 23),
      makeEntry(day: 24, deleted: true),
    ]);
    expect(r.current, 1);
  });

  test('entries from other habits are ignored', () {
    final r = run(makeHabit(), [
      makeEntry(habitId: 'other', day: 23),
      makeEntry(habitId: 'other', day: 24),
    ]);
    expect(r.current, 0);
  });

  test('days before creation are not misses', () {
    final habit = makeHabit(createdAt: DateTime(2026, 10, 22));
    final r = run(habit, [
      makeEntry(day: 22),
      makeEntry(day: 23),
      makeEntry(day: 24),
    ]);
    expect(r.current, 3);
  });

  test('backfilled entries before creation date still count', () {
    final habit = makeHabit(createdAt: DateTime(2026, 10, 24));
    final r = run(habit, [
      makeEntry(day: 22),
      makeEntry(day: 23),
      makeEntry(day: 24),
    ]);
    expect(r.current, 3);
  });

  test('streak crosses a month boundary', () {
    final r = run(
      makeHabit(createdAt: DateTime(2026, 9, 1)),
      [
        makeEntry(month: 9, day: 29),
        makeEntry(month: 9, day: 30),
        makeEntry(day: 1),
        makeEntry(day: 2),
      ],
      at: DateTime(2026, 10, 2, 8),
    );
    expect(r.current, 4);
  });

  test('retroactively filling a gap repairs the streak', () {
    final habit = makeHabit();
    final before = run(habit, [makeEntry(day: 22), makeEntry(day: 24)]);
    final after = run(habit, [
      makeEntry(day: 22),
      makeEntry(day: 23),
      makeEntry(day: 24),
    ]);
    expect(before.current, 1);
    expect(after.current, 3);
  });
}
