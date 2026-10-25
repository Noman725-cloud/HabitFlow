import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitflow/data/database/app_database.dart';
import 'package:habitflow/data/repositories/drift_entry_repository.dart';
import 'package:habitflow/data/repositories/drift_habit_repository.dart';
import 'package:habitflow/domain/models/habit.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late DriftHabitRepository habits;
  late DriftEntryRepository entries;
  final now = DateTime(2026, 10, 24, 9);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    habits = DriftHabitRepository(db, now: () => now);
    entries = DriftEntryRepository(db, now: () => now);
  });

  tearDown(() => db.close());

  test('create, read back, schedule bitmask round-trips', () async {
    final h = makeHabit(days: {1, 3, 7}, target: 8);
    await habits.create(h);
    final loaded = await habits.getById(h.id);
    expect(loaded!.scheduleDays, {1, 3, 7});
    expect(loaded.targetValue, 8);
    expect(loaded.unit, isNull);
  });

  test('update can clear a nullable field', () async {
    final h = makeHabit().copyWith(unit: () => 'glasses');
    await habits.create(h);
    await habits.update(h.copyWith(unit: () => null));
    expect((await habits.getById(h.id))!.unit, isNull);
  });

  test('soft delete hides from watchActive; restore brings it back', () async {
    final h = makeHabit();
    await habits.create(h);
    expect(await habits.watchActive().first, hasLength(1));

    await habits.delete(h.id);
    expect(await habits.watchActive().first, isEmpty);
    expect((await habits.getById(h.id))!.isDeleted, isTrue);

    await habits.restore(h.id);
    expect(await habits.watchActive().first, hasLength(1));
  });

  test('archive hides from watchActive', () async {
    final h = makeHabit();
    await habits.create(h);
    await habits.archive(h.id);
    expect(await habits.watchActive().first, isEmpty);
    await habits.unarchive(h.id);
    expect(await habits.watchActive().first, hasLength(1));
  });

  test('setValue upserts one row per habit per day', () async {
    final h = makeHabit(target: 8);
    await habits.create(h);
    await entries.setValue(habit: h, date: '2026-10-24', value: 3);
    await entries.setValue(habit: h, date: '2026-10-24', value: 5);

    final list = await entries.watchForHabit(h.id).first;
    expect(list, hasLength(1));
    expect(list.single.value, 5);
    expect(list.single.target, 8);
  });

  test('negative values clamp to zero', () async {
    final h = makeHabit();
    await habits.create(h);
    await entries.setValue(habit: h, date: '2026-10-24', value: -4);
    expect((await entries.watchForHabit(h.id).first).single.value, 0);
  });

  test('future dates are rejected', () async {
    final h = makeHabit();
    await habits.create(h);
    expect(
      () => entries.setValue(habit: h, date: '2026-10-25', value: 1),
      throwsArgumentError,
    );
  });

  test('past entries keep their target; today refreshes it', () async {
    final h = makeHabit(target: 8);
    await habits.create(h);
    await entries.setValue(habit: h, date: '2026-10-23', value: 8);
    await entries.setValue(habit: h, date: '2026-10-24', value: 4);

    final raised = h.copyWith(targetValue: 10);
    await habits.update(raised);
    await entries.setValue(habit: raised, date: '2026-10-23', value: 9);
    await entries.setValue(habit: raised, date: '2026-10-24', value: 9);

    final byDate = {
      for (final e in await entries.watchForHabit(h.id).first) e.date: e,
    };
    expect(byDate['2026-10-23']!.target, 8);
    expect(byDate['2026-10-23']!.isMet, isTrue);
    expect(byDate['2026-10-24']!.target, 10);
    expect(byDate['2026-10-24']!.isMet, isFalse);
  });

  test('habit update refreshes today\'s entry target, not past ones', () async {
    final h = makeHabit(target: 8);
    await habits.create(h);
    await entries.setValue(habit: h, date: '2026-10-23', value: 8);
    await entries.setValue(habit: h, date: '2026-10-24', value: 8);

    await habits.update(h.copyWith(targetValue: 10));

    final byDate = {
      for (final e in await entries.watchForHabit(h.id).first) e.date: e,
    };
    expect(byDate['2026-10-23']!.target, 8);
    expect(byDate['2026-10-24']!.target, 10);
    expect(byDate['2026-10-24']!.isMet, isFalse);
  });

  test('watchAll includes archived but not deleted; watchArchived filters',
      () async {
    final a = makeHabit(id: 'a');
    final b = makeHabit(id: 'b');
    final c = makeHabit(id: 'c');
    for (final h in [a, b, c]) {
      await habits.create(h);
    }
    await habits.archive('b');
    await habits.delete('c');

    expect((await habits.watchAll().first).map((h) => h.id), ['a', 'b']);
    expect((await habits.watchArchived().first).map((h) => h.id), ['b']);
    expect((await habits.watchActive().first).map((h) => h.id), ['a']);
  });

  test('watchRange is inclusive and watchForDate filters', () async {
    final h = makeHabit();
    await habits.create(h);
    for (final d in ['2026-10-20', '2026-10-21', '2026-10-22']) {
      await entries.setValue(habit: h, date: d, value: 1);
    }
    expect(await entries.watchRange('2026-10-20', '2026-10-21').first,
        hasLength(2));
    expect(await entries.watchForDate('2026-10-22').first, hasLength(1));
  });

  test('foreign key blocks entries for unknown habits', () async {
    final ghost = Habit(
      id: 'ghost',
      name: 'Ghost',
      iconKey: 'x',
      colorValue: 0,
      scheduleDays: Habit.everyDay,
      createdAt: now,
      updatedAt: now,
    );
    expect(
      () => entries.setValue(habit: ghost, date: '2026-10-24', value: 1),
      throwsA(anything),
    );
  });
}
