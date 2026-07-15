import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_gym_progress_notebook/app/gym_app_controller.dart';
import 'package:personal_gym_progress_notebook/core/errors/app_exception.dart';
import 'package:personal_gym_progress_notebook/data/gym_repository.dart';
import 'package:personal_gym_progress_notebook/features/workout/domain/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_harness.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late TestDb db;
  late GymAppController controller;

  setUp(() async {
    db = await TestDb.create();
    controller = GymAppController(db.repository);
    await controller.load();
  });

  tearDown(() => db.dispose());

  test('load initializes defaults for a fresh install', () {
    expect(controller.isReady, isTrue);
    expect(controller.lastError, isNull);
    expect(controller.settings, isNotNull);
    expect(controller.settings!.isReady, isFalse);
    expect(controller.program, isNull);
    expect(controller.activeSession, isNull);
    expect(controller.locale, const Locale('en'));
    expect(controller.weightUnit, 'kg');
  });

  test('completeOnboarding persists language and name', () async {
    await controller.completeOnboarding(languageCode: 'ar', displayName: 'هلا');
    expect(controller.settings!.isReady, isTrue);
    expect(controller.locale, const Locale('ar'));
    expect(controller.settings!.displayName, 'هلا');
  });

  test('changeLanguage and changeWeightUnit update state independently',
      () async {
    await controller.completeOnboarding(languageCode: 'en');
    await controller.changeWeightUnit('lb');
    expect(controller.weightUnit, 'lb');
    await controller.changeLanguage('ar');
    expect(controller.locale, const Locale('ar'));
    expect(controller.weightUnit, 'lb');
  });

  test('createProgram rejects blank names with a localized error', () async {
    await expectLater(
      controller.createProgram(name: '   ', days: const <WorkoutDayDraft>[
        WorkoutDayDraft(weekDay: 0, name: 'Push'),
      ]),
      throwsA(isA<AppException>()
          .having((e) => e.l10nKey, 'l10nKey', 'nameRequired')),
    );
  });

  test('createProgram selects the Program tab and loads the snapshot',
      () async {
    await controller.createProgram(
      name: 'Plan',
      days: const <WorkoutDayDraft>[WorkoutDayDraft(weekDay: 0, name: 'Push')],
    );
    expect(controller.selectedTab, 1);
    expect(controller.program!.program.name, 'Plan');
  });

  test('startWorkout activates a session and selects the Workout tab',
      () async {
    final seeded = await seedProgram(db.repository);
    final resumed = await controller.startWorkout(seeded.dayId);
    expect(resumed, isFalse);
    expect(controller.selectedTab, 2);
    expect(controller.activeSession, isNotNull);
  });

  test('startWorkout reports when a different-day session was resumed',
      () async {
    final seeded = await seedProgram(db.repository);
    final otherDayId = await db.repository.addWorkoutDay(
      programId: seeded.programId,
      name: 'Pull',
      weekDay: 3,
    );
    await db.repository.addExercise(
      workoutDayId: otherDayId,
      name: 'Row',
      type: ExerciseType.weighted,
      defaultSets: 2,
    );

    await controller.startWorkout(seeded.dayId);
    final resumed = await controller.startWorkout(otherDayId);
    expect(resumed, isTrue);
    expect(controller.activeSession!.session.workoutDayId, seeded.dayId);
  });

  test('snoozeActiveSessionBanner remembers the snoozed session id', () async {
    final seeded = await seedProgram(db.repository);
    await controller.startWorkout(seeded.dayId);
    controller.snoozeActiveSessionBanner();
    expect(controller.snoozedSessionId, controller.activeSession!.session.id);
  });

  test('updateSetAndRefresh persists values into the refreshed snapshot',
      () async {
    final seeded = await seedProgram(db.repository);
    await controller.startWorkout(seeded.dayId);
    final set = controller.activeSession!.exercises.single.sets.first;
    await controller.updateSetAndRefresh(
      set.copyWith(weight: 42.5, reps: 8, isCompleted: true),
    );
    final refreshed = controller.activeSession!.exercises.single.sets.first;
    expect(refreshed.weight, 42.5);
    expect(refreshed.reps, 8);
    expect(refreshed.isCompleted, isTrue);
  });

  test('addSet and deleteSet keep the active snapshot in sync', () async {
    final seeded = await seedProgram(db.repository, defaultSets: 2);
    await controller.startWorkout(seeded.dayId);
    final logId = controller.activeSession!.exercises.single.log.id;

    await controller.addSet(logId);
    expect(controller.activeSession!.exercises.single.sets, hasLength(3));

    final middle = controller.activeSession!.exercises.single.sets[1];
    await controller.deleteSet(middle.id, logId);
    final sets = controller.activeSession!.exercises.single.sets;
    expect(sets, hasLength(2));
    expect(sets.map((s) => s.setNumber), <int>[1, 2]);
  });

  test('finishWorkout produces a summary, clears the session, opens Progress',
      () async {
    final seeded = await seedProgram(db.repository);
    await controller.startWorkout(seeded.dayId);
    final set = controller.activeSession!.exercises.single.sets.first;
    await controller.updateSetAndRefresh(
      set.copyWith(weight: 40, reps: 10, isCompleted: true),
    );

    final summary = await controller.finishWorkout();
    expect(summary.completedSetCount, 1);
    expect(summary.newBestCount, 1);
    expect(controller.latestSummary, summary);
    expect(controller.activeSession, isNull);
    expect(controller.selectedTab, 3);
    expect(controller.progress.bests, hasLength(1));
  });

  test('R3: completeExercise marks valid sets done and deletes empty ones',
      () async {
    final seeded = await seedProgram(db.repository, defaultSets: 3);
    await controller.startWorkout(seeded.dayId);
    final log = controller.activeSession!.exercises.single;
    // Fill only the first set; leave sets 2 and 3 empty.
    await controller.updateSetSilently(
      log.sets.first.copyWith(weight: 40, reps: 12),
    );

    await controller.completeExercise(log.log.id);

    final after = controller.activeSession!.exercises.single;
    expect(after.sets, hasLength(1));
    expect(after.sets.single.isCompleted, isTrue);
    expect(after.sets.single.setNumber, 1);
  });

  test('R3b: completeExercise with no valid sets throws localized error',
      () async {
    final seeded = await seedProgram(db.repository, defaultSets: 2);
    await controller.startWorkout(seeded.dayId);
    final log = controller.activeSession!.exercises.single;
    await expectLater(
      controller.completeExercise(log.log.id),
      throwsA(isA<AppException>()
          .having((e) => e.l10nKey, 'l10nKey', 'emptyExerciseWarning')),
    );
    // Nothing was deleted or completed.
    final after = controller.activeSession!.exercises.single;
    expect(after.sets, hasLength(2));
    expect(after.sets.every((s) => !s.isCompleted), isTrue);
  });

  test('finishWorkout without an active session throws', () async {
    await expectLater(
      controller.finishWorkout(),
      throwsA(isA<AppException>()
          .having((e) => e.l10nKey, 'l10nKey', 'sessionNotFound')),
    );
  });

  test('discardWorkout cancels the active session', () async {
    final seeded = await seedProgram(db.repository);
    await controller.startWorkout(seeded.dayId);
    await controller.discardWorkout();
    expect(controller.activeSession, isNull);
    expect(controller.progress.recentSessions, isEmpty);
  });

  test('restoreProgram refreshes both active and archived lists', () async {
    final seeded = await seedProgram(db.repository);
    await controller.archiveProgram(seeded.programId);
    expect(controller.program, isNull);
    expect(controller.archivedPrograms, hasLength(1));

    await controller.restoreProgram(seeded.programId);
    expect(controller.program!.program.id, seeded.programId);
    expect(controller.archivedPrograms, isEmpty);
  });
}
