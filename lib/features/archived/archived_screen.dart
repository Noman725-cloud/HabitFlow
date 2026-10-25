import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/habit_icons.dart';
import '../../core/schedule_label.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../shared/habit_actions.dart';

class ArchivedScreen extends ConsumerWidget {
  const ArchivedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(archivedHabitsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Archived habits')),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: 'Could not load archived habits.',
          onRetry: () => ref.invalidate(archivedHabitsProvider),
        ),
        data: (habits) {
          if (habits.isEmpty) {
            return const EmptyState(
              icon: Icons.archive_outlined,
              title: 'No archived habits',
              message: 'Archive a habit to hide it from Today without '
                  'losing its history.',
            );
          }
          return ListView(
            children: [
              for (final habit in habits)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(habit.colorValue),
                    child: Icon(
                      iconFor(habit.iconKey),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(habit.name),
                  subtitle: Text(scheduleLabel(habit.scheduleDays)),
                  onTap: () => context.push('/habit/${habit.id}'),
                  trailing: TextButton(
                    onPressed: () => unarchiveHabit(
                      ref,
                      ScaffoldMessenger.of(context),
                      habit,
                    ),
                    child: const Text('Unarchive'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
