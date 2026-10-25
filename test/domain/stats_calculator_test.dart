import 'package:flutter_test/flutter_test.dart';
import 'package:habitflow/domain/services/stats_calculator.dart';

import '../helpers.dart';

void main() {
  const calc = StatsCalculator();
  final weekStart = DateTime(2026, 10, 19); // Monday
  final today = DateTime(2026, 10, 24, 12); // Saturday

  final check = makeHabit(id: 'a');
  final water = makeHabit(id: 'b', target: 8);

  final entries = [
    makeEntry(habitId: 'a', day: 19),
    makeEntry(habitId: 'b', day: 19, value: 8, target: 8),
    makeEntry(habitId: 'a', day: 20),
    makeEntry(habitId: 'b', day: 20, value: 4, target: 8),
  ];

  WeeklyStats weekly({List? habits, List? es}) => calc.weekly(
        habits: (habits ?? [check, water]).cast(),
        entries: (es ?? entries).cast(),
        weekStart: weekStart,
        today: today,
      );

  test('per-day counts and progress', () {
    final s = weekly();
    expect(s.days, hasLength(7));
    expect(s.days[0].scheduled, 2);
    expect(s.days[0].met, 2);
    expect(s.days[1].met, 1);
    expect(s.days[1].progress, closeTo(0.75, 1e-9)); // (1 + 0.5) / 2
  });

  test('future days have nothing scheduled', () {
    final s = weekly();
    expect(s.days[6].scheduled, 0); // Sunday 25th, after "today"
    expect(s.days[6].completionRate, 0);
  });

  test('overall rate is goals met / goals scheduled', () {
    final s = weekly();
    expect(s.scheduled, 12); // 2 habits x Mon..Sat
    expect(s.met, 3);
    expect(s.completionRate, closeTo(0.25, 1e-9));
  });

  test('per-habit breakdown', () {
    final s = weekly();
    final a = s.habits.firstWhere((h) => h.habitId == 'a');
    final b = s.habits.firstWhere((h) => h.habitId == 'b');
    expect(a.scheduled, 6);
    expect(a.met, 2);
    expect(a.completionRate, closeTo(1 / 3, 1e-9));
    expect(b.met, 1);
    expect(b.averageProgress, closeTo((1 + 0.5) / 6, 1e-9));
  });

  test('best day is the highest completion rate (earliest wins ties)', () {
    expect(weekly().bestDay!.date, DateTime(2026, 10, 19));
  });

  test('bestDay is null when nothing is scheduled', () {
    expect(weekly(habits: [], es: []).bestDay, isNull);
  });

  test('respects schedule, creation date, archive and deletion', () {
    final weekdays = makeHabit(id: 'w', days: {1, 2, 3, 4, 5});
    final late = makeHabit(id: 'l', createdAt: DateTime(2026, 10, 22));
    final archived = makeHabit(id: 'x', archivedAt: DateTime(2026, 10, 21));
    final deleted = makeHabit(id: 'd', deletedAt: DateTime(2026, 10, 20));

    final s = weekly(habits: [weekdays, late, archived, deleted], es: []);
    final by = {for (final h in s.habits) h.habitId: h};

    expect(by['w']!.scheduled, 5); // Mon-Fri
    expect(by['l']!.scheduled, 3); // Thu, Fri, Sat
    expect(by['x']!.scheduled, 2); // Mon, Tue (archived on Wed)
    expect(by.containsKey('d'), isFalse);
  });

  test('over-achievement does not inflate average progress', () {
    final s = weekly(
      habits: [water],
      es: [makeEntry(habitId: 'b', day: 19, value: 16, target: 8)],
    );
    expect(s.days[0].progress, 1.0);
  });

  group('forDay', () {
    test('counts met and scheduled for one day', () {
      final d = calc.forDay(
        habits: [check, water],
        entries: entries,
        date: DateTime(2026, 10, 20),
        today: today,
      );
      expect(d.scheduled, 2);
      expect(d.met, 1); // water is 4/8 on the 20th
      expect(d.progress, closeTo(0.75, 1e-9));
    });

    test('future days have nothing scheduled', () {
      final d = calc.forDay(
        habits: [check],
        entries: const [],
        date: DateTime(2026, 10, 25),
        today: today,
      );
      expect(d.scheduled, 0);
    });
  });

  group('forMonth', () {
    test('returns one entry per day of the month', () {
      final days = calc.forMonth(
        habits: [check, water],
        entries: entries,
        month: DateTime(2026, 10),
        today: today,
      );
      expect(days, hasLength(31));
      expect(days[0].scheduled, 2); // Oct 1, habits created that day
      expect(days[0].met, 0);
      expect(days[18].met, 2); // Oct 19
      expect(days[19].met, 1); // Oct 20
      expect(days[24].scheduled, 0); // Oct 25 is in the future
    });

    test('handles February in a non-leap year', () {
      final days = calc.forMonth(
        habits: const [],
        entries: const [],
        month: DateTime(2027, 2),
        today: DateTime(2027, 3, 1),
      );
      expect(days, hasLength(28));
    });
  });
}
