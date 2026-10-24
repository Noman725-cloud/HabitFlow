import 'package:drift/drift.dart';

import '../../domain/models/entry.dart';
import '../../domain/models/habit.dart';
import '../database/app_database.dart';

int scheduleToMask(Set<int> days) =>
    days.fold(0, (mask, d) => mask | (1 << (d - 1)));

Set<int> maskToSchedule(int mask) => {
      for (var d = 1; d <= 7; d++)
        if ((mask & (1 << (d - 1))) != 0) d,
    };

extension HabitRowMapper on HabitRow {
  Habit toDomain() => Habit(
        id: id,
        name: name,
        iconKey: iconKey,
        colorValue: colorValue,
        scheduleDays: maskToSchedule(scheduleMask),
        targetValue: targetValue,
        unit: unit,
        step: step,
        createdAt: createdAt,
        updatedAt: updatedAt,
        archivedAt: archivedAt,
        deletedAt: deletedAt,
      );
}

extension HabitMapper on Habit {
  HabitsCompanion toCompanion() => HabitsCompanion(
        id: Value(id),
        name: Value(name),
        iconKey: Value(iconKey),
        colorValue: Value(colorValue),
        scheduleMask: Value(scheduleToMask(scheduleDays)),
        targetValue: Value(targetValue),
        unit: Value(unit),
        step: Value(step),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
        archivedAt: Value(archivedAt),
        deletedAt: Value(deletedAt),
      );
}

extension EntryRowMapper on EntryRow {
  Entry toDomain() => Entry(
        id: id,
        habitId: habitId,
        date: date,
        value: value,
        target: target,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
      );
}
