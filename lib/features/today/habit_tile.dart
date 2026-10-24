import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/date_utils.dart';
import '../../core/habit_icons.dart';
import '../../domain/models/entry.dart';
import '../../domain/models/habit.dart';
import '../../domain/services/streak_calculator.dart';

enum _TileAction { edit, delete }

/// One habit on the Today screen.
/// Check habits: tap the tile to toggle. Counted habits: +/- buttons, and
/// long-press to type an exact value.
class HabitTile extends ConsumerWidget {
  const HabitTile({super.key, required this.habit, required this.today});

  final Habit habit;
  final DateTime today;

  Future<void> _setValue(WidgetRef ref, int value) {
    return ref.read(entryRepositoryProvider).setValue(
          habit: habit,
          date: toDateKey(today),
          value: value,
        );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(habitRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    await repo.delete(habit.id);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(
      content: Text('"${habit.name}" deleted'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => repo.restore(habit.id),
      ),
    ));
  }

  Future<void> _enterExact(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) async {
    final value = await showDialog<int>(
      context: context,
      builder: (_) => _ExactValueDialog(habit: habit, initial: current),
    );
    if (value != null) await _setValue(ref, value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(entriesForHabitProvider(habit.id)).orEmpty;
    final todayKey = toDateKey(today);

    Entry? entry;
    for (final e in entries) {
      if (e.date == todayKey) entry = e;
    }
    final value = entry?.value ?? 0;
    final target = entry?.target ?? habit.targetValue;
    final met = value >= target;
    final progress = (value / target).clamp(0.0, 1.0).toDouble();
    final streak = const StreakCalculator()
        .calculate(habit: habit, entries: entries, today: today)
        .current;

    final color = Color(habit.colorValue);
    final onColor = ThemeData.estimateBrightnessForColor(color) ==
            Brightness.dark
        ? Colors.white
        : Colors.black;
    final theme = Theme.of(context);
    final counted = habit.targetValue > 1;

    final leading = counted
        ? SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.2),
                  ),
                ),
                Icon(
                  met ? Icons.check : iconFor(habit.iconKey),
                  size: 20,
                  color: color,
                ),
              ],
            ),
          )
        : AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: met ? color : Colors.transparent,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(
              met ? Icons.check : iconFor(habit.iconKey),
              size: 22,
              color: met ? onColor : color,
            ),
          );

    final subtitle = counted
        ? '$value / $target${habit.unit == null ? '' : ' ${habit.unit}'}'
        : (met ? 'Done' : 'Tap to complete');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: counted ? null : () => _setValue(ref, met ? 0 : 1),
        onLongPress: counted ? () => _enterExact(context, ref, value) : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                    if (streak > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 16,
                            color: theme.colorScheme.tertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$streak day streak',
                            style: theme.textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (counted) ...[
                IconButton(
                  tooltip: 'Remove ${habit.step}',
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: value <= 0
                      ? null
                      : () => _setValue(ref, value - habit.step),
                ),
                IconButton(
                  tooltip: 'Add ${habit.step}',
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _setValue(ref, value + habit.step),
                ),
              ],
              PopupMenuButton<_TileAction>(
                tooltip: 'More options',
                onSelected: (action) {
                  switch (action) {
                    case _TileAction.edit:
                      context.push('/habit/${habit.id}/edit');
                    case _TileAction.delete:
                      _delete(context, ref);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: _TileAction.edit, child: Text('Edit')),
                  PopupMenuItem(
                    value: _TileAction.delete,
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExactValueDialog extends StatefulWidget {
  const _ExactValueDialog({required this.habit, required this.initial});

  final Habit habit;
  final int initial;

  @override
  State<_ExactValueDialog> createState() => _ExactValueDialogState();
}

class _ExactValueDialogState extends State<_ExactValueDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.initial}');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(int.tryParse(_controller.text.trim()));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.habit.name),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: widget.habit.unit ?? 'Amount today',
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
