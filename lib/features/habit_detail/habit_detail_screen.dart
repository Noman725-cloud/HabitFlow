import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/date_utils.dart';
import '../../core/habit_icons.dart';
import '../../core/schedule_label.dart';
import '../../core/widgets/day_cell.dart';
import '../../core/widgets/month_grid.dart';
import '../../core/widgets/stat_card.dart';
import '../../domain/models/habit.dart';
import '../../domain/services/day_status.dart';
import '../../domain/services/entry_index.dart';
import '../../domain/services/habit_overview.dart';
import '../calendar/day_editor_sheet.dart';
import '../shared/habit_actions.dart';

enum _DetailAction { edit, archive, unarchive, delete }

class HabitDetailScreen extends ConsumerStatefulWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final String habitId;

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shift(int months) =>
      setState(() => _month = DateTime(_month.year, _month.month + months));

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(allHabitsProvider);
    return habitsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Could not load this habit.\n$e')),
      ),
      data: (habits) {
        Habit? habit;
        for (final h in habits) {
          if (h.id == widget.habitId) habit = h;
        }
        if (habit == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('This habit no longer exists.')),
          );
        }
        return _buildContent(context, habit);
      },
    );
  }

  Widget _buildContent(BuildContext context, Habit habit) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = ref.watch(todayProvider);
    final weekStart = ref.watch(weekStartProvider);
    final entries = ref.watch(entriesForHabitProvider(habit.id)).orEmpty;
    final overview = const HabitOverviewCalculator()
        .calculate(habit: habit, entries: entries, today: today);
    final index = EntryIndex(entries);
    final color = Color(habit.colorValue);
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black;

    final currentMonth = DateTime(today.year, today.month);
    final canGoNext = _month.isBefore(currentMonth);

    Widget cell(BuildContext context, DateTime day) {
      final status = habitDayStatus(
        habit: habit,
        entry: index.find(habit.id, toDateKey(day)),
        day: day,
        today: today,
      );
      Color? background;
      var foreground = scheme.onSurface;
      var outlined = false;
      switch (status) {
        case DayStatus.met:
          background = color;
          foreground = onColor;
        case DayStatus.partial:
          background = color.withValues(alpha: 0.35);
        case DayStatus.missed:
          outlined = true;
          foreground = scheme.onSurface.withValues(alpha: 0.7);
        case DayStatus.pending:
          if (day != today) {
            foreground = scheme.onSurface.withValues(alpha: 0.5);
          }
        case DayStatus.notTracked:
          foreground = scheme.onSurface.withValues(alpha: 0.25);
      }
      final tappable = status != DayStatus.notTracked && !day.isAfter(today);
      return DayCell(
        day: day.day,
        background: background,
        foreground: foreground,
        outlined: outlined,
        isToday: day == today,
        onTap: tappable
            ? () => showDayEditor(context, date: day, onlyHabitId: habit.id)
            : null,
      );
    }

    final goal = habit.targetValue > 1
        ? '${habit.targetValue}${habit.unit == null ? '' : ' ${habit.unit}'} per day'
        : 'Check off once a day';

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
        actions: [
          PopupMenuButton<_DetailAction>(
            tooltip: 'More options',
            onSelected: (action) async {
              final messenger = ScaffoldMessenger.of(context);
              final router = GoRouter.of(context);
              switch (action) {
                case _DetailAction.edit:
                  router.push('/habit/${habit.id}/edit');
                case _DetailAction.archive:
                  await archiveHabit(ref, messenger, habit);
                  if (mounted) router.pop();
                case _DetailAction.unarchive:
                  await unarchiveHabit(ref, messenger, habit);
                case _DetailAction.delete:
                  await deleteHabit(ref, messenger, habit);
                  if (mounted) router.pop();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: _DetailAction.edit, child: Text('Edit')),
              if (habit.isArchived)
                const PopupMenuItem(
                  value: _DetailAction.unarchive,
                  child: Text('Unarchive'),
                )
              else
                const PopupMenuItem(
                  value: _DetailAction.archive,
                  child: Text('Archive'),
                ),
              const PopupMenuItem(
                value: _DetailAction.delete,
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color,
                child: Icon(iconFor(habit.iconKey), color: onColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal, style: theme.textTheme.titleMedium),
                    Text(
                      scheduleLabel(habit.scheduleDays),
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (habit.isArchived)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Chip(
                          label: Text('Archived'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Current streak',
                  value: _days(overview.currentStreak),
                  icon: Icons.local_fire_department,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Best streak',
                  value: _days(overview.bestStreak),
                  icon: Icons.emoji_events_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Completion rate',
                  value: '${(overview.completionRate * 100).round()}%',
                  icon: Icons.percent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Days completed',
                  value: '${overview.totalMet}',
                  icon: Icons.check_circle_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('History', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          MonthHeader(
            month: _month,
            onPrev: () => _shift(-1),
            onNext: canGoNext ? () => _shift(1) : null,
          ),
          MonthGrid(month: _month, weekStartDay: weekStart, cellBuilder: cell),
          const SizedBox(height: 8),
          Text(
            _month.isBefore(dateOnly(habit.createdAt))
                ? 'Tap a day to change it. To log days before '
                    '${DateFormat.yMMMd().format(dateOnly(habit.createdAt))}, '
                    'edit the habit and change its start date.'
                : 'Tap a day to change it.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _days(int n) => '$n ${n == 1 ? 'day' : 'days'}';
}
