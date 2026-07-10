import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:personal_gym_progress_notebook/core/errors/app_exception.dart';
import 'package:personal_gym_progress_notebook/data/gym_repository.dart';
import 'package:personal_gym_progress_notebook/database/app_database.dart';
import 'package:personal_gym_progress_notebook/features/workout/domain/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase appDatabase;
  late GymRepository repository;
  var dbCounter = 0;

  setUp(() async {
    dbCounter += 1;
    appDatabase = AppDatabase(
      databaseName:
          'gym_test_${DateTime.now().microsecondsSinceEpoch}_$dbCounter.db',
    );
    repository = GymRepository(appDatabase);
    await repository.init();
  });

  tearDown(() async {
    final path = p.join(
      await databaseFactory.getDatabasesPath(),
      appDatabase.databaseName,
    );
    await appDatabase.close();
    await databaseFactory.deleteDatabase(path);
  });

  Future<({int dayId, int exerciseId})> seedProgram({
    ExerciseType type = ExerciseType.weighted,
    int defaultSets = 2,
  }) async {
    await repository.createProgram(
      name: 'Test Program',
      days: const <WorkoutDayDraft>[WorkoutDayDraft(weekDay: 0, name: 'Push')],
    );
    final snapshot = await repository.activeProgram();
    final dayId = snapshot!.days.first.day.id;
    final exerciseId = await repository.addExercise(
      workoutDayId: dayId,
      name: 'Bench Press',
      type: type,
      defaultSets: defaultSets,
    );
    return (dayId: dayId, exerciseId: exerciseId);
  }

  /// Starts a session, fills every set with the given values, marks them
  /// completed and finishes. Returns the summary.
  Future<WorkoutSummary> completeSession(
    int dayId,
    List<({double? weight, int reps})> sets,
  ) async {
    final session = await repository.startWorkout(dayId);
    final logSets = session.exercises.first.sets;
    for (var index = 0;
        index < sets.length && index < logSets.length;
        index += 1) {
      await repository.updateSet(
        logSets[index].copyWith(
          weight: sets[index].weight,
          clearWeight: sets[index].weight == null,
          reps: sets[index].reps,
          isCompleted: true,
        ),
      );
    }
    return repository.finishSession(session.session.id);
  }

  group('previous session lookup', () {
    test('returns null when no previous session exists', () async {
      final seeded = await seedProgram();
      expect(
        await repository.previousSessionForExercise(seeded.exerciseId),
        isNull,
      );
    });

    test('returns the latest completed session and skips the active one',
        () async {
      final seeded = await seedProgram();
      await completeSession(seeded.dayId, <({double? weight, int reps})>[
        (weight: 40, reps: 10),
        (weight: 42.5, reps: 8),
      ]);
      await completeSession(seeded.dayId, <({double? weight, int reps})>[
        (weight: 45, reps: 6),
        (weight: 45, reps: 5),
      ]);

      final active = await repository.startWorkout(seeded.dayId);
      final previous = await repository.previousSessionForExercise(
        seeded.exerciseId,
        excludeSessionId: active.session.id,
      );

      expect(previous, isNotNull);
      expect(previous!.sets.first.weight, 45);
      expect(previous.sets.first.reps, 6);
    });

    test('ignores cancelled sessions', () async {
      final seeded = await seedProgram();
      final session = await repository.startWorkout(seeded.dayId);
      await repository.updateSet(
        session.exercises.first.sets.first
            .copyWith(weight: 100, reps: 1, isCompleted: true),
      );
      await repository.discardSession(session.session.id);

      expect(
        await repository.previousSessionForExercise(seeded.exerciseId),
        isNull,
      );
      expect(
        await repository.bestForExercise(
          seeded.exerciseId,
          ExerciseType.weighted,
        ),
        isNull,
      );
    });
  });

  group('best values', () {
    test('uses highest reps as tie breaker at the same weight', () async {
      final seeded = await seedProgram();
      await completeSession(seeded.dayId, <({double? weight, int reps})>[
        (weight: 45, reps: 6),
        (weight: 45, reps: 8),
      ]);

      final best = await repository.bestForExercise(
        seeded.exerciseId,
        ExerciseType.weighted,
      );
      expect(best!.weight, 45);
      expect(best.reps, 8);
    });

    test('finds best reps for reps-only exercises', () async {
      final seeded = await seedProgram(
        type: ExerciseType.repsOnly,
        defaultSets: 3,
      );
      await completeSession(seeded.dayId, <({double? weight, int reps})>[
        (weight: null, reps: 20),
        (weight: null, reps: 25),
        (weight: null, reps: 18),
      ]);

      final best = await repository.bestForExercise(
        seeded.exerciseId,
        ExerciseType.repsOnly,
      );
      expect(best!.reps, 25);
    });
  });

  group('finish session', () {
    test('first-ever completed workout counts as a new best', () async {
      final seeded = await seedProgram();
      final summary = await completeSession(
        seeded.dayId,
        <({double? weight, int reps})>[(weight: 40, reps: 10)],
      );
      expect(summary.newBestCount, 1);
      expect(summary.completedSetCount, 1);
    });

    test('beating the previous best counts, matching it does not', () async {
      final seeded = await seedProgram();
      await completeSession(
        seeded.dayId,
        <({double? weight, int reps})>[(weight: 40, reps: 10)],
      );
      final same = await completeSession(
        seeded.dayId,
        <({double? weight, int reps})>[(weight: 40, reps: 10)],
      );
      expect(same.newBestCount, 0);

      final heavier = await completeSession(
        seeded.dayId,
        <({double? weight, int reps})>[(weight: 42.5, reps: 8)],
      );
      expect(heavier.newBestCount, 1);
    });

    test('throws a localized error when no set is completed', () async {
      final seeded = await seedProgram();
      final session = await repository.startWorkout(seeded.dayId);
      await expectLater(
        repository.finishSession(session.session.id),
        throwsA(
          isA<AppException>().having(
            (e) => e.l10nKey,
            'l10nKey',
            'emptyWorkoutWarning',
          ),
        ),
      );
    });
  });

  group('history retention', () {
    test('deleting an exercise keeps its workout history', () async {
      final seeded = await seedProgram();
      await completeSession(
        seeded.dayId,
        <({double? weight, int reps})>[(weight: 40, reps: 10)],
      );

      final program = await repository.activeProgram();
      final assignment = program!.days.first.exercises.first;
      await repository.deleteExerciseAssignment(
        assignmentId: assignment.assignment.id,
        exerciseId: assignment.exercise.id,
      );

      final history = await repository.exerciseHistory(seeded.exerciseId);
      expect(history, hasLength(1));
      final overview = await repository.progressOverview();
      expect(overview.bests, hasLength(1));
    });

    test('archiving a program keeps history and restore reactivates it',
        () async {
      final seeded = await seedProgram();
      await completeSession(
        seeded.dayId,
        <({double? weight, int reps})>[(weight: 40, reps: 10)],
      );

      final program = await repository.activeProgram();
      await repository.archiveProgram(program!.program.id);
      expect(await repository.activeProgram(), isNull);

      final archived = await repository.archivedPrograms();
      expect(archived, hasLength(1));
      expect(
        await repository.exerciseHistory(seeded.exerciseId),
        hasLength(1),
      );

      await repository.restoreProgram(archived.first.id);
      final restored = await repository.activeProgram();
      expect(restored, isNotNull);
      expect(restored!.program.id, program.program.id);
    });
  });

  group('set management', () {
    test('set numbers stay sequential after deleting a middle set', () async {
      final seeded = await seedProgram(defaultSets: 3);
      final session = await repository.startWorkout(seeded.dayId);
      final sets = session.exercises.first.sets;
      expect(sets.map((set) => set.setNumber), <int>[1, 2, 3]);

      await repository.deleteSet(sets[1].id, sets[1].workoutExerciseLogId);

      final reloaded = await repository.sessionSnapshot(session.session.id);
      expect(
        reloaded.exercises.first.sets.map((set) => set.setNumber),
        <int>[1, 2],
      );
    });

    test('addSet appends with the next set number', () async {
      final seeded = await seedProgram(defaultSets: 2);
      final session = await repository.startWorkout(seeded.dayId);
      await repository.addSet(session.exercises.first.log.id);

      final reloaded = await repository.sessionSnapshot(session.session.id);
      expect(
        reloaded.exercises.first.sets.map((set) => set.setNumber),
        <int>[1, 2, 3],
      );
    });
  });

  group('settings', () {
    test('persists language, name and weight unit', () async {
      await repository.saveSettings(
        languageCode: 'ar',
        onboardingCompleted: true,
        displayName: 'Hla',
        weightUnit: 'lb',
      );
      final settings = await repository.settings();
      expect(settings.languageCode, 'ar');
      expect(settings.displayName, 'Hla');
      expect(settings.weightUnit, 'lb');
      expect(settings.onboardingCompleted, isTrue);
    });
  });
}
