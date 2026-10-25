import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitflow/app/app.dart';
import 'package:habitflow/app/providers.dart';
import 'package:habitflow/core/date_utils.dart';
import 'package:habitflow/domain/models/entry.dart';
import 'package:habitflow/domain/models/habit.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';
import 'helpers.dart';

Future<SharedPreferences> _pumpApp(
  WidgetTester tester, {
  List<Habit> habits = const [],
  FakeEntryRepository? entryRepo,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        habitRepositoryProvider.overrideWithValue(FakeHabitRepository(habits)),
        entryRepositoryProvider
            .overrideWithValue(entryRepo ?? FakeEntryRepository()),
      ],
      child: const HabitFlowApp(),
    ),
  );
  await tester.pumpAndSettle();
  return prefs;
}

/// Unmount so the Today provider's midnight timer is cancelled.
Future<void> _teardown(WidgetTester tester) =>
    tester.pumpWidget(const SizedBox());

void main() {
  testWidgets('empty state invites the user to create a habit', (tester) async {
    await _pumpApp(tester);
    expect(find.text('No habits yet'), findsOneWidget);
    expect(find.text('New habit'), findsOneWidget);
    await _teardown(tester);
  });

  testWidgets('shell navigates and theme setting persists', (tester) async {
    final prefs = await _pumpApp(tester);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Settings'),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(prefs.getString('themeMode'), 'dark');
    await _teardown(tester);
  });

  testWidgets('tapping a check habit toggles it on', (tester) async {
    final entryRepo = FakeEntryRepository();
    await _pumpApp(
      tester,
      habits: [makeHabit(id: 'run')],
      entryRepo: entryRepo,
    );
    expect(find.text('Habit run'), findsOneWidget);
    expect(find.text('Tap to complete'), findsOneWidget);

    await tester.tap(find.text('Habit run'));
    await tester.pumpAndSettle();

    expect(entryRepo.calls, hasLength(1));
    expect(entryRepo.calls.single.habitId, 'run');
    expect(entryRepo.calls.single.value, 1);
    expect(entryRepo.calls.single.date, toDateKey(DateTime.now()));
    await _teardown(tester);
  });

  testWidgets('counted habit shows progress and + adds one step',
      (tester) async {
    final entryRepo = FakeEntryRepository();
    await _pumpApp(
      tester,
      habits: [
        makeHabit(id: 'water', target: 8).copyWith(unit: () => 'glasses'),
      ],
      entryRepo: entryRepo,
    );
    expect(find.text('0 / 8 glasses'), findsOneWidget);

    await tester.tap(find.byTooltip('Add 1'));
    await tester.pumpAndSettle();

    expect(entryRepo.calls.single.value, 1);
    await _teardown(tester);
  });

  testWidgets('calendar day opens the editor and logs for that day',
      (tester) async {
    final entryRepo = FakeEntryRepository();
    final now = DateTime.now();
    await _pumpApp(
      tester,
      habits: [
        makeHabit(
          id: 'run',
          createdAt: now.subtract(const Duration(days: 40)),
        ),
      ],
      entryRepo: entryRepo,
    );

    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Calendar'),
    ));
    await tester.pumpAndSettle();
    expect(find.text(DateFormat.yMMMM().format(now)), findsOneWidget);

    // The test screen is small; scroll today's cell into view first.
    await tester.ensureVisible(find.text('${now.day}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('${now.day}'));
    await tester.pumpAndSettle();
    expect(find.text('Habit run'), findsOneWidget);

    await tester.tap(find.text('Habit run'));
    await tester.pumpAndSettle();
    expect(entryRepo.calls.single.date, toDateKey(now));
    expect(entryRepo.calls.single.value, 1);
    await _teardown(tester);
  });

  testWidgets('menu opens the habit detail screen', (tester) async {
    await _pumpApp(
      tester,
      habits: [
        makeHabit(
          id: 'run',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
      ],
    );

    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View details'));
    await tester.pumpAndSettle();

    expect(find.text('Current streak'), findsOneWidget);
    expect(find.text('Best streak'), findsOneWidget);
    expect(find.text('Completion rate'), findsOneWidget);
    await _teardown(tester);
  });

  testWidgets('statistics tab shows the chart and per-habit breakdown',
      (tester) async {
    // Tall viewport so the whole list is built.
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 1600);
    addTearDown(tester.view.reset);

    final now = DateTime.now();
    final habit = makeHabit(
      id: 'run',
      createdAt: now.subtract(const Duration(days: 40)),
    );
    final entry = Entry(
      id: 'e1',
      habitId: 'run',
      date: toDateKey(now),
      value: 1,
      target: 1,
      updatedAt: now,
    );
    await _pumpApp(
      tester,
      habits: [habit],
      entryRepo: FakeEntryRepository([entry]),
    );

    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Stats'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Goals met per day'), findsOneWidget);
    expect(find.text('By habit'), findsOneWidget);
    expect(find.text('Habit run'), findsOneWidget);
    await _teardown(tester);
  });

  testWidgets('statistics week navigation works', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 1600);
    addTearDown(tester.view.reset);

    await _pumpApp(tester, habits: [
      makeHabit(
        id: 'run',
        createdAt: DateTime.now().subtract(const Duration(days: 40)),
      ),
    ]);
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Stats'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('This week'), findsNothing);
    await tester.tap(find.byTooltip('Previous week'));
    await tester.pumpAndSettle();
    expect(find.text('This week'), findsOneWidget);

    await tester.tap(find.text('This week'));
    await tester.pumpAndSettle();
    expect(find.text('This week'), findsNothing);
    await _teardown(tester);
  });

  testWidgets('statistics shows a hint when there are no habits',
      (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Stats'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Create a habit to see your statistics.'), findsOneWidget);
    await _teardown(tester);
  });
}
