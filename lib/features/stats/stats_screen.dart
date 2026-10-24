import 'package:flutter/material.dart';

import '../../core/widgets/placeholder_screen.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Statistics',
        icon: Icons.bar_chart_outlined,
        message: 'Weekly statistics arrive in Phase 4.',
      );
}
