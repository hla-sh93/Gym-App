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

class _ActiveWorkout extends StatelessWidget {
  const _ActiveWorkout({required this.snapshot});

  final ActiveSessionSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: snapshot.day.name,
      bottom: FilledButton.icon(
        onPressed: () => _finish(context),
        icon: const Icon(Icons.flag_outlined),
        label: Text(context.l10n.t('finishWorkout')),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          NotebookCard(
            child: Row(
              children: <Widget>[
                const Icon(Icons.timer_outlined, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.t('workoutInProgress'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Text(context.l10n.date(snapshot.session.startedAt)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (snapshot.exercises.isEmpty)
            EmptyState(
              message: context.l10n.t('noExercises'),
              icon: Icons.fitness_center_outlined,
              action: OutlinedButton.icon(
                onPressed: () => GymScope.of(context).discardWorkout(),
                icon: const Icon(Icons.close),
                label: Text(context.l10n.t('discard')),
              ),
            )
          else
            for (final exerciseLog in snapshot.exercises)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ActiveExerciseCard(exerciseLog: exerciseLog),
              ),
        ],
      ),
    );
  }

  Future<void> _finish(BuildContext context) async {
    try {
      final summary = await GymScope.of(context).finishWorkout();
      if (!context.mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.t('workoutSummary')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              InlineStat(
                label: context.l10n.t('exercises'),
                value: summary.exerciseCount.toString(),
              ),
              const SizedBox(height: 8),
              InlineStat(
                label: context.l10n.t('completedSets'),
                value: summary.completedSetCount.toString(),
                color: AppColors.success,
              ),
              const SizedBox(height: 8),
              InlineStat(
                label: context.l10n.t('newBests'),
                value: summary.newBestCount.toString(),
                color: AppColors.warning,
              ),
            ],
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.t('done')),
            ),
          ],
        ),
      );
    } catch (error) {
      if (context.mounted) {
        showAppError(context, error);
      }
    }
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
          for (final set in exerciseLog.sets)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SetRow(
                key: ValueKey<int>(set.id),
                set: set,
                type: exercise.type,
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
    String value;
    if (best == null) {
      value = context.l10n.t('noPreviousData');
    } else if (type == ExerciseType.weighted) {
      value =
          '${formatWeight(best.weight ?? 0)}${weightUnitLabel(context)} x ${best.reps ?? '-'}';
    } else {
      value = '${best.reps ?? '-'} ${context.l10n.t('reps')}';
    }
    return InlineStat(
      label: context.l10n.t('best'),
      value: value,
      color: AppColors.success,
    );
  }
}

class _SetRow extends StatefulWidget {
  const _SetRow({required this.set, required this.type, super.key});

  final WorkoutSetLog set;
  final ExerciseType type;

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
    // Only rewrite the text when it no longer represents the stored value,
    // so refreshes don't clobber in-progress typing.
    if (oldWidget.set.id != widget.set.id ||
        InputValidation.parseWeight(_weightController.text) !=
            widget.set.weight) {
      _weightController.text =
          widget.set.weight == null ? '' : formatWeight(widget.set.weight!);
    }
    if (oldWidget.set.id != widget.set.id ||
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
                Checkbox(
                  value: widget.set.isCompleted,
                  onChanged: (value) {
                    GymScope.of(context).updateSetAndRefresh(
                      _composedSet(isCompleted: value ?? false),
                    );
                  },
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
        SizedBox(
          width: 48,
          height: 48,
          child: OutlinedButton(
            onPressed: onDecrement,
            child: Text(decrementLabel),
          ),
        ),
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
        SizedBox(
          width: 48,
          height: 48,
          child: OutlinedButton(
            onPressed: onIncrement,
            child: Text(incrementLabel),
          ),
        ),
      ],
    );
  }
}
