import 'package:habitflow/domain/models/entry.dart';
import 'package:habitflow/domain/models/habit.dart';

Habit makeHabit({
  String id = 'h1',
  Set<int> days = Habit.everyDay,
  int target = 1,
  DateTime? createdAt,
  DateTime? archivedAt,
  DateTime? deletedAt,
}) {
  final created = createdAt ?? DateTime(2026, 10, 1);
  return Habit(
    id: id,
    name: 'Habit $id',
    iconKey: 'star',
    colorValue: 0xFF4F46E5,
    scheduleDays: days,
    targetValue: target,
    createdAt: created,
    updatedAt: created,
    archivedAt: archivedAt,
    deletedAt: deletedAt,
  );
}

/// [day] is the day of October 2026 unless [month] is given.
Entry makeEntry({
  String habitId = 'h1',
  required int day,
  int month = 10,
  int value = 1,
  int target = 1,
  bool deleted = false,
}) {
  final mm = month.toString().padLeft(2, '0');
  final dd = day.toString().padLeft(2, '0');
  return Entry(
    id: '$habitId-$mm-$dd',
    habitId: habitId,
    date: '2026-$mm-$dd',
    value: value,
    target: target,
    updatedAt: DateTime(2026, month, day, 12),
    deletedAt: deleted ? DateTime(2026, month, day, 13) : null,
  );
}
