import 'package:flutter/material.dart';

/// One round day in a month grid.
class DayCell extends StatelessWidget {
  const DayCell({
    super.key,
    required this.day,
    required this.foreground,
    this.background,
    this.outlined = false,
    this.isToday = false,
    this.onTap,
    this.semanticsLabel,
  });

  final int day;
  final Color foreground;
  final Color? background;
  final bool outlined;
  final bool isToday;
  final VoidCallback? onTap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final BorderSide side = isToday
        ? BorderSide(color: scheme.primary, width: 2)
        : outlined
            ? BorderSide(color: foreground.withValues(alpha: 0.5))
            : BorderSide.none;

    return Semantics(
      label: semanticsLabel,
      button: onTap != null,
      excludeSemantics: semanticsLabel != null,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Material(
          color: background ?? Colors.transparent,
          shape: CircleBorder(side: side),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: foreground,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
