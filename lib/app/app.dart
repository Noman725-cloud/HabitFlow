import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'router.dart';
import 'theme.dart';

class HabitFlowApp extends ConsumerStatefulWidget {
  const HabitFlowApp({super.key});

  @override
  ConsumerState<HabitFlowApp> createState() => _HabitFlowAppState();
}

class _HabitFlowAppState extends ConsumerState<HabitFlowApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// If the app was backgrounded past midnight, "today" must roll over.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(todayProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HabitFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
