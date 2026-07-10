import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_scope.dart';
import '../../../app/localization/app_localizations.dart';
import '../../../app/theme.dart';
import '../../../core/input_validation.dart';
import '../../common/presentation/common_widgets.dart';
import '../../workout/domain/models.dart';
import '../../workout/presentation/workout_screen.dart'
    show decimalWeightFormatter;

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GymScope.of(context);
    final progress = controller.progress;
    final isEmpty = progress.bests.isEmpty && progress.recentSessions.isEmpty;
    return AppPage(
      title: context.l10n.t('progress'),
      child: isEmpty
          ? EmptyState(
              message: context.l10n.t('noProgress'),
              icon: Icons.trending_up_outlined,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SectionHeader(title: context.l10n.t('bests')),
                if (progress.bests.isEmpty)
                  EmptyState(message: context.l10n.t('noProgress'))
                else
                  for (final best in progress.bests)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _BestCard(best: best),
                    ),
                SectionHeader(title: context.l10n.t('recentWorkouts')),
                if (progress.recentSessions.isEmpty)
                  EmptyState(message: context.l10n.t('noHistory'))
                else
                  for (final session in progress.recentSessions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: NotebookCard(
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.check_circle_outline,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    session.dayName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${context.l10n.date(session.session.finishedAt ?? session.session.sessionDate)} · ${session.completedSetCount} ${context.l10n.t('completedSets')}',
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
                          ],
                        ),
                      ),
                    ),
              ],
            ),
    );
  }
}

class _BestCard extends StatelessWidget {
  const _BestCard({required this.best});

  final ExerciseBestSummary best;

  @override
  Widget build(BuildContext context) {
    final result = best.best;
    final value = result == null
        ? context.l10n.t('noPreviousData')
        : best.exercise.type == ExerciseType.weighted
            ? '${formatWeight(result.weight ?? 0)}${weightUnitLabel(context)} x ${result.reps ?? '-'}'
            : '${result.reps ?? '-'} ${context.l10n.t('reps')}';
    return NotebookCard(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  best.exercise.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _showHistory(context, best.exercise),
            icon: const Icon(Icons.history),
            label: Text(context.l10n.t('history')),
          ),
        ],
      ),
    );
  }

  void _showHistory(BuildContext context, Exercise exercise) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExerciseHistorySheet(exercise: exercise),
    );
  }
}

class _ExerciseHistorySheet extends StatefulWidget {
  const _ExerciseHistorySheet({required this.exercise});

  final Exercise exercise;

  @override
  State<_ExerciseHistorySheet> createState() => _ExerciseHistorySheetState();
}

class _ExerciseHistorySheetState extends State<_ExerciseHistorySheet> {
  Future<List<ExerciseHistoryEntry>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= GymScope.of(context).exerciseHistory(widget.exercise.id);
  }

  void _reload() {
    setState(() {
      _future = GymScope.of(context).exerciseHistory(widget.exercise.id);
    });
  }

  /// The single best completed set across all history entries.
  WorkoutSetLog? _bestSet(List<ExerciseHistoryEntry> history) {
    WorkoutSetLog? best;
    for (final entry in history) {
      for (final set in entry.sets) {
        if (set.reps == null) {
          continue;
        }
        if (widget.exercise.type == ExerciseType.weighted) {
          if (set.weight == null) {
            continue;
          }
          if (best == null ||
              set.weight! > best.weight! ||
              (set.weight == best.weight && set.reps! > best.reps!)) {
            best = set;
          }
        } else if (best == null || set.reps! > best.reps!) {
          best = set;
        }
      }
    }
    return best;
  }

  Future<void> _editSession(ExerciseHistoryEntry entry) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditSessionSheet(
        exercise: widget.exercise,
        sessionId: entry.session.id,
      ),
    );
    if (!mounted) {
      return;
    }
    await GymScope.of(context).refresh();
    if (mounted) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.82,
              child: FutureBuilder<List<ExerciseHistoryEntry>>(
                future: _future,
                builder: (context, snapshot) {
                  final history = snapshot.data ?? <ExerciseHistoryEntry>[];
                  final bestSet = _bestSet(history);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              exercise.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          IconButton(
                            tooltip: context.l10n.t('cancel'),
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      if (bestSet != null) ...<Widget>[
                        const SizedBox(height: 4),
                        InlineStat(
                          label: context.l10n.t('best'),
                          value: exercise.type == ExerciseType.weighted
                              ? '${formatWeight(bestSet.weight ?? 0)}${weightUnitLabel(context)} x ${bestSet.reps ?? '-'}'
                              : '${bestSet.reps ?? '-'} ${context.l10n.t('reps')}',
                          color: AppColors.success,
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (history.isEmpty)
                        Expanded(
                          child: Center(
                            child: EmptyState(
                              message: context.l10n.t('noHistory'),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            itemBuilder: (context, index) {
                              final entry = history[index];
                              return NotebookCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            context.l10n.date(
                                              entry.session.finishedAt ??
                                                  entry.session.sessionDate,
                                            ),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: context.l10n.t(
                                            'editSession',
                                          ),
                                          onPressed: () => _editSession(entry),
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    for (final set in entry.sets)
                                      Text(
                                        formatSetLine(
                                          context,
                                          set,
                                          exercise.type,
                                          isBest: bestSet?.id == set.id,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemCount: history.length,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Edits the sets of one exercise inside a past (completed) session.
/// Best values and history update automatically because progress queries
/// always read live data.
class _EditSessionSheet extends StatefulWidget {
  const _EditSessionSheet({required this.exercise, required this.sessionId});

  final Exercise exercise;
  final int sessionId;

  @override
  State<_EditSessionSheet> createState() => _EditSessionSheetState();
}

class _EditSessionSheetState extends State<_EditSessionSheet> {
  ActiveExerciseLog? _log;
  bool _loading = true;
  bool _loadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadStarted) {
      _loadStarted = true;
      _load();
    }
  }

  Future<void> _load() async {
    final controller = GymScope.of(context);
    try {
      final snapshot = await controller.repository.sessionSnapshot(
        widget.sessionId,
      );
      if (!mounted) {
        return;
      }
      ActiveExerciseLog? match;
      for (final log in snapshot.exercises) {
        if (log.exercise.id == widget.exercise.id) {
          match = log;
          break;
        }
      }
      setState(() {
        _log = match;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _loading = false);
        showAppError(context, error);
      }
    }
  }

  Future<void> _addSet() async {
    final log = _log;
    if (log == null) {
      return;
    }
    await GymScope.of(context).repository.addSet(log.log.id);
    await _load();
  }

  Future<void> _deleteSet(WorkoutSetLog set) async {
    await GymScope.of(
      context,
    ).repository.deleteSet(set.id, set.workoutExerciseLogId);
    await _load();
  }

  Future<void> _saveSet(WorkoutSetLog set, {bool reload = false}) async {
    await GymScope.of(context).repository.updateSet(set);
    if (reload) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final log = _log;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '${context.l10n.t('editSession')} · ${widget.exercise.name}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: context.l10n.t('cancel'),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (log == null)
                    EmptyState(message: context.l10n.t('noHistory'))
                  else ...<Widget>[
                    for (final set in log.sets)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _EditSetRow(
                          key: ValueKey<int>(set.id),
                          set: set,
                          type: widget.exercise.type,
                          onSave: _saveSet,
                          onDelete: _deleteSet,
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: _addSet,
                      icon: const Icon(Icons.add),
                      label: Text(context.l10n.t('addSet')),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditSetRow extends StatefulWidget {
  const _EditSetRow({
    required this.set,
    required this.type,
    required this.onSave,
    required this.onDelete,
    super.key,
  });

  final WorkoutSetLog set;
  final ExerciseType type;
  final Future<void> Function(WorkoutSetLog set, {bool reload}) onSave;
  final Future<void> Function(WorkoutSetLog set) onDelete;

  @override
  State<_EditSetRow> createState() => _EditSetRowState();
}

class _EditSetRowState extends State<_EditSetRow> {
  late final TextEditingController _weightController = TextEditingController(
    text: widget.set.weight == null ? '' : formatWeight(widget.set.weight!),
  );
  late final TextEditingController _repsController = TextEditingController(
    text: widget.set.reps?.toString() ?? '',
  );

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
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
                  onChanged: (value) => widget.onSave(
                    _composedSet(isCompleted: value ?? false),
                    reload: true,
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.t('delete'),
                  onPressed: () => widget.onDelete(widget.set),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                if (widget.type == ExerciseType.weighted) ...<Widget>[
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: <TextInputFormatter>[
                        decimalWeightFormatter(),
                      ],
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText:
                            '${context.l10n.t('weight')} ${weightUnitLabel(context)}',
                      ),
                      onChanged: (_) => widget.onSave(_composedSet()),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: context.l10n.t('reps'),
                    ),
                    onChanged: (_) => widget.onSave(_composedSet()),
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

