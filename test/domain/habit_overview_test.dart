import 'package:flutter_test/flutter_test.dart';
import 'package:habitflow/domain/services/habit_overview.dart';

import '../helpers.dart';

void main() {
  const calc = HabitOverviewCalculator();
  final today = DateTime(2026, 10, 24, 12); // Saturday
  final habit = makeHabit(createdAt: DateTime(2026, 10, 20));

  test('rate ignores an unfinished today', () {
    final o = calc.calculate(
      habit: habit,
      entries: [makeEntry(day: 20), makeEntry(day: 21), makeEntry(day: 22)],
      today: today,
    );
    expect(o.totalMet, 3);
    expect(o.scheduledDays, 4); // 20, 21, 22, 23 (today not counted yet)
    expect(o.completionRate, closeTo(0.75, 1e-9));
    expect(o.currentStreak, 0); // 23rd was missed
    expect(o.bestStreak, 3);
  });

  test('a met today counts as scheduled and extends the streak', () {
    final o = calc.calculate(
      habit: habit,
      entries: [
        makeEntry(day: 20),
        makeEntry(day: 21),
        makeEntry(day: 22),
        makeEntry(day: 24),
      ],
      today: today,
    );
    expect(o.totalMet, 4);
    expect(o.scheduledDays, 5);
    expect(o.completionRate, closeTo(0.8, 1e-9));
    expect(o.currentStreak, 1);
  });

  test('brand new habit has a zero rate, not a division error', () {
    final fresh = makeHabit(createdAt: DateTime(2026, 10, 24));
    final o = calc.calculate(habit: fresh, entries: const [], today: today);
    expect(o.scheduledDays, 0);
    expect(o.completionRate, 0);
  });

  test('ignores other habits entries', () {
    final o = calc.calculate(
      habit: habit,
      entries: [makeEntry(habitId: 'other', day: 22)],
      today: today,
    );
    expect(o.totalMet, 0);
  });
}
