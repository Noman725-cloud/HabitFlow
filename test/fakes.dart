import 'package:habitflow/domain/models/entry.dart';
import 'package:habitflow/domain/models/habit.dart';
import 'package:habitflow/domain/repositories/entry_repository.dart';
import 'package:habitflow/domain/repositories/habit_repository.dart';

/// In-memory repositories for widget tests. Streams emit once (no live
/// updates), which keeps widget tests free of database timers.
class FakeHabitRepository implements HabitRepository {
  FakeHabitRepository([Iterable<Habit> initial = const []])
      : habits = [...initial];

  final List<Habit> habits;

  @override
  Stream<List<Habit>> watchActive() => Stream.value(
        habits.where((h) => !h.isDeleted && !h.isArchived).toList(),
      );

  @override
  Stream<List<Habit>> watchAll() =>
      Stream.value(habits.where((h) => !h.isDeleted).toList());

  @override
  Stream<List<Habit>> watchArchived() => Stream.value(
        habits.where((h) => !h.isDeleted && h.isArchived).toList(),
      );

  @override
  Future<Habit?> getById(String id) async {
    for (final h in habits) {
      if (h.id == id) return h;
    }
    return null;
  }

  @override
  Future<void> create(Habit habit) async => habits.add(habit);

  @override
  Future<void> update(Habit habit) async {
    final i = habits.indexWhere((h) => h.id == habit.id);
    if (i >= 0) habits[i] = habit;
  }

  Future<void> _mutate(String id, Habit Function(Habit) change) async {
    final i = habits.indexWhere((h) => h.id == id);
    if (i >= 0) habits[i] = change(habits[i]);
  }

  @override
  Future<void> archive(String id) =>
      _mutate(id, (h) => h.copyWith(archivedAt: () => DateTime.now()));

  @override
  Future<void> unarchive(String id) =>
      _mutate(id, (h) => h.copyWith(archivedAt: () => null));

  @override
  Future<void> delete(String id) =>
      _mutate(id, (h) => h.copyWith(deletedAt: () => DateTime.now()));

  @override
  Future<void> restore(String id) =>
      _mutate(id, (h) => h.copyWith(deletedAt: () => null));
}

class FakeEntryRepository implements EntryRepository {
  FakeEntryRepository([Iterable<Entry> initial = const []])
      : entries = [...initial];

  final List<Entry> entries;

  /// Every setValue call, in order, for assertions.
  final List<({String habitId, String date, int value})> calls = [];

  @override
  Stream<List<Entry>> watchForDate(String dateKey) =>
      Stream.value(entries.where((e) => e.date == dateKey).toList());

  @override
  Stream<List<Entry>> watchRange(String startKey, String endKey) => Stream.value(
        entries
            .where((e) => e.date.compareTo(startKey) >= 0 &&
                e.date.compareTo(endKey) <= 0)
            .toList(),
      );

  @override
  Stream<List<Entry>> watchForHabit(String habitId) =>
      Stream.value(entries.where((e) => e.habitId == habitId).toList());

  @override
  Future<void> setValue({
    required Habit habit,
    required String date,
    required int value,
  }) async {
    calls.add((habitId: habit.id, date: date, value: value));
  }
}
