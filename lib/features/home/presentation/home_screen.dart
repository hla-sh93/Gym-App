import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/localization/app_localizations.dart';
import '../../../app/theme.dart';
import '../../../core/week_days.dart';
import '../../common/presentation/common_widgets.dart';
import '../../program/presentation/program_forms.dart';
import '../../settings/presentation/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GymScope.of(context);
    final program = controller.program;
    final todayWeekDay = currentAppWeekDay(DateTime.now());
    final today = program?.dayForWeekDay(todayWeekDay);

    return AppPage(
      title: context.l10n.t('home'),
      actions: <Widget>[
        IconButton(
          tooltip: context.l10n.t('settings'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            );
          },
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (controller.activeSession != null &&
              controller.snoozedSessionId !=
                  controller.activeSession!.session.id) ...<Widget>[
            _InProgressBanner(dayName: controller.activeSession!.day.name),
            const SizedBox(height: 16),
          ],
          SectionHeader(title: context.l10n.t('today')),
          if (program == null)
            EmptyState(
              message: context.l10n.t('createFirstProgram'),
              action: FilledButton.icon(
                onPressed: () => showCreateProgramSheet(context),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.t('createProgram')),
              ),
            )
          else if (today == null)
            EmptyState(
              message: context.l10n.t('noWorkoutToday'),
              icon: Icons.calendar_today_outlined,
              action: OutlinedButton.icon(
                onPressed: () => controller.selectTab(2),
                icon: const Icon(Icons.fitness_center_outlined),
                label: Text(context.l10n.t('chooseWorkout')),
              ),
            )
          else
            NotebookCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    today.day.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${weekDayName(today.day.weekDay, context.l10n.locale)} · ${today.exercises.length} ${context.l10n.t('exercises')}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _startWorkout(context, today.day.id),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(context.l10n.t('startWorkout')),
                  ),
                ],
              ),
            ),
          if (program != null) ...<Widget>[
            SectionHeader(title: context.l10n.t('currentProgram')),
            NotebookCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    program.program.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${program.days.length} ${context.l10n.t('trainingDays')}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => controller.selectTab(1),
                    icon: const Icon(Icons.event_note_outlined),
                    label: Text(context.l10n.t('program')),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startWorkout(BuildContext context, int workoutDayId) async {
    try {
      final resumedOtherDay = await GymScope.of(
        context,
      ).startWorkout(workoutDayId);
      if (resumedOtherDay && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.t('workoutInProgress'))),
        );
      }
    } catch (error) {
      if (context.mounted) {
        showAppError(context, error);
      }
    }
  }
}

class _InProgressBanner extends StatelessWidget {
  const _InProgressBanner({required this.dayName});

  final String dayName;

  @override
  Widget build(BuildContext context) {
    final controller = GymScope.of(context);
    return NotebookCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.timer_outlined, color: AppColors.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.t('workoutInProgress'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(dayName),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.icon(
                onPressed: () => controller.selectTab(2),
                icon: const Icon(Icons.play_arrow),
                label: Text(context.l10n.t('continueWorkout')),
              ),
              OutlinedButton.icon(
                onPressed: controller.snoozeActiveSessionBanner,
                icon: const Icon(Icons.watch_later_outlined),
                label: Text(context.l10n.t('finishLater')),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await confirmDialog(
                    context: context,
                    title: context.l10n.t('discard'),
                    message: context.l10n.t('discardWorkoutConfirm'),
                    confirmLabel: context.l10n.t('discard'),
                  );
                  if (!confirmed || !context.mounted) {
                    return;
                  }
                  await controller.discardWorkout();
                },
                icon: const Icon(Icons.close),
                label: Text(context.l10n.t('discard')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
