import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/date_utils.dart';
import '../data/database/app_database.dart';
import '../data/repositories/drift_entry_repository.dart';
import '../data/repositories/drift_habit_repository.dart';
import '../domain/models/entry.dart';
import '../domain/models/habit.dart';
import '../domain/repositories/entry_repository.dart';
import '../domain/repositories/habit_repository.dart';

/// Overridden in main() with the real instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override sharedPreferencesProvider'),
);

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final habitRepositoryProvider = Provider<HabitRepository>(
  (ref) => DriftHabitRepository(ref.watch(databaseProvider)),
);

final entryRepositoryProvider = Provider<EntryRepository>(
  (ref) => DriftEntryRepository(ref.watch(databaseProvider)),
);

// ---------------------------------------------------------------- theme

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'themeMode';

  @override
  ThemeMode build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(_key);
    return ThemeMode.values.asNameMap()[saved] ?? ThemeMode.system;
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_key, mode.name);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

// ---------------------------------------------------------------- today

/// The current local calendar date (midnight). Rolls over at midnight and
/// when the app returns to the foreground (see HabitFlowApp).
class TodayNotifier extends Notifier<DateTime> {
  Timer? _timer;

  @override
  DateTime build() {
    ref.onDispose(() => _timer?.cancel());
    final now = DateTime.now();
    _schedule(now);
    return dateOnly(now);
  }

  void _schedule(DateTime now) {
    _timer?.cancel();
    final nextMidnight = addDays(dateOnly(now), 1);
    _timer = Timer(
      nextMidnight.difference(now) + const Duration(seconds: 1),
      refresh,
    );
  }

  void refresh() {
    final now = DateTime.now();
    final today = dateOnly(now);
    if (today != state) state = today;
    _schedule(now);
  }
}

final todayProvider =
    NotifierProvider<TodayNotifier, DateTime>(TodayNotifier.new);

// ----------------------------------------------------------------- data

final activeHabitsProvider = StreamProvider<List<Habit>>(
  (ref) => ref.watch(habitRepositoryProvider).watchActive(),
);

final entriesForDateProvider =
    StreamProvider.family<List<Entry>, String>((ref, dateKey) {
  return ref.watch(entryRepositoryProvider).watchForDate(dateKey);
});

final entriesForHabitProvider =
    StreamProvider.family<List<Entry>, String>((ref, habitId) {
  return ref.watch(entryRepositoryProvider).watchForHabit(habitId);
});

extension AsyncListOrEmpty<T> on AsyncValue<List<T>> {
  /// The list, or empty while loading / on error.
  List<T> get orEmpty => when(
        data: (d) => d,
        loading: () => <T>[],
        error: (_, _) => <T>[],
      );
}

// ------------------------------------------------------------ phase 3

/// All non-deleted habits, including archived (history needs them).
final allHabitsProvider = StreamProvider<List<Habit>>(
  (ref) => ref.watch(habitRepositoryProvider).watchAll(),
);

final archivedHabitsProvider = StreamProvider<List<Habit>>(
  (ref) => ref.watch(habitRepositoryProvider).watchArchived(),
);

/// Entries for a calendar month. Key must be the first day of the month.
final entriesForMonthProvider =
    StreamProvider.family<List<Entry>, DateTime>((ref, month) {
  final first = DateTime(month.year, month.month, 1);
  final last = DateTime(month.year, month.month + 1, 0);
  return ref
      .watch(entryRepositoryProvider)
      .watchRange(toDateKey(first), toDateKey(last));
});

/// First day of the week: 1 = Monday .. 7 = Sunday.
class WeekStartNotifier extends Notifier<int> {
  static const _key = 'weekStartDay';

  @override
  int build() {
    final saved = ref.watch(sharedPreferencesProvider).getInt(_key);
    return (saved != null && saved >= 1 && saved <= 7)
        ? saved
        : DateTime.monday;
  }

  Future<void> set(int day) async {
    state = day;
    await ref.read(sharedPreferencesProvider).setInt(_key, day);
  }
}

final weekStartProvider =
    NotifierProvider<WeekStartNotifier, int>(WeekStartNotifier.new);

/// Entries for the 7 days starting at [weekStart] (a local midnight).
final entriesForWeekProvider =
    StreamProvider.family<List<Entry>, DateTime>((ref, weekStart) {
  return ref
      .watch(entryRepositoryProvider)
      .watchRange(toDateKey(weekStart), toDateKey(addDays(weekStart, 6)));
});
