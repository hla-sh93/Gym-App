import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/localization/app_localizations.dart';
import '../../home/presentation/home_screen.dart';
import '../../program/presentation/program_screen.dart';
import '../../progress/presentation/progress_screen.dart';
import '../../workout/presentation/workout_screen.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GymScope.of(context);
    final pages = <Widget>[
      const HomeScreen(),
      const ProgramScreen(),
      const WorkoutScreen(),
      const ProgressScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: controller.selectedTab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: controller.selectedTab,
        onDestinationSelected: controller.selectTab,
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: context.l10n.t('home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_note_outlined),
            selectedIcon: const Icon(Icons.event_note),
            label: context.l10n.t('program'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.fitness_center_outlined),
            selectedIcon: const Icon(Icons.fitness_center),
            label: context.l10n.t('workout'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.trending_up_outlined),
            selectedIcon: const Icon(Icons.trending_up),
            label: context.l10n.t('progress'),
          ),
        ],
      ),
    );
  }
}
