import 'package:flutter_test/flutter_test.dart';
import 'package:personal_gym_progress_notebook/core/errors/app_exception.dart';
import 'package:personal_gym_progress_notebook/data/gym_repository.dart';
import 'package:personal_gym_progress_notebook/features/workout/domain/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_harness.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late TestDb db;

  setUp(() async => db = await TestDb.create());
  tearDown(() => db.dispose());

  group('program management', () {
    test('creating a program makes it active and stores its days', () async {
      final seeded = await seedProgram(db.repository);
      final snapshot = await db.repository.activeProgram();
      expect(snapshot!.program.id, seeded.programId);
      expect(snapshot.program.isActive, isTrue);
      expect(snapshot.days.single.day.name, 'Push');
      expect(snapshot.days.single.day.weekDay, 0);
    });

    test('creating a second program deactivates the first', () async {
      final first = await seedProgram(db.repository, programName: 'Old');
      await db.repository.createProgram(
        name: 'New',
        days: const <WorkoutDayDraft>[
          WorkoutDayDraft(weekDay: 1, name: 'Pull'),
        ],
      );
      final active = await db.repository.activeProgram();
      expect(active!.program.name, 'New');
      expect(active.program.id, isNot(first.programId));
    });

    test('createProgram with no days throws localized error', () async {
      await expectLater(
        db.repository.createProgram(name: 'X', days: const <WorkoutDayDraft>[]),
        throwsA(isA<AppException>()
            .having((e) => e.l10nKey, 'l10nKey', 'atLeastOneDay')),
      );
    });

    test('updateProgramName trims and persists', () async {
      final seeded = await seedProgram(db.repository);
      await db.repository.updateProgramName(seeded.programId, '  Renamed  ');
      final snapshot = await db.repository.activeProgram();
      expect(snapshot!.program.name, 'Renamed');
    });

    test('archive removes active program; restore swaps active back',
        () async {
      final seeded = await seedProgram(db.repository, programName: 'A');
      await db.repository.archiveProgram(seeded.programId);
      expect(await db.repository.activeProgram(), isNull);

      await db.repository.createProgram(
        name: 'B',
        days: const <WorkoutDayDraft>[WorkoutDayDraft(weekDay: 2, name: 'D')],
      );
      await db.repository.restoreProgram(seeded.programId);

      final active = await db.repository.activeProgram();
      expect(active!.program.name, 'A');
      final archived = await db.repository.archivedPrograms();
      expect(archived, isEmpty); // B was deactivated, not archived
    });
  });

  group('workout day management', () {
    test('addWorkoutDay appends with increasing sort order', () async {
      final seeded = await seedProgram(db.repository);
      await db.repository.addWorkoutDay(
        programId: seeded.programId,
        name: 'Pull',
        weekDay: 2,
      );
      final snapshot = await db.repository.activeProgram();
      expect(snapshot!.days.map((d) => d.day.name), <String>['Push', 'Pull']);
      expect(
        snapshot.days[1].day.sortOrder,
        greaterThan(snapshot.days[0].day.sortOrder),
      );
    });

    test('updateWorkoutDay changes name and week day', () async {
      final seeded = await seedProgram(db.repository);
      await db.repository.updateWorkoutDay(
        workoutDayId: seeded.dayId,
        name: 'Leg Day',
        weekDay: 4,
      );
      final snapshot = await db.repository.activeProgram();
      expect(snapshot!.days.single.day.name, 'Leg Day');
      expect(snapshot.days.single.day.weekDay, 4);
    });

    test('deleteWorkoutDay hides day but keeps completed history', () async {
      final seeded = await seedProgram(db.repository);
      await completeSession(db.repository, seeded.dayId,
          <({double? weight, int reps})>[(weight: 40, reps: 10)]);
      await db.repository.deleteWorkoutDay(seeded.dayId);

      final snapshot = await db.repository.activeProgram();
      expect(snapshot!.days, isEmpty);
      expect(
        await db.repository.exerciseHistory(seeded.exerciseId),
        hasLength(1),
      );
    });

    test('moveWorkoutDay swaps neighbours and ignores out-of-range moves',
        () async {
      final seeded = await seedProgram(db.repository);
      await db.repository.addWorkoutDay(
        programId: seeded.programId,
        name: 'Pull',
        weekDay: 2,
      );
      await db.repository.moveWorkoutDay(
        programId: seeded.programId,
        workoutDayId: seeded.dayId,
        direction: 1,
      );
      var snapshot = await db.repository.activeProgram();
      expect(snapshot!.days.map((d) => d.day.name), <String>['Pull', 'Push']);

      // Moving the last day further down must be a no-op.
      await db.repository.moveWorkoutDay(
        programId: seeded.programId,
        workoutDayId: seeded.dayId,
        direction: 1,
      );
      snapshot = await db.repository.activeProgram();
      expect(snapshot!.days.map((d) => d.day.name), <String>['Pull', 'Push']);
    });
  });

  group('exercise management', () {
    test('updateExercise changes name, type and default sets', () async {
      final seeded = await seedProgram(db.repository);
      final snapshot = await db.repository.activeProgram();
      final assignment = snapshot!.days.single.exercises.single;

      await db.repository.updateExercise(
        assignmentId: assignment.assignment.id,
        exerciseId: seeded.exerciseId,
        name: 'Push-ups',
        type: ExerciseType.repsOnly,
        defaultSets: 5,
        targetMuscle: 'chest',
      );

      final updated = await db.repository.activeProgram();
      final exercise = updated!.days.single.exercises.single;
      expect(exercise.exercise.name, 'Push-ups');
      expect(exercise.exercise.type, ExerciseType.repsOnly);
      expect(exercise.exercise.targetMuscle, 'chest');
      expect(exercise.assignment.defaultSets, 5);
    });

    test('starting a day whose only exercise was deleted throws', () async {
      final seeded = await seedProgram(db.repository);
      final snapshot = await db.repository.activeProgram();
      final assignment = snapshot!.days.single.exercises.single;
      await db.repository.deleteExerciseAssignment(
        assignmentId: assignment.assignment.id,
        exerciseId: seeded.exerciseId,
      );
      await expectLater(
        db.repository.startWorkout(seeded.dayId),
        throwsA(isA<AppException>()
            .having((e) => e.l10nKey, 'l10nKey', 'addAtLeastOneExercise')),
      );
    });

    test('startWorkout on missing day throws localized error', () async {
      await seedProgram(db.repository);
      await expectLater(
        db.repository.startWorkout(99999),
        throwsA(isA<AppException>()
            .having((e) => e.l10nKey, 'l10nKey', 'workoutDayNotFound')),
      );
    });
  });

  group('session lifecycle', () {
    test('startWorkout creates default sets; reps-only sets have no weight',
        () async {
      final seeded = await seedProgram(
        db.repository,
        type: ExerciseType.repsOnly,
        defaultSets: 4,
      );
      final session = await db.repository.startWorkout(seeded.dayId);
      final sets = session.exercises.single.sets;
      expect(sets, hasLength(4));
      expect(sets.map((s) => s.setNumber), <int>[1, 2, 3, 4]);
      expect(sets.every((s) => s.weight == null), isTrue);
      expect(sets.every((s) => !s.isCompleted), isTrue);
    });

    test('starting again returns the same in-progress session', () async {
      final seeded = await seedProgram(db.repository);
      final first = await db.repository.startWorkout(seeded.dayId);
      final second = await db.repository.startWorkout(seeded.dayId);
      expect(second.session.id, first.session.id);
    });

    test('discarding a session frees the slot and hides it from progress',
        () async {
      final seeded = await seedProgram(db.repository);
      final session = await db.repository.startWorkout(seeded.dayId);
      await db.repository.discardSession(session.session.id);

      expect(await db.repository.inProgressSession(), isNull);
      final overview = await db.repository.progressOverview();
      expect(overview.recentSessions, isEmpty);
      expect(overview.bests, isEmpty);
    });

    test('in-progress session is recoverable with its recorded values',
        () async {
      final seeded = await seedProgram(db.repository);
      final session = await db.repository.startWorkout(seeded.dayId);
      await db.repository.updateSet(
        session.exercises.single.sets.first
            .copyWith(weight: 62.5, reps: 5, isCompleted: true),
      );

      final recovered = await db.repository.inProgressSession();
      expect(recovered!.session.id, session.session.id);
      final set = recovered.exercises.single.sets.first;
      expect(set.weight, 62.5);
      expect(set.reps, 5);
      expect(set.isCompleted, isTrue);
    });
  });

  group('history and progress queries', () {
    test('history uses exercise identity, not name', () async {
      final seeded = await seedProgram(db.repository);
      await completeSession(db.repository, seeded.dayId,
          <({double? weight, int reps})>[(weight: 40, reps: 10)]);
      // A second exercise with the same name must not pollute history.
      await db.repository.addExercise(
        workoutDayId: seeded.dayId,
        name: 'Bench Press',
        type: ExerciseType.weighted,
        defaultSets: 2,
      );
      final history = await db.repository.exerciseHistory(seeded.exerciseId);
      expect(history, hasLength(1));
    });

    test('history lists sessions newest first with only completed sets',
        () async {
      final seeded = await seedProgram(db.repository, defaultSets: 2);
      await completeSession(db.repository, seeded.dayId,
          <({double? weight, int reps})>[(weight: 40, reps: 10)]);
      await completeSession(db.repository, seeded.dayId,
          <({double? weight, int reps})>[(weight: 45, reps: 8)]);

      final history = await db.repository.exerciseHistory(seeded.exerciseId);
      expect(history, hasLength(2));
      expect(history.first.sets.single.weight, 45);
      expect(history.last.sets.single.weight, 40);
      // The untouched second default set was never completed -> excluded.
      expect(history.first.sets, hasLength(1));
    });

    test('progress overview counts completed sets per session', () async {
      final seeded = await seedProgram(db.repository, defaultSets: 3);
      await completeSession(db.repository, seeded.dayId,
          <({double? weight, int reps})>[
            (weight: 40, reps: 10),
            (weight: 42.5, reps: 8),
          ]);
      final overview = await db.repository.progressOverview();
      expect(overview.recentSessions.single.completedSetCount, 2);
      expect(overview.bests.single.best!.weight, 42.5);
    });

    test('editing a past session set updates the best value', () async {
      final seeded = await seedProgram(db.repository);
      await completeSession(db.repository, seeded.dayId,
          <({double? weight, int reps})>[(weight: 40, reps: 10)]);

      final overview = await db.repository.progressOverview();
      final session = overview.recentSessions.single.session;
      final snapshot = await db.repository.sessionSnapshot(session.id);
      await db.repository.updateSet(
        snapshot.exercises.single.sets.first.copyWith(weight: 100, reps: 3),
      );

      final best = await db.repository.bestForExercise(
        seeded.exerciseId,
        ExerciseType.weighted,
      );
      expect(best!.weight, 100);
      expect(best.reps, 3);
    });

    test('previous session tracks per exercise across mixed days', () async {
      final seeded = await seedProgram(db.repository);
      final secondExercise = await db.repository.addExercise(
        workoutDayId: seeded.dayId,
        name: 'Squat',
        type: ExerciseType.weighted,
        defaultSets: 1,
      );
      final session = await db.repository.startWorkout(seeded.dayId);
      for (final log in session.exercises) {
        await db.repository.updateSet(
          log.sets.first.copyWith(
            weight: log.exercise.id == seeded.exerciseId ? 40 : 80,
            reps: 10,
            isCompleted: true,
          ),
        );
      }
      await db.repository.finishSession(session.session.id);

      final benchPrev =
          await db.repository.previousSessionForExercise(seeded.exerciseId);
      final squatPrev =
          await db.repository.previousSessionForExercise(secondExercise);
      expect(benchPrev!.sets.single.weight, 40);
      expect(squatPrev!.sets.single.weight, 80);
    });
  });

  group('program stores structure only (spec 4.5)', () {
    test('starting a workout creates EMPTY set rows - no program weights',
        () async {
      final seeded = await seedProgram(db.repository, defaultSets: 3);
      final session = await db.repository.startWorkout(seeded.dayId);
      final sets = session.exercises.single.sets;
      expect(sets, hasLength(3));
      expect(sets.every((s) => s.weight == null), isTrue,
          reason: 'weights must never come from the program template');
      expect(sets.every((s) => s.reps == null), isTrue,
          reason: 'reps must never come from the program template');
      expect(sets.every((s) => !s.isCompleted), isTrue);
    });

    test('weights logged in a session do not change the program template',
        () async {
      final seeded = await seedProgram(db.repository, defaultSets: 2);
      await completeSession(db.repository, seeded.dayId,
          <({double? weight, int reps})>[
            (weight: 40, reps: 12),
            (weight: 45, reps: 10),
          ]);

      // The template still only knows the set COUNT.
      final program = await db.repository.activeProgram();
      final assignment = program!.days.single.exercises.single;
      expect(assignment.assignment.defaultSets, 2);

      // And the next session starts empty again, with Previous available.
      final next = await db.repository.startWorkout(seeded.dayId);
      final sets = next.exercises.single.sets;
      expect(sets.every((s) => s.weight == null && s.reps == null), isTrue);
      expect(next.exercises.single.previous, isNotNull);
      expect(next.exercises.single.previous!.sets.first.weight, 40);
      expect(next.exercises.single.previous!.sets.last.weight, 45);
    });

    test('highlight (best) carries the date it was achieved', () async {
      final seeded = await seedProgram(db.repository);
      await completeSession(db.repository, seeded.dayId,
          <({double? weight, int reps})>[(weight: 50, reps: 8)]);

      final best = await db.repository.bestForExercise(
        seeded.exerciseId,
        ExerciseType.weighted,
      );
      expect(best!.weight, 50);
      expect(best.reps, 8);
      final now = DateTime.now();
      expect(best.date.difference(now).inMinutes.abs() < 5, isTrue,
          reason: 'highlight date must reflect when the best was achieved');
    });
  });
  group('target reps (WORKOUT_FLOW.md R1+R2)', () {
    test('R1: target reps are stored and read back; weight is never stored',
        () async {
      final seeded = await seedProgram(
        db.repository,
        defaultSets: 3,
        targetReps: const <int?>[12, 10, 8],
      );
      final program = await db.repository.activeProgram();
      final assignment = program!.days.single.exercises.single;
      expect(assignment.targetReps, <int?>[12, 10, 8]);

      // The planned-sets table must never carry a weight.
      final database = await db.appDatabase.database;
      final rows = await database.query('workout_day_exercise_sets');
      expect(rows, hasLength(3));
      expect(rows.every((r) => r['target_weight'] == null), isTrue);

      // Verify seeded ids stay linked.
      expect(assignment.exercise.id, seeded.exerciseId);
    });

    test('R1b: updateExercise replaces targets and set count', () async {
      final seeded = await seedProgram(
        db.repository,
        defaultSets: 3,
        targetReps: const <int?>[12, 10, 8],
      );
      final program = await db.repository.activeProgram();
      final assignment = program!.days.single.exercises.single;
      await db.repository.updateExercise(
        assignmentId: assignment.assignment.id,
        exerciseId: seeded.exerciseId,
        name: 'Bench Press',
        type: ExerciseType.weighted,
        defaultSets: 2,
        targetReps: const <int?>[15, null],
      );
      final after = await db.repository.activeProgram();
      final updated = after!.days.single.exercises.single;
      expect(updated.assignment.defaultSets, 2);
      expect(updated.targetReps, <int?>[15, null]);
    });

    test('R2: startWorkout pre-fills reps from targets, weight stays NULL',
        () async {
      final seeded = await seedProgram(
        db.repository,
        defaultSets: 3,
        targetReps: const <int?>[12, 10, 8],
      );
      final session = await db.repository.startWorkout(seeded.dayId);
      final sets = session.exercises.single.sets;
      expect(sets.map((s) => s.reps), <int?>[12, 10, 8]);
      expect(sets.every((s) => s.weight == null), isTrue);
      expect(sets.every((s) => !s.isCompleted), isTrue);
      // Targets are exposed for the "Target: X reps" labels.
      expect(session.exercises.single.targetReps, <int?>[12, 10, 8]);
    });

    test('R2b: without targets, sets start fully empty', () async {
      final seeded = await seedProgram(db.repository, defaultSets: 2);
      final session = await db.repository.startWorkout(seeded.dayId);
      final sets = session.exercises.single.sets;
      expect(sets.every((s) => s.reps == null && s.weight == null), isTrue);
    });
  });

  group('monthly report', () {
    test('sessionsBetween returns completed workouts with played sets',
        () async {
      final seeded = await seedProgram(db.repository);
      await completeSession(db.repository, seeded.dayId,
          <({double? weight, int reps})>[(weight: 40, reps: 12)]);
      await completeSession(db.repository, seeded.dayId,
          <({double? weight, int reps})>[(weight: 45, reps: 10)]);
      // A discarded session must not appear in the report.
      final cancelled = await db.repository.startWorkout(seeded.dayId);
      await db.repository.discardSession(cancelled.session.id);

      final now = DateTime.now();
      final start = DateTime(now.year, now.month);
      final end = DateTime(now.year, now.month + 1);
      final reports = await db.repository.sessionsBetween(start, end);

      expect(reports, hasLength(2));
      expect(reports.first.dayName, 'Push');
      // Newest first; each report carries the actual played sets.
      expect(reports.first.exercises.single.sets.single.weight, 45);
      expect(reports.last.exercises.single.sets.single.weight, 40);
      expect(reports.first.completedSetCount, 1);

      // A different month is empty.
      final lastMonth = await db.repository.sessionsBetween(
        DateTime(now.year, now.month - 1),
        start,
      );
      expect(lastMonth, isEmpty);
    });
  });

  group('reminder settings', () {
    test('persist enabled flag and hour', () async {
      await db.repository.saveSettings(
        languageCode: 'en',
        onboardingCompleted: true,
        remindersEnabled: true,
        reminderHour: 7,
      );
      final settings = await db.repository.settings();
      expect(settings.remindersEnabled, isTrue);
      expect(settings.reminderHour, 7);
    });

    test('default reminder settings are off at 18:00', () async {
      final settings = await db.repository.settings();
      expect(settings.remindersEnabled, isFalse);
      expect(settings.reminderHour, 18);
    });
  });

  group('settings edge cases', () {
    test('blank display name is stored as null', () async {
      await db.repository.saveSettings(
        languageCode: 'en',
        onboardingCompleted: true,
        displayName: '   ',
      );
      final settings = await db.repository.settings();
      expect(settings.displayName, isNull);
    });

    test('saveSettings without weightUnit keeps the previous unit', () async {
      await db.repository.saveSettings(
        languageCode: 'en',
        onboardingCompleted: true,
        weightUnit: 'lb',
      );
      await db.repository.saveSettings(
        languageCode: 'ar',
        onboardingCompleted: true,
      );
      final settings = await db.repository.settings();
      expect(settings.weightUnit, 'lb');
      expect(settings.languageCode, 'ar');
    });
  });
}
