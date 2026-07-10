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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: controller.selectedTab,
        onTap: controller.selectTab,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: context.l10n.t('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.event_note_outlined),
            activeIcon: const Icon(Icons.event_note),
            label: context.l10n.t('program'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.fitness_center_outlined),
            activeIcon: const Icon(Icons.fitness_center),
            label: context.l10n.t('workout'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.trending_up_outlined),
            activeIcon: const Icon(Icons.trending_up),
            label: context.l10n.t('progress'),
          ),
        ],
      ),
    );
  }
}
