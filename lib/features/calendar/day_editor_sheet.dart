import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/date_utils.dart';
import '../today/habit_tile.dart';

/// Bottom sheet to view/edit one day's progress (today or a past day).
/// [onlyHabitId] limits it to a single habit (used from the detail screen).
Future<void> showDayEditor(
  BuildContext context, {
  required DateTime date,
  String? onlyHabitId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => DayEditorSheet(date: date, onlyHabitId: onlyHabitId),
  );
}

class DayEditorSheet extends ConsumerWidget {
  const DayEditorSheet({super.key, required this.date, this.onlyHabitId});

  final DateTime date;
  final String? onlyHabitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final theme = Theme.of(context);
    final candidates = ref
        .watch(allHabitsProvider)
        .orEmpty
        .where((h) => onlyHabitId == null || h.id == onlyHabitId)
        .toList();
    final habits = candidates.where((h) => h.isTrackedOn(date)).toList();
    final startedLater = candidates.any(
      (h) =>
          !h.isDeleted &&
          h.isScheduledOn(date) &&
          date.isBefore(dateOnly(h.createdAt)),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMM d').format(date),
            style: theme.textTheme.titleLarge,
          ),
          if (date != today)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Editing a past day. Streaks update automatically.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 12),
          if (habits.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  startedLater
                      ? 'Your habit started after this day. Edit it and '
                          'change the start date to log earlier days.'
                      : 'No habits were scheduled this day.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final habit in habits)
                    HabitTile(
                      key: ValueKey('${habit.id}-${date.toIso8601String()}'),
                      habit: habit,
                      today: today,
                      date: date,
                      showMenu: false,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
