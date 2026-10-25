import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/services/stats_calculator.dart';

/// Seven bars, one per day. The solid part is the share of goals MET; the
/// lighter part behind it is average PROGRESS toward goals (so partial effort
/// is still visible). Drawn with plain widgets: no chart package needed.
class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({
    super.key,
    required this.days,
    required this.today,
    this.onDayTap,
  });

  final List<DayStats> days;
  final DateTime today;
  final void Function(DateTime day)? onDayTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final d in days)
            Expanded(
              child: _Bar(
                stats: d,
                isToday: d.date == today,
                isFuture: d.date.isAfter(today),
                onTap: onDayTap,
              ),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.stats,
    required this.isToday,
    required this.isFuture,
    required this.onTap,
  });

  final DayStats stats;
  final bool isToday;
  final bool isFuture;
  final void Function(DateTime day)? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tappable = !isFuture && onTap != null;
    final hasData = !isFuture && stats.scheduled > 0;

    final rate = hasData ? stats.completionRate.clamp(0.0, 1.0).toDouble() : 0.0;
    final progress = hasData ? stats.progress.clamp(0.0, 1.0).toDouble() : 0.0;
    final count = hasData ? '${stats.met}/${stats.scheduled}' : ' ';

    final semantics = '${DateFormat.EEEE().format(stats.date)}: '
        '${hasData ? '${stats.met} of ${stats.scheduled} goals met' : 'nothing due'}';

    return Semantics(
      label: semantics,
      button: tappable,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: tappable ? () => onTap!(stats.date) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: scheme.surfaceContainerHighest
                            .withValues(alpha: isFuture ? 0.4 : 1),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: progress,
                          widthFactor: 1,
                          child: ColoredBox(
                            color: scheme.primary.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: rate,
                          widthFactor: 1,
                          child: ColoredBox(color: scheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat.E().format(stats.date),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(count, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
