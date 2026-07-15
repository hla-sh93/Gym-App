import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_gym_progress_notebook/app/app_scope.dart';
import 'package:personal_gym_progress_notebook/app/gym_app_controller.dart';
import 'package:personal_gym_progress_notebook/app/localization/app_localizations.dart';
import 'package:personal_gym_progress_notebook/app/theme.dart';
import 'package:personal_gym_progress_notebook/features/workout/domain/models.dart';
import 'package:personal_gym_progress_notebook/features/workout/presentation/workout_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_harness.dart';

/// Wizard-flow tests (WORKOUT_FLOW.md §5, W1–W8): the active workout opens
/// directly on the first exercise, targets pre-fill reps, Complete Exercise
/// advances the flow, and Finish only becomes primary at the end.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late TestDb db;
  late GymAppController controller;

  setUp(() async {
    db = await TestDb.create();
    controller = GymAppController(db.repository);
  });

  tearDown(() => db.dispose());

  /// Program with two exercises: Bench Press (weighted, targets 12/10/8)
  /// and Triceps Pushdown (weighted, 2 sets, no targets).
  Future<({int dayId, int benchId, int triId})> seedTwoExercises() async {
    final seeded = await seedProgram(
      db.repository,
      defaultSets: 3,
      targetReps: const <int?>[12, 10, 8],
    );
    final triId = await db.repository.addExercise(
      workoutDayId: seeded.dayId,
      name: 'Triceps Pushdown',
      type: ExerciseType.weighted,
      defaultSets: 2,
    );
    return (dayId: seeded.dayId, benchId: seeded.exerciseId, triId: triId);
  }

  Future<void> pumpWizard(WidgetTester tester, int dayId) async {
    useTallSurface(tester);
    await tester.runAsync(() => db.repository.saveSettings(
          languageCode: 'en',
          onboardingCompleted: true,
        ));
    await tester.runAsync(() => controller.startWorkout(dayId));
    await tester.runAsync(controller.load);
    await tester.pumpWidget(
      GymScope(
        controller: controller,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            locale: controller.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            home: const WorkoutScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets(
      'W1+W2: start opens the FIRST exercise directly with its set fields '
      'and a progress header', (tester) async {
    final seeded = await tester.runAsync(seedTwoExercises);
    await pumpWizard(tester, seeded!.dayId);

    // First exercise is OPEN immediately — set fields visible, no empty page.
    expect(find.text('Bench Press'), findsWidgets);
    expect(find.byType(TextField), findsWidgets);
    expect(find.text('Set 1'), findsOneWidget);
    expect(find.text('Set 3'), findsOneWidget);

    // Header: exercise 1 of 2 + progress bar.
    expect(find.textContaining('1'), findsWidgets);
    expect(find.text('Exercise 1 of 2'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // The second exercise is listed under Up Next (numbered), not open.
    expect(find.text('Up Next'), findsOneWidget);
    expect(find.textContaining('Triceps Pushdown'), findsOneWidget);

    // Complete Exercise is the primary action; Finish is not primary.
    expect(find.text('Complete Exercise'), findsOneWidget);
  });

  testWidgets(
      'W3: target reps from the program pre-fill the reps fields; '
      'weight fields start EMPTY', (tester) async {
    final seeded = await tester.runAsync(seedTwoExercises);
    await pumpWizard(tester, seeded!.dayId);

    // Targets shown per set.
    expect(find.textContaining('Target: 12'), findsOneWidget);
    expect(find.textContaining('Target: 10'), findsOneWidget);
    expect(find.textContaining('Target: 8'), findsOneWidget);

    // Reps fields pre-filled with targets; weight fields empty.
    final sets = controller.activeSession!.exercises.first.sets;
    expect(sets.map((s) => s.reps), <int?>[12, 10, 8]);
    expect(sets.every((s) => s.weight == null), isTrue,
        reason: 'weight must never come from the program');
  });

  testWidgets(
      'W4+W6: Complete Exercise marks it done and auto-opens the next; '
      'after the last one Finish Workout becomes the primary action',
      (tester) async {
    final seeded = await tester.runAsync(seedTwoExercises);
    await pumpWizard(tester, seeded!.dayId);

    // Log weights for the three bench sets (reps already pre-filled).
    final fields = find.byType(TextField);
    await typeText(tester, fields.at(0), '40'); // set 1 weight
    await typeText(tester, fields.at(2), '45'); // set 2 weight
    await typeText(tester, fields.at(4), '50'); // set 3 weight

    await pressButton<FilledButton>(tester, find.text('Complete Exercise'));

    // Bench is done; wizard advanced to exercise 2 of 2 automatically.
    expect(find.text('Exercise 2 of 2'), findsOneWidget);
    expect(find.textContaining('Triceps Pushdown'), findsWidgets);
    final bench = controller.activeSession!.exercises.first;
    expect(bench.sets.every((s) => s.isCompleted), isTrue);
    expect(bench.sets.first.weight, 40);

    // Complete the second exercise too.
    final fields2 = find.byType(TextField);
    await typeText(tester, fields2.at(0), '20');
    await typeText(tester, fields2.at(1), '15');
    await typeText(tester, fields2.at(2), '25');
    await typeText(tester, fields2.at(3), '12');
    await act(tester, () async {});
    await pressButton<FilledButton>(tester, find.text('Complete Exercise'));

    // All done: Finish Workout is now the primary (FilledButton) action.
    expect(find.text('Complete Exercise'), findsNothing);
    expect(
      find.ancestor(
        of: find.text('Finish Workout'),
        matching: find.byType(FilledButton),
      ),
      findsOneWidget,
    );
  });

  testWidgets('W5: Complete with no values shows an error and stays put',
      (tester) async {
    final seeded = await tester.runAsync(seedTwoExercises);
    // No targets for this test: use the second exercise day? Bench has
    // pre-filled reps from targets, so clear them first.
    await pumpWizard(tester, seeded!.dayId);
    final fields = find.byType(TextField);
    await typeText(tester, fields.at(1), ''); // clear reps set 1
    await typeText(tester, fields.at(3), ''); // clear reps set 2
    await typeText(tester, fields.at(5), ''); // clear reps set 3

    await pressButton<FilledButton>(tester, find.text('Complete Exercise'));

    expect(
      find.text('Enter at least one set before completing this exercise.'),
      findsOneWidget,
    );
    // Still on exercise 1.
    expect(find.text('Exercise 1 of 2'), findsOneWidget);
  });

  testWidgets(
      'W7: reps-only exercise has no weight fields and pre-fills targets',
      (tester) async {
    final seeded = await tester.runAsync(() => seedProgram(
          db.repository,
          exerciseName: 'Abs Crunches',
          type: ExerciseType.repsOnly,
          defaultSets: 2,
          targetReps: const <int?>[20, 18],
        ));
    await pumpWizard(tester, seeded!.dayId);

    expect(find.text('Abs Crunches'), findsWidgets);
    // One reps field per set, no weight fields (2 fields total).
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.textContaining('Target: 20'), findsOneWidget);
    final sets = controller.activeSession!.exercises.single.sets;
    expect(sets.map((s) => s.reps), <int?>[20, 18]);
  });

  testWidgets(
      'W8: empty sets are deleted on Complete and numbering stays sequential',
      (tester) async {
    final seeded = await tester.runAsync(seedTwoExercises);
    await pumpWizard(tester, seeded!.dayId);

    // Fill only set 1; clear the pre-filled reps of sets 2 and 3.
    final fields = find.byType(TextField);
    await typeText(tester, fields.at(0), '40');
    await typeText(tester, fields.at(3), '');
    await typeText(tester, fields.at(5), '');

    await pressButton<FilledButton>(tester, find.text('Complete Exercise'));

    final bench = controller.activeSession!.exercises.first;
    expect(bench.sets, hasLength(1), reason: 'empty sets must be deleted');
    expect(bench.sets.single.setNumber, 1);
    expect(bench.sets.single.isCompleted, isTrue);
    expect(bench.sets.single.weight, 40);
  });
}
