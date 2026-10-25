import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/widgets/day_cell.dart';
import '../../core/widgets/month_grid.dart';
import '../../domain/services/stats_calculator.dart';
import 'day_editor_sheet.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shift(int months) =>
      setState(() => _month = DateTime(_month.year, _month.month + months));

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final weekStart = ref.watch(weekStartProvider);
    final habits = ref.watch(allHabitsProvider).orEmpty;
    final entries = ref.watch(entriesForMonthProvider(_month)).orEmpty;
    final scheme = Theme.of(context).colorScheme;

    final days = const StatsCalculator().forMonth(
      habits: habits,
      entries: entries,
      month: _month,
      today: today,
    );
    final totalScheduled = days.fold(0, (s, d) => s + d.scheduled);
    final totalMet = days.fold(0, (s, d) => s + d.met);

    final currentMonth = DateTime(today.year, today.month);
    final canGoNext = _month.isBefore(currentMonth);

    Widget cell(BuildContext context, DateTime day) {
      final s = days[day.day - 1];
      final future = day.isAfter(today);
      Color? background;
      var foreground = scheme.onSurface;
      if (future) {
        foreground = scheme.onSurface.withValues(alpha: 0.35);
      } else if (s.scheduled == 0) {
        foreground = scheme.onSurface.withValues(alpha: 0.5);
      } else if (s.met == s.scheduled) {
        background = scheme.primary;
        foreground = scheme.onPrimary;
      } else if (s.progress > 0) {
        background = scheme.primary.withValues(alpha: 0.35);
      } else {
        background = scheme.surfaceContainerHighest;
      }
      final status = s.scheduled == 0
          ? 'nothing scheduled'
          : '${s.met} of ${s.scheduled} done';
      return DayCell(
        day: day.day,
        background: background,
        foreground: foreground,
        isToday: day == today,
        semanticsLabel: '${DateFormat('MMMM d').format(day)}: $status',
        onTap: future ? null : () => showDayEditor(context, date: day),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          if (_month != currentMonth)
            TextButton(
              onPressed: () => setState(() => _month = currentMonth),
              child: const Text('This month'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MonthHeader(
            month: _month,
            onPrev: () => _shift(-1),
            onNext: canGoNext ? () => _shift(1) : null,
          ),
          const SizedBox(height: 8),
          MonthGrid(month: _month, weekStartDay: weekStart, cellBuilder: cell),
          const SizedBox(height: 16),
          const _Legend(),
          const SizedBox(height: 16),
          if (totalScheduled > 0)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '$totalMet of $totalScheduled goals met this month',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Tap a day to see or change what you did.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget item(Color color, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        item(scheme.surfaceContainerHighest, 'None'),
        item(scheme.primary.withValues(alpha: 0.35), 'Some'),
        item(scheme.primary, 'All done'),
      ],
    );
  }
}
