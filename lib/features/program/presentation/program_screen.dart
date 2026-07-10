import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/localization/app_localizations.dart';
import '../../../app/theme.dart';
import '../../../core/week_days.dart';
import '../../common/presentation/common_widgets.dart';
import '../../workout/domain/models.dart';
import 'program_forms.dart';

class ProgramScreen extends StatelessWidget {
  const ProgramScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GymScope.of(context);
    final snapshot = controller.program;

    return AppPage(
      title: context.l10n.t('program'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (snapshot == null)
            EmptyState(
              message: context.l10n.t('createFirstProgram'),
              action: FilledButton.icon(
                onPressed: () => showCreateProgramSheet(context),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.t('createProgram')),
              ),
            )
          else ...<Widget>[
                NotebookCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              snapshot.program.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          IconButton(
                            tooltip: context.l10n.t('edit'),
                            onPressed: () =>
                                showEditProgramSheet(context, snapshot.program),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: context.l10n.t('archive'),
                            onPressed: () =>
                                _archiveProgram(context, snapshot.program),
                            icon: const Icon(Icons.archive_outlined),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.days.length} ${context.l10n.t('trainingDays')}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                SectionHeader(
                  title: context.l10n.t('workoutDays'),
                  trailing: IconButton.filled(
                    tooltip: context.l10n.t('addWorkoutDay'),
                    onPressed: () => showWorkoutDaySheet(
                      context,
                      programId: snapshot.program.id,
                    ),
                    icon: const Icon(Icons.add),
                  ),
                ),
                if (snapshot.days.isEmpty)
                  EmptyState(
                    message: context.l10n.t('selectTrainingDays'),
                    icon: Icons.calendar_month_outlined,
                  )
                else
                  for (var index = 0; index < snapshot.days.length; index += 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _WorkoutDayCard(
                        programId: snapshot.program.id,
                        day: snapshot.days[index],
                        isFirst: index == 0,
                        isLast: index == snapshot.days.length - 1,
                      ),
                    ),
          ],
          if (controller.archivedPrograms.isNotEmpty) ...<Widget>[
            SectionHeader(title: context.l10n.t('archivedPrograms')),
            for (final archived in controller.archivedPrograms)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NotebookCard(
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.archive_outlined,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              archived.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (archived.archivedAt != null) ...<Widget>[
                              const SizedBox(height: 4),
                              Text(
                                context.l10n.date(archived.archivedAt!),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _restoreProgram(context, archived),
                        icon: const Icon(Icons.unarchive_outlined),
                        label: Text(context.l10n.t('restore')),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _restoreProgram(BuildContext context, Program program) async {
    try {
      await GymScope.of(context).restoreProgram(program.id);
    } catch (error) {
      if (context.mounted) {
        showAppError(context, error);
      }
    }
  }

  Future<void> _archiveProgram(BuildContext context, Program program) async {
    final controller = GymScope.of(context);
    final confirmed = await confirmDialog(
      context: context,
      title: context.l10n.t('archiveProgram'),
      message: context.l10n.t('archiveProgramConfirm'),
      confirmLabel: context.l10n.t('archive'),
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    try {
      await controller.archiveProgram(program.id);
    } catch (error) {
      if (context.mounted) {
        showAppError(context, error);
      }
    }
  }
}

class _WorkoutDayCard extends StatelessWidget {
  const _WorkoutDayCard({
    required this.programId,
    required this.day,
    required this.isFirst,
    required this.isLast,
  });

  final int programId;
  final WorkoutDayWithExercises day;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final controller = GymScope.of(context);
    return NotebookCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      day.day.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weekDayName(day.day.weekDay, context.l10n.locale),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.l10n.t('moveUp'),
                onPressed: isFirst
                    ? null
                    : () => controller.moveWorkoutDay(
                          programId: programId,
                          workoutDayId: day.day.id,
                          direction: -1,
                        ),
                icon: const Icon(Icons.keyboard_arrow_up),
              ),
              IconButton(
                tooltip: context.l10n.t('moveDown'),
                onPressed: isLast
                    ? null
                    : () => controller.moveWorkoutDay(
                          programId: programId,
                          workoutDayId: day.day.id,
                          direction: 1,
                        ),
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
              PopupMenuButton<String>(
                tooltip: context.l10n.t('edit'),
                onSelected: (value) {
                  if (value == 'edit') {
                    showWorkoutDaySheet(
                      context,
                      programId: programId,
                      day: day.day,
                    );
                  } else if (value == 'delete') {
                    _deleteDay(context);
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Text(context.l10n.t('edit')),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(context.l10n.t('delete')),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.icon(
                onPressed: () => _startWorkout(context),
                icon: const Icon(Icons.play_arrow),
                label: Text(context.l10n.t('startWorkout')),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    showExerciseSheet(context, workoutDayId: day.day.id),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.t('addExercise')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (day.exercises.isEmpty)
            Text(
              context.l10n.t('noExercises'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            )
          else
            Column(
              children: <Widget>[
                for (final assignment in day.exercises)
                  _ExerciseListTile(
                    workoutDayId: day.day.id,
                    assignment: assignment,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _startWorkout(BuildContext context) async {
    try {
      await GymScope.of(context).startWorkout(day.day.id);
    } catch (error) {
      if (context.mounted) {
        showAppError(context, error);
      }
    }
  }

  Future<void> _deleteDay(BuildContext context) async {
    final confirmed = await confirmDialog(
      context: context,
      title: context.l10n.t('confirmDelete'),
      message: context.l10n.t('deleteDayConfirm'),
      confirmLabel: context.l10n.t('yesDelete'),
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    try {
      await GymScope.of(context).deleteWorkoutDay(day.day.id);
    } catch (error) {
      if (context.mounted) {
        showAppError(context, error);
      }
    }
  }
}

class _ExerciseListTile extends StatelessWidget {
  const _ExerciseListTile({
    required this.workoutDayId,
    required this.assignment,
  });

  final int workoutDayId;
  final ExerciseAssignment assignment;

  @override
  Widget build(BuildContext context) {
    final exercise = assignment.exercise;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${exercise.type == ExerciseType.weighted ? context.l10n.t('weighted') : context.l10n.t('repsOnly')} · ${assignment.assignment.defaultSets} ${context.l10n.t('set')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: context.l10n.t('edit'),
              onPressed: () => showExerciseSheet(
                context,
                workoutDayId: workoutDayId,
                assignment: assignment,
              ),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: context.l10n.t('delete'),
              onPressed: () => _deleteExercise(context),
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteExercise(BuildContext context) async {
    final confirmed = await confirmDialog(
      context: context,
      title: context.l10n.t('confirmDelete'),
      message: context.l10n.t('deleteExerciseConfirm'),
      confirmLabel: context.l10n.t('yesDelete'),
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    try {
      await GymScope.of(context).deleteExercise(
        assignmentId: assignment.assignment.id,
        exerciseId: assignment.exercise.id,
      );
    } catch (error) {
      if (context.mounted) {
        showAppError(context, error);
      }
    }
  }
}
