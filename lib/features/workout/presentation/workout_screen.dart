import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_scope.dart';
import '../../../app/localization/app_localizations.dart';
import '../../../app/theme.dart';
import '../../../core/input_validation.dart';
import '../../../core/week_days.dart';
import '../../common/presentation/common_widgets.dart';
import '../../program/presentation/program_forms.dart';
import '../domain/models.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GymScope.of(context);
    final active = controller.activeSession;
    if (active != null) {
      return _ActiveWorkout(snapshot: active);
    }
    return _WorkoutPicker();
  }
}

class _WorkoutPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = GymScope.of(context);
    final program = controller.program;
    return AppPage(
      title: context.l10n.t('workout'),
      child: program == null
          ? EmptyState(
              message: context.l10n.t('createFirstProgram'),
              action: FilledButton.icon(
                onPressed: () => showCreateProgramSheet(context),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.t('createProgram')),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SectionHeader(title: context.l10n.t('chooseWorkout')),
                for (final day in program.days)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: NotebookCard(
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  day.day.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${weekDayName(day.day.weekDay, context.l10n.locale)} · ${day.exercises.length} ${context.l10n.t('exercises')}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filled(
                            tooltip: context.l10n.t('startWorkout'),
                            onPressed: () => _start(context, day.day.id),
                            icon: const Icon(Icons.play_arrow),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _start(BuildContext context, int dayId) async {
    try {
      final resumedOtherDay = await GymScope.of(context).startWorkout(dayId);
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

/// The active-workout wizard (WORKOUT_FLOW.md §2): header with progress,
/// the CURRENT exercise open for logging, the rest minimized under Up Next.
/// Complete Exercise is the primary action; Finish Workout only becomes
/// primary after every exercise is done.
class _ActiveWorkout extends StatefulWidget {
  const _ActiveWorkout({required this.snapshot});

  final ActiveSessionSnapshot snapshot;

  @override
  State<_ActiveWorkout> createState() => _ActiveWorkoutState();
}

class _ActiveWorkoutState extends State<_ActiveWorkout> {
  /// Exercise the user explicitly opened from the list (overrides the
  /// default "first not-done" selection). Reset after Complete Exercise.
  int? _manualLogId;

  ActiveExerciseLog? get _current {
    final exercises = widget.snapshot.exercises;
    if (_manualLogId != null) {
      for (final log in exercises) {
        if (log.log.id == _manualLogId) {
          return log;
        }
      }
    }
    for (final log in exercises) {
      if (!log.isDone) {
        return log;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final exercises = snapshot.exercises;
    final doneCount = exercises.where((log) => log.isDone).length;
    final total = exercises.length;
    final current = _current;
    final allDone = total > 0 && current == null;
    final currentNumber = current == null
        ? total
        : exercises.indexWhere((log) => log.log.id == current.log.id) + 1;
    final progressLabel = context.l10n
        .t('exerciseOf')
        .replaceFirst('%1', '$currentNumber')
        .replaceFirst('%2', '$total');

    return AppPage(
      title: snapshot.day.name,
      bottom: allDone
          ? FilledButton.icon(
              onPressed: () => _finish(context),
              icon: const Icon(Icons.flag_outlined),
              label: Text(context.l10n.t('finishWorkout')),
            )
          : current == null
              ? null
              : FilledButton.icon(
                  onPressed: () => _complete(context, current),
                  icon: const Icon(Icons.check),
                  label: Text(context.l10n.t('completeExercise')),
                ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Header: day, date, exercise count, progress (WORKOUT_FLOW §2).
          HeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${weekDayName(snapshot.day.weekDay, context.l10n.locale)} · ${context.l10n.date(snapshot.session.startedAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ),
                    Text(
                      '$total ${context.l10n.t('exercises')}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
                if (total > 0) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    progressLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : doneCount / total,
                      minHeight: 8,
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (exercises.isEmpty)
            EmptyState(
              message: context.l10n.t('noExercises'),
              icon: Icons.fitness_center_outlined,
              action: OutlinedButton.icon(
                onPressed: () => GymScope.of(context).discardWorkout(),
                icon: const Icon(Icons.close),
                label: Text(context.l10n.t('discard')),
              ),
            )
          else if (current != null)
            // The current exercise, fully open for logging.
            _ActiveExerciseCard(exerciseLog: current)
          else
            NotebookCard(
              child: Column(
                children: <Widget>[
                  const IconBadge(
                    icon: Icons.emoji_events,
                    color: AppColors.success,
                    size: 56,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.t('allExercisesDone'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
          // Up Next: the other exercises, minimized (tap to open/edit).
          if (exercises.length > 1 || (allDone && exercises.isNotEmpty)) ...[
            SectionHeader(title: context.l10n.t('upNext')),
            for (var index = 0; index < exercises.length; index += 1)
              if (exercises[index].log.id != current?.log.id)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _UpNextTile(
                    number: index + 1,
                    exerciseLog: exercises[index],
                    onTap: () => setState(
                      () => _manualLogId = exercises[index].log.id,
                    ),
                  ),
                ),
          ],
          // Early finish stays available but never as the primary action.
          if (!allDone && exercises.isNotEmpty)
            TextButton(
              onPressed: () => _finish(context),
              child: Text(context.l10n.t('finishEarly')),
            ),
        ],
      ),
    );
  }

  Future<void> _complete(
    BuildContext context,
    ActiveExerciseLog exerciseLog,
  ) async {
    try {
      await GymScope.of(context).completeExercise(exerciseLog.log.id);
      if (mounted) {
        // Return to automatic selection: the next not-done exercise opens.
        setState(() => _manualLogId = null);
      }
    } catch (error) {
      if (context.mounted) {
        showAppError(context, error);
      }
    }
  }

  Future<void> _finish(BuildContext context) async {
    try {
      final controller = GymScope.of(context);
      await controller.finishWorkout();
      if (!context.mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const WorkoutSummaryScreen(),
        ),
      );
    } catch (error) {
      if (context.mounted) {
        showAppError(context, error);
      }
    }
  }
}

/// A minimized exercise row under "Up Next" (✓ when completed).
class _UpNextTile extends StatelessWidget {
  const _UpNextTile({
    required this.number,
    required this.exerciseLog,
    required this.onTap,
  });

  final int number;
  final ActiveExerciseLog exerciseLog;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = exerciseLog.isDone;
    return NotebookCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          IconBadge(
            icon: done ? Icons.check : Icons.fitness_center,
            color: done ? AppColors.success : AppColors.textSecondary,
            size: 32,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$number. ${exerciseLog.exercise.name}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: done ? AppColors.success : AppColors.textPrimary,
                  ),
            ),
          ),
          Text(
            done
                ? context.l10n.t('completed')
                : '${exerciseLog.sets.length} ${context.l10n.t('set')}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: done ? AppColors.success : AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

/// End-of-day report: everything played in the finished workout.
class WorkoutSummaryScreen extends StatelessWidget {
  const WorkoutSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GymScope.of(context);
    final summary = controller.latestSummary;
    final report = controller.lastWorkoutReport;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.t('workoutSummary')),
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.t('done')),
          ),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: <Widget>[
                if (report != null)
                  HeroCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          report.dayName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.date(report.session.sessionDate),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                if (summary != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: InlineStat(
                          label: context.l10n.t('exercises'),
                          value: summary.exerciseCount.toString(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InlineStat(
                          label: context.l10n.t('completedSets'),
                          value: summary.completedSetCount.toString(),
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InlineStat(
                          label: context.l10n.t('newBests'),
                          value: summary.newBestCount.toString(),
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                if (report != null)
                  for (final exercise in report.exercises)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: NotebookCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              exercise.exercise.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            for (final set in exercise.sets)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  formatSetLine(
                                    context,
                                    set,
                                    exercise.exercise.type,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveExerciseCard extends StatelessWidget {
  const _ActiveExerciseCard({required this.exerciseLog});

  final ActiveExerciseLog exerciseLog;

  @override
  Widget build(BuildContext context) {
    final exercise = exerciseLog.exercise;
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
                      exercise.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.type == ExerciseType.weighted
                          ? context.l10n.t('weighted')
                          : context.l10n.t('repsOnly'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (exercise.targetMuscle != null)
                Chip(label: Text(context.l10n.t(exercise.targetMuscle!))),
            ],
          ),
          const SizedBox(height: 16),
          _PreviousBlock(exerciseLog: exerciseLog),
          const SizedBox(height: 16),
          _BestBlock(best: exerciseLog.best, type: exercise.type),
          const SizedBox(height: 16),
          Text(
            context.l10n.t('todaySets'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < exerciseLog.sets.length; index += 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SetRow(
                key: ValueKey<int>(exerciseLog.sets[index].id),
                set: exerciseLog.sets[index],
                type: exercise.type,
                targetReps: index < exerciseLog.targetReps.length
                    ? exerciseLog.targetReps[index]
                    : null,
              ),
            ),
          OutlinedButton.icon(
            onPressed: () => GymScope.of(context).addSet(exerciseLog.log.id),
            icon: const Icon(Icons.add),
            label: Text(context.l10n.t('addSet')),
          ),
        ],
      ),
    );
  }
}

class _PreviousBlock extends StatelessWidget {
  const _PreviousBlock({required this.exerciseLog});

  final ActiveExerciseLog exerciseLog;

  @override
  Widget build(BuildContext context) {
    final previous = exerciseLog.previous;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.history, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  context.l10n.t('previous'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                ),
                if (previous != null) ...<Widget>[
                  const Spacer(),
                  Text(
                    context.l10n.date(
                      previous.session.finishedAt ??
                          previous.session.sessionDate,
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            if (previous == null || previous.sets.isEmpty)
              Text(
                '${context.l10n.t('noPreviousData')} ${context.l10n.t('startFirstLog')}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final set in previous.sets)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        formatSetLine(context, set, exerciseLog.exercise.type),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _BestBlock extends StatelessWidget {
  const _BestBlock({required this.best, required this.type});

  final BestResult? best;
  final ExerciseType type;

  @override
  Widget build(BuildContext context) {
    final best = this.best;
    // Spec §12.2.1 highlight: highest weight × reps (or best reps) with the
    // date it was last achieved, from completed sessions only.
    final title = type == ExerciseType.weighted
        ? context.l10n.t('highestWeight')
        : context.l10n.t('bestReps');
    if (best == null) {
      return InlineStat(
        label: title,
        value: context.l10n.t('noPreviousData'),
        color: AppColors.success,
      );
    }
    final value = type == ExerciseType.weighted
        ? '${formatWeight(best.weight ?? 0)}${weightUnitLabel(context)} x ${best.reps ?? '-'}'
        : '${best.reps ?? '-'} ${context.l10n.t('reps')}';
    return InlineStat(
      label:
          '$title · ${context.l10n.t('lastAchieved')}: ${context.l10n.date(best.date)}',
      value: value,
      color: AppColors.success,
    );
  }
}

class _SetRow extends StatefulWidget {
  const _SetRow({
    required this.set,
    required this.type,
    this.targetReps,
    super.key,
  });

  final WorkoutSetLog set;
  final ExerciseType type;

  /// Planned target reps from the program ("Target: 12 Reps"), if any.
  final int? targetReps;

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.set.weight == null ? '' : formatWeight(widget.set.weight!),
    );
    _repsController = TextEditingController(
      text: widget.set.reps?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The text the user typed is the source of truth while this row lives.
    // Rewrite it ONLY on a real external change: a different set, or the
    // stored value itself changed (stepper/refresh). Comparing text against
    // the possibly-stale snapshot would wipe typed input on any rebuild.
    if (oldWidget.set.id != widget.set.id) {
      _weightController.text =
          widget.set.weight == null ? '' : formatWeight(widget.set.weight!);
      _repsController.text = widget.set.reps?.toString() ?? '';
      return;
    }
    if (oldWidget.set.weight != widget.set.weight &&
        InputValidation.parseWeight(_weightController.text) !=
            widget.set.weight) {
      _weightController.text =
          widget.set.weight == null ? '' : formatWeight(widget.set.weight!);
    }
    if (oldWidget.set.reps != widget.set.reps &&
        InputValidation.parseReps(_repsController.text) != widget.set.reps) {
      _repsController.text = widget.set.reps?.toString() ?? '';
    }
  }

  /// Builds the up-to-date set from what is on screen right now. Never use
  /// widget.set values directly for writes: typed input is saved silently
  /// (without a snapshot refresh), so widget.set can be stale.
  WorkoutSetLog _composedSet({bool? isCompleted}) {
    final weight = InputValidation.parseWeight(_weightController.text);
    final reps = InputValidation.parseReps(_repsController.text);
    return widget.set.copyWith(
      weight: weight,
      clearWeight: weight == null,
      reps: reps,
      clearReps: reps == null,
      isCompleted: isCompleted,
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWeighted = widget.type == ExerciseType.weighted;
    final completed = widget.set.isCompleted;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: completed ? AppColors.successSoft : null,
        border: Border.all(
          color: completed ? AppColors.success : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${context.l10n.t('set')} ${widget.set.setNumber}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                // "Target: 12 Reps" — planned in the program, reps only.
                if (widget.targetReps != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 4),
                    child: Text(
                      '${context.l10n.t('target')}: ${widget.targetReps} ${context.l10n.t('reps')}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                if (completed)
                  const Padding(
                    padding: EdgeInsetsDirectional.only(end: 4),
                    child: Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    ),
                  ),
                IconButton(
                  tooltip: context.l10n.t('delete'),
                  onPressed: () => GymScope.of(
                    context,
                  ).deleteSet(widget.set.id, widget.set.workoutExerciseLogId),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 420;
                final fields = <Widget>[
                  if (isWeighted)
                    _NumberStepperField(
                      controller: _weightController,
                      label:
                          '${context.l10n.t('weight')} ${weightUnitLabel(context)}',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: <TextInputFormatter>[
                        decimalWeightFormatter(),
                      ],
                      decrementLabel: '-2.5',
                      incrementLabel: '+2.5',
                      onDecrement: () => _stepWeight(context, -2.5),
                      onIncrement: () => _stepWeight(context, 2.5),
                      onChanged: (_) => _saveTyped(context),
                    ),
                  _NumberStepperField(
                    controller: _repsController,
                    label: context.l10n.t('reps'),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decrementLabel: '-',
                    incrementLabel: '+',
                    onDecrement: () => _stepReps(context, -1),
                    onIncrement: () => _stepReps(context, 1),
                    onChanged: (_) => _saveTyped(context),
                  ),
                ];
                if (narrow) {
                  return Column(
                    children: <Widget>[
                      for (var index = 0; index < fields.length; index += 1)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: index == fields.length - 1 ? 0 : 8,
                          ),
                          child: fields[index],
                        ),
                    ],
                  );
                }
                return Row(
                  children: <Widget>[
                    for (var index = 0; index < fields.length; index += 1) ...[
                      if (index > 0) const SizedBox(width: 8),
                      Expanded(child: fields[index]),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTyped(BuildContext context) async {
    await GymScope.of(context).updateSetSilently(_composedSet());
  }

  Future<void> _stepWeight(BuildContext context, double delta) async {
    final current = (InputValidation.parseWeight(_weightController.text) ??
            widget.set.weight ??
            0)
        .toDouble();
    final next = math.max<double>(0, current + delta);
    _weightController.text = formatWeight(next);
    await GymScope.of(context).updateSetAndRefresh(_composedSet());
  }

  Future<void> _stepReps(BuildContext context, int delta) async {
    final current =
        InputValidation.parseReps(_repsController.text) ?? widget.set.reps ?? 0;
    final next = math.max<int>(0, current + delta);
    _repsController.text = next.toString();
    await GymScope.of(context).updateSetAndRefresh(_composedSet());
  }
}

/// Allows only a single decimal number such as "42.5" or "42,5".
TextInputFormatter decimalWeightFormatter() {
  final pattern = RegExp(r'^\d{0,4}([.,]\d{0,2})?$');
  return TextInputFormatter.withFunction((oldValue, newValue) {
    if (newValue.text.isEmpty || pattern.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  });
}

class _NumberStepperField extends StatelessWidget {
  const _NumberStepperField({
    required this.controller,
    required this.label,
    required this.keyboardType,
    required this.inputFormatters,
    required this.decrementLabel,
    required this.incrementLabel,
    required this.onDecrement,
    required this.onIncrement,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final String decrementLabel;
  final String incrementLabel;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _StepperButton(label: decrementLabel, onPressed: onDecrement),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textAlign: TextAlign.center,
            decoration: InputDecoration(labelText: label),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 8),
        _StepperButton(label: incrementLabel, onPressed: onIncrement),
      ],
    );
  }
}

/// Compact quick-increment button ("-2.5" / "+2.5" / "-" / "+"). Zero padding
/// and a single line so the label never wraps into unreadable columns.
class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(54, 48),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(label, maxLines: 1, softWrap: false),
      ),
    );
  }
}
