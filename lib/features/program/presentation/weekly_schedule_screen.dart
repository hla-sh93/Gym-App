import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/localization/app_localizations.dart';
import '../../../app/theme.dart';
import '../../../core/week_days.dart';
import '../../common/presentation/common_widgets.dart';
import '../../workout/domain/models.dart';

/// A gym-style weekly plan: every weekday Sun–Sat with its workout and
/// exercises (or a rest day).
class WeeklyScheduleScreen extends StatelessWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GymScope.of(context);
    final program = controller.program;
    final todayWeekDay = currentAppWeekDay(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.t('weeklySchedule')),
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: program == null
                ? EmptyState(
                    message: context.l10n.t('createFirstProgram'),
                    illustration: true,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: <Widget>[
                      for (final weekDay in weekDayValues)
                        _DayRow(
                          weekDay: weekDay,
                          day: program.dayForWeekDay(weekDay),
                          isToday: weekDay == todayWeekDay,
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.weekDay,
    required this.day,
    required this.isToday,
  });

  final int weekDay;
  final WorkoutDayWithExercises? day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isToday ? AppColors.primary : AppColors.border,
            width: isToday ? 1.6 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    weekDayName(weekDay, context.l10n.locale),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isToday ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  if (isToday) ...<Widget>[
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        context.l10n.t('today'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (day != null)
                    Text(
                      '${day!.exercises.length} ${context.l10n.t('exercises')}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (day == null)
                Text(
                  context.l10n.t('restDay'),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                )
              else ...<Widget>[
                Text(
                  day!.day.name,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                if (day!.exercises.isEmpty)
                  Text(
                    context.l10n.t('noExercises'),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  )
                else
                  for (final assignment in day!.exercises)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '• ${assignment.exercise.name}  ·  ${_planLabel(context, assignment)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _planLabel(BuildContext context, ExerciseAssignment assignment) {
    final sets = assignment.assignment.defaultSets;
    final planned = assignment.plannedSets;
    if (planned.isEmpty) {
      return '$sets ${context.l10n.t('set')}';
    }
    if (assignment.exercise.type == ExerciseType.weighted) {
      final weights = planned
          .map((p) => p.targetWeight == null
              ? '-'
              : formatWeight(p.targetWeight!))
          .join('/');
      return '$sets ${context.l10n.t('set')} · $weights${weightUnitLabel(context)}';
    }
    final reps = planned.map((p) => p.targetReps?.toString() ?? '-').join('/');
    return '$sets ${context.l10n.t('set')} · $reps ${context.l10n.t('reps')}';
  }
}
