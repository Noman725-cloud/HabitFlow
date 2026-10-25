import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/habit.dart';

void _snack(
  ScaffoldMessengerState messenger,
  String message,
  VoidCallback onUndo,
) {
  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(message),
      action: SnackBarAction(label: 'Undo', onPressed: onUndo),
    ));
}

/// Capture [messenger] with ScaffoldMessenger.of(context) BEFORE awaiting or
/// popping, so the snackbar still shows after the screen is gone.
Future<void> archiveHabit(
  WidgetRef ref,
  ScaffoldMessengerState messenger,
  Habit habit,
) async {
  final repo = ref.read(habitRepositoryProvider);
  await repo.archive(habit.id);
  _snack(messenger, '"${habit.name}" archived', () => repo.unarchive(habit.id));
}

Future<void> unarchiveHabit(
  WidgetRef ref,
  ScaffoldMessengerState messenger,
  Habit habit,
) async {
  final repo = ref.read(habitRepositoryProvider);
  await repo.unarchive(habit.id);
  _snack(messenger, '"${habit.name}" restored', () => repo.archive(habit.id));
}

Future<void> deleteHabit(
  WidgetRef ref,
  ScaffoldMessengerState messenger,
  Habit habit,
) async {
  final repo = ref.read(habitRepositoryProvider);
  await repo.delete(habit.id);
  _snack(messenger, '"${habit.name}" deleted', () => repo.restore(habit.id));
}
