import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/animation.dart';
import '../../core/date_utils.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../domain/services/stats_calculator.dart';
import 'habit_tile.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final habitsAsync = ref.watch(activeHabitsProvider);
    final todaysEntries =
        ref.watch(entriesForDateProvider(toDateKey(today))).orEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/habit/new'),
        icon: const Icon(Icons.add),
        label: const Text('New habit'),
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: 'Could not load your habits.',
          onRetry: () => ref.invalidate(activeHabitsProvider),
        ),
        data: (habits) {
          if (habits.isEmpty) {
            return EmptyState(
              icon: Icons.spa_outlined,
              title: 'No habits yet',
              message: 'Create your first habit to start building a streak.',
              actionLabel: 'Create habit',
              onAction: () => context.push('/habit/new'),
            );
          }

          final due = habits.where((h) => h.isScheduledOn(today)).toList();
          final stats = const StatsCalculator().forDay(
            habits: due,
            entries: todaysEntries,
            date: today,
            today: today,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              _SummaryCard(today: today, met: stats.met, total: stats.scheduled),
              const SizedBox(height: 12),
              if (due.isEmpty)
                const _RestDay()
              else
                for (final habit in due)
                  HabitTile(key: ValueKey(habit.id), habit: habit, today: today),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.today,
    required this.met,
    required this.total,
  });

  final DateTime today;
  final int met;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline = total == 0
        ? 'Nothing due today'
        : met == total
            ? 'All done. Great work!'
            : '$met of $total done';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, MMM d').format(today),
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(headline, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: total == 0 ? 0 : met / total),
              duration: animDuration(context, 400),
              curve: Curves.easeOut,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestDay extends StatelessWidget {
  const _RestDay();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Text(
        'None of your habits are scheduled today. Enjoy the rest day.',
        textAlign: TextAlign.center,
      ),
    );
  }
}
