import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/date_utils.dart';
import '../../core/habit_icons.dart';
import '../../core/widgets/stat_card.dart';
import '../../domain/models/habit.dart';
import '../../domain/services/stats_calculator.dart';
import '../calendar/day_editor_sheet.dart';
import 'weekly_bar_chart.dart';

int _pct(double v) => (v * 100).round();

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  /// 0 = this week, -1 = last week, ...
  int _weekOffset = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = ref.watch(todayProvider);
    final weekStartDay = ref.watch(weekStartProvider);
    final currentStart = startOfWeek(today, weekStartDay: weekStartDay);
    final weekStart = addDays(currentStart, _weekOffset * 7);
    final weekEnd = addDays(weekStart, 6);

    final habits = ref.watch(allHabitsProvider).orEmpty;
    final entries = ref.watch(entriesForWeekProvider(weekStart)).orEmpty;
    final stats = const StatsCalculator().weekly(
      habits: habits,
      entries: entries,
      weekStart: weekStart,
      today: today,
    );

    final byId = {for (final h in habits) h.id: h};
    final habitRows = stats.habits.where((h) => h.scheduled > 0).toList();
    final best = stats.bestDay;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          if (_weekOffset != 0)
            TextButton(
              onPressed: () => setState(() => _weekOffset = 0),
              child: const Text('This week'),
            ),
        ],
      ),
      body: habits.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Create a habit to see your statistics.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Previous week',
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(() => _weekOffset--),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '${DateFormat.MMMd().format(weekStart)} – '
                          '${DateFormat.yMMMd().format(weekEnd)}',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Next week',
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _weekOffset < 0
                          ? () => setState(() => _weekOffset++)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Goals met',
                        value: '${stats.met} of ${stats.scheduled}',
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Completion rate',
                        value: '${_pct(stats.completionRate)}%',
                        icon: Icons.percent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Average progress',
                        value: '${_pct(stats.averageProgress)}%',
                        icon: Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: best == null
                            ? 'Best day'
                            : 'Best day (${_pct(best.completionRate)}%)',
                        value: best == null
                            ? '–'
                            : DateFormat.EEEE().format(best.date),
                        icon: Icons.emoji_events_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Goals met per day',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        WeeklyBarChart(
                          days: stats.days,
                          today: today,
                          onDayTap: (day) =>
                              showDayEditor(context, date: day),
                        ),
                        const SizedBox(height: 12),
                        const _ChartLegend(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('By habit', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (habitRows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No habits were due this week.'),
                  )
                else
                  for (final row in habitRows)
                    if (byId[row.habitId] != null)
                      _HabitRow(habit: byId[row.habitId]!, stats: row),
              ],
            ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodySmall;
    Widget item(Color color, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(label, style: style),
          ],
        );
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        item(scheme.primary, 'Goals met'),
        item(scheme.primary.withValues(alpha: 0.35), 'Progress toward goals'),
      ],
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({required this.habit, required this.stats});

  final Habit habit;
  final HabitWeekStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(habit.colorValue);
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black;
    final counted = habit.targetValue > 1;
    final subtitle = '${stats.met} of ${stats.scheduled} days'
        '${counted ? ' · avg ${_pct(stats.averageProgress)}% of goal' : ''}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/habit/${habit.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: color,
                    child: Icon(
                      iconFor(habit.iconKey),
                      size: 20,
                      color: onColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(habit.name, style: theme.textTheme.titleMedium),
                        Text(subtitle, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Text(
                    '${_pct(stats.completionRate)}%',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: stats.completionRate.clamp(0.0, 1.0).toDouble(),
                minHeight: 6,
                color: color,
                backgroundColor: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
