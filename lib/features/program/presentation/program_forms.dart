import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/localization/app_localizations.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/input_validation.dart';
import '../../../core/week_days.dart';
import '../../../data/gym_repository.dart';
import '../../common/presentation/common_widgets.dart';
import '../../workout/domain/models.dart';

Future<void> showCreateProgramSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _ProgramFormSheet(),
  );
}

Future<void> showEditProgramSheet(BuildContext context, Program program) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ProgramNameSheet(program: program),
  );
}

Future<void> showWorkoutDaySheet(
  BuildContext context, {
  required int programId,
  WorkoutDay? day,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _WorkoutDayFormSheet(programId: programId, day: day),
  );
}

Future<void> showExerciseSheet(
  BuildContext context, {
  required int workoutDayId,
  ExerciseAssignment? assignment,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        _ExerciseFormSheet(workoutDayId: workoutDayId, assignment: assignment),
  );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
                          title,
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
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgramFormSheet extends StatefulWidget {
  const _ProgramFormSheet();

  @override
  State<_ProgramFormSheet> createState() => _ProgramFormSheetState();
}

class _ProgramFormSheetState extends State<_ProgramFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final Set<int> _days = <int>{currentAppWeekDay(DateTime.now())};
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: context.l10n.t('createProgram'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              maxLength: 60,
              decoration: InputDecoration(
                labelText: context.l10n.t('programName'),
              ),
              validator: (value) => InputValidation.requiredText(value ?? '')
                  ? null
                  : context.l10n.t('nameRequired'),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.t('selectTrainingDays'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final day in weekDayValues)
                  FilterChip(
                    label: Text(weekDayName(day, context.l10n.locale)),
                    selected: _days.contains(day),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _days.add(day);
                        } else {
                          _days.remove(day);
                        }
                      });
                    },
                  ),
              ],
            ),
            if (_days.isEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                context.l10n.t('atLeastOneDay'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(context.l10n.t('save')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) || _days.isEmpty) {
      setState(() {});
      return;
    }
    setState(() => _saving = true);
    try {
      final messenger = ScaffoldMessenger.of(context);
      final savedLabel = context.l10n.t('programSaved');
      final sortedDays = _days.toList()..sort();
      await GymScope.of(context).createProgram(
        name: _nameController.text,
        days: <WorkoutDayDraft>[
          for (final day in sortedDays)
            WorkoutDayDraft(
              weekDay: day,
              name: weekDayName(day, context.l10n.locale),
            ),
        ],
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
      messenger.showSnackBar(SnackBar(content: Text(savedLabel)));
    } catch (error) {
      if (mounted) {
        showAppError(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _ProgramNameSheet extends StatefulWidget {
  const _ProgramNameSheet({required this.program});

  final Program program;

  @override
  State<_ProgramNameSheet> createState() => _ProgramNameSheetState();
}

class _ProgramNameSheetState extends State<_ProgramNameSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.program.name,
  );
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: context.l10n.t('editProgram'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _controller,
            maxLength: 60,
            decoration: InputDecoration(
              labelText: context.l10n.t('programName'),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(context.l10n.t('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!InputValidation.requiredText(_controller.text)) {
      showAppError(context, const AppException('nameRequired'));
      return;
    }
    setState(() => _saving = true);
    try {
      final messenger = ScaffoldMessenger.of(context);
      final savedLabel = context.l10n.t('programSaved');
      await GymScope.of(
        context,
      ).updateProgramName(widget.program.id, _controller.text);
      if (mounted) {
        Navigator.of(context).pop();
      }
      messenger.showSnackBar(SnackBar(content: Text(savedLabel)));
    } catch (error) {
      if (mounted) {
        showAppError(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _WorkoutDayFormSheet extends StatefulWidget {
  const _WorkoutDayFormSheet({required this.programId, this.day});

  final int programId;
  final WorkoutDay? day;

  @override
  State<_WorkoutDayFormSheet> createState() => _WorkoutDayFormSheetState();
}

class _WorkoutDayFormSheetState extends State<_WorkoutDayFormSheet> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.day?.name ?? '',
  );
  late int _weekDay = widget.day?.weekDay ?? currentAppWeekDay(DateTime.now());
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: widget.day == null
          ? context.l10n.t('addWorkoutDay')
          : context.l10n.t('editWorkoutDay'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _nameController,
            maxLength: 60,
            decoration: InputDecoration(
              labelText: context.l10n.t('workoutDayName'),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _weekDay,
            decoration: InputDecoration(labelText: context.l10n.t('weekDay')),
            items: <DropdownMenuItem<int>>[
              for (final day in weekDayValues)
                DropdownMenuItem<int>(
                  value: day,
                  child: Text(weekDayName(day, context.l10n.locale)),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _weekDay = value);
              }
            },
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(context.l10n.t('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!InputValidation.requiredText(_nameController.text)) {
      showAppError(context, const AppException('nameRequired'));
      return;
    }
    setState(() => _saving = true);
    try {
      final messenger = ScaffoldMessenger.of(context);
      final savedLabel = context.l10n.t('saved');
      final controller = GymScope.of(context);
      final day = widget.day;
      if (day == null) {
        await controller.addWorkoutDay(
          programId: widget.programId,
          name: _nameController.text,
          weekDay: _weekDay,
        );
      } else {
        await controller.updateWorkoutDay(
          workoutDayId: day.id,
          name: _nameController.text,
          weekDay: _weekDay,
        );
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
      messenger.showSnackBar(SnackBar(content: Text(savedLabel)));
    } catch (error) {
      if (mounted) {
        showAppError(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _ExerciseFormSheet extends StatefulWidget {
  const _ExerciseFormSheet({required this.workoutDayId, this.assignment});

  final int workoutDayId;
  final ExerciseAssignment? assignment;

  @override
  State<_ExerciseFormSheet> createState() => _ExerciseFormSheetState();
}

class _ExerciseFormSheetState extends State<_ExerciseFormSheet> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.assignment?.exercise.name ?? '',
  );
  late ExerciseType _type =
      widget.assignment?.exercise.type ?? ExerciseType.weighted;
  late int _defaultSets = widget.assignment?.assignment.defaultSets ?? 3;
  late String? _muscle = widget.assignment?.exercise.targetMuscle;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final muscleOptions = <String>[
      'chest',
      'back',
      'shoulders',
      'biceps',
      'triceps',
      'forearms',
      'quads',
      'hamstrings',
      'glutes',
      'calves',
      'core',
      'fullBody',
    ];
    return _SheetFrame(
      title: widget.assignment == null
          ? context.l10n.t('addExercise')
          : context.l10n.t('editExercise'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _nameController,
            maxLength: 80,
            decoration: InputDecoration(
              labelText: context.l10n.t('exerciseName'),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.t('exerciseType'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SegmentedButton<ExerciseType>(
            segments: <ButtonSegment<ExerciseType>>[
              ButtonSegment<ExerciseType>(
                value: ExerciseType.weighted,
                icon: const Icon(Icons.fitness_center),
                label: Text(context.l10n.t('weighted')),
              ),
              ButtonSegment<ExerciseType>(
                value: ExerciseType.repsOnly,
                icon: const Icon(Icons.repeat),
                label: Text(context.l10n.t('repsOnly')),
              ),
            ],
            selected: <ExerciseType>{_type},
            onSelectionChanged: (selection) {
              setState(() => _type = selection.single);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            initialValue: _muscle,
            decoration: InputDecoration(
              labelText: context.l10n.t('targetMuscle'),
            ),
            items: <DropdownMenuItem<String?>>[
              DropdownMenuItem<String?>(
                value: null,
                child: Text(context.l10n.t('optional')),
              ),
              for (final key in muscleOptions)
                DropdownMenuItem<String?>(
                  value: key,
                  child: Text(context.l10n.t(key)),
                ),
            ],
            onChanged: (value) => setState(() => _muscle = value),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  context.l10n.t('defaultSets'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton.outlined(
                tooltip: '-',
                onPressed: _defaultSets <= 1
                    ? null
                    : () => setState(() => _defaultSets -= 1),
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  _defaultSets.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton.outlined(
                tooltip: '+',
                onPressed: _defaultSets >= 20
                    ? null
                    : () => setState(() => _defaultSets += 1),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(context.l10n.t('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!InputValidation.requiredText(_nameController.text, maxLength: 80)) {
      showAppError(context, const AppException('nameRequired'));
      return;
    }
    setState(() => _saving = true);
    try {
      final messenger = ScaffoldMessenger.of(context);
      final savedLabel = context.l10n.t('exerciseSaved');
      final controller = GymScope.of(context);
      final assignment = widget.assignment;
      if (assignment == null) {
        await controller.addExercise(
          workoutDayId: widget.workoutDayId,
          name: _nameController.text,
          type: _type,
          defaultSets: _defaultSets,
          targetMuscle: _muscle,
        );
      } else {
        await controller.updateExercise(
          assignmentId: assignment.assignment.id,
          exerciseId: assignment.exercise.id,
          name: _nameController.text,
          type: _type,
          defaultSets: _defaultSets,
          targetMuscle: _muscle,
        );
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
      messenger.showSnackBar(SnackBar(content: Text(savedLabel)));
    } catch (error) {
      if (mounted) {
        showAppError(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
