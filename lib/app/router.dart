import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/archived/archived_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/habit_detail/habit_detail_screen.dart';
import '../features/habit_form/habit_form_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/stats/stats_screen.dart';
import '../features/today/today_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/today',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _ScaffoldWithNav(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/today',
              builder: (context, state) => const TodayScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/calendar',
              builder: (context, state) => const CalendarScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/stats',
              builder: (context, state) => const StatsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ]),
        ],
      ),
      // Full-screen routes pushed above the bottom-nav shell.
      GoRoute(
        path: '/habit/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HabitFormScreen(),
      ),
      GoRoute(
        path: '/habit/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            HabitFormScreen(habitId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/habit/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            HabitDetailScreen(habitId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/archived',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ArchivedScreen(),
      ),
    ],
  );
});

class _ScaffoldWithNav extends StatelessWidget {
  const _ScaffoldWithNav({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(
          i,
          initialLocation: i == shell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
