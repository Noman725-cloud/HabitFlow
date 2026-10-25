import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final weekStart = ref.watch(weekStartProvider);
    final titleStyle = Theme.of(context).textTheme.titleMedium;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Appearance', style: titleStyle),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto),
                label: Text('System'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode),
                label: Text('Light'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode),
                label: Text('Dark'),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).set(s.first),
          ),
          const SizedBox(height: 24),
          Text('Week starts on', style: titleStyle),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: DateTime.monday, label: Text('Mon')),
              ButtonSegment(value: DateTime.saturday, label: Text('Sat')),
              ButtonSegment(value: DateTime.sunday, label: Text('Sun')),
            ],
            selected: {weekStart},
            onSelectionChanged: (s) =>
                ref.read(weekStartProvider.notifier).set(s.first),
          ),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.archive_outlined),
            title: const Text('Archived habits'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/archived'),
          ),
        ],
      ),
    );
  }
}
