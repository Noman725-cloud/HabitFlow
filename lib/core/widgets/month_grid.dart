import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// "< October 2026 >" header. Pass null for [onNext] / [onPrev] to disable.
class MonthHeader extends StatelessWidget {
  const MonthHeader({
    super.key,
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Previous month',
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrev,
        ),
        Expanded(
          child: Center(
            child: Text(
              DateFormat.yMMMM().format(month),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Next month',
          icon: const Icon(Icons.chevron_right),
          onPressed: onNext,
        ),
      ],
    );
  }
}

/// A month laid out as weeks. [weekStartDay]: 1 = Mon .. 7 = Sun.
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required this.month,
    required this.weekStartDay,
    required this.cellBuilder,
  });

  final DateTime month;
  final int weekStartDay;
  final Widget Function(BuildContext context, DateTime day) cellBuilder;

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = (first.weekday - weekStartDay + 7) % 7;
    final rows = ((leading + daysInMonth) / 7).ceil();
    final labelStyle = Theme.of(context).textTheme.labelMedium;

    Widget cell(int dayNumber) {
      if (dayNumber < 1 || dayNumber > daysInMonth) {
        return const AspectRatio(aspectRatio: 1, child: SizedBox.shrink());
      }
      return AspectRatio(
        aspectRatio: 1,
        child: cellBuilder(
          context,
          DateTime(month.year, month.month, dayNumber),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    _letters[(weekStartDay - 1 + i) % 7],
                    style: labelStyle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                Expanded(child: cell(r * 7 + c - leading + 1)),
            ],
          ),
      ],
    );
  }
}
