import 'package:flutter/material.dart';

import '../../core/widgets/placeholder_screen.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Calendar',
        icon: Icons.calendar_month_outlined,
        message: 'History calendar arrives in Phase 3.',
      );
}
