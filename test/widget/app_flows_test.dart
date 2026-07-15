import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_gym_progress_notebook/app/app.dart';
import 'package:personal_gym_progress_notebook/app/app_scope.dart';
import 'package:personal_gym_progress_notebook/app/gym_app_controller.dart';
import 'package:personal_gym_progress_notebook/app/localization/app_localizations.dart';
import 'package:personal_gym_progress_notebook/app/theme.dart';
import 'package:personal_gym_progress_notebook/core/week_days.dart';
import 'package:personal_gym_progress_notebook/features/workout/presentation/workout_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_harness.dart';

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

  Future<void> pumpApp(WidgetTester tester, {bool onboarded = true}) async {
    useTallSurface(tester);
    if (onboarded) {
      await tester.runAsync(() => db.repository.saveSettings(
            languageCode: 'en',
            onboardingCompleted: true,
            displayName: 'Hla',
          ));
    }
    await tester.runAsync(controller.load);
    await tester.pumpWidget(GymNotebookApp(controller: controller));
    await tester.pump();
    await tester.pump();
  }

  /// Mounts only the WorkoutScreen (no shell IndexedStack/overlay) so set-row
  /// interactions hit-test cleanly. Requires an already-loaded controller with
  /// an active session.
  Future<void> pumpWorkoutOnly(WidgetTester tester) async {
    useTallSurface(tester);
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

  group('IT-001 onboarding', () {
    testWidgets('first launch: choose Arabic, save name, land on RTL home',
        (tester) async {
      await pumpApp(tester, onboarded: false);
      expect(find.text('Choose your language'), findsOneWidget);

      await tester.tap(find.text('Arabic'));
      await tester.pump();
      expect(find.text('اختر اللغة'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'هلا');
      await pressButton<FilledButton>(tester, find.text('متابعة'));

      expect(controller.settings!.isReady, isTrue);
      expect(find.text('الرئيسية'), findsWidgets);
      expect(find.textContaining('هلا'), findsWidgets);
      final context = tester.element(find.text('الرئيسية').first);
      expect(Directionality.of(context), TextDirection.rtl);
    });
  });

  group('IT-003 active workout logging', () {
    testWidgets(
        'CRITICAL: typing weight+reps then completing the exercise keeps values',
        (tester) async {
      final seeded = await tester.runAsync(
        () => seedProgram(db.repository, defaultSets: 1),
      );
      await tester.runAsync(() => db.repository.saveSettings(
            languageCode: 'en',
            onboardingCompleted: true,
          ));
      await tester.runAsync(() => controller.startWorkout(seeded!.dayId));
      await pumpWorkoutOnly(tester);

      // The wizard opens the exercise directly — fields visible immediately.
      expect(find.text('Bench Press'), findsOneWidget);
      final fields = find.byType(TextField);
      await typeText(tester, fields.at(0), '42.5');
      await typeText(tester, fields.at(1), '10');

      await pressButton<FilledButton>(tester, find.text('Complete Exercise'));

      final set = controller.activeSession!.exercises.single.sets.first;
      expect(set.weight, 42.5, reason: 'typed weight must survive completion');
      expect(set.reps, 10, reason: 'typed reps must survive completion');
      expect(set.isCompleted, isTrue);
    });

    testWidgets('weight stepper +2.5 does not clobber typed reps',
        (tester) async {
      final seeded = await tester.runAsync(
        () => seedProgram(db.repository, defaultSets: 1),
      );
      await tester.runAsync(() => db.repository.saveSettings(
            languageCode: 'en',
            onboardingCompleted: true,
          ));
      await tester.runAsync(() => controller.startWorkout(seeded!.dayId));
      await pumpWorkoutOnly(tester);

      final fields = find.byType(TextField);
      await typeText(tester, fields.at(1), '8');
      await pressButton<OutlinedButton>(tester, find.text('+2.5'));

      final set = controller.activeSession!.exercises.single.sets.first;
      expect(set.weight, 2.5);
      expect(set.reps, 8, reason: 'stepper must not erase typed reps');
    });

    testWidgets('add set and delete set renumber rows in the UI',
        (tester) async {
      final seeded = await tester.runAsync(
        () => seedProgram(db.repository, defaultSets: 2),
      );
      await tester.runAsync(() => db.repository.saveSettings(
            languageCode: 'en',
            onboardingCompleted: true,
          ));
      await tester.runAsync(() => controller.startWorkout(seeded!.dayId));
      await pumpWorkoutOnly(tester);

      await pressButton<OutlinedButton>(tester, find.text('Add Set'));
      expect(find.text('Set 3'), findsOneWidget);

      await pressIconButton(
        tester,
        find.ancestor(
          of: find.byIcon(Icons.delete_outline).first,
          matching: find.byType(IconButton),
        ),
      );
      expect(find.text('Set 3'), findsNothing);
      expect(find.text('Set 1'), findsOneWidget);
      expect(find.text('Set 2'), findsOneWidget);
    });

    testWidgets('early finish with no completed sets shows localized warning',
        (tester) async {
      final seeded = await tester.runAsync(
        () => seedProgram(db.repository, defaultSets: 1),
      );
      await tester.runAsync(() => db.repository.saveSettings(
            languageCode: 'en',
            onboardingCompleted: true,
          ));
      await tester.runAsync(() => controller.startWorkout(seeded!.dayId));
      await pumpWorkoutOnly(tester);

      // Finish is only a secondary "early finish" link during the workout.
      await pressButton<TextButton>(
        tester,
        find.text('Finish workout early'),
      );
      expect(
        find.text('Log at least one completed set before finishing.'),
        findsOneWidget,
      );
    });

    testWidgets('finishing a logged workout produces a summary and best',
        (tester) async {
      final seeded = await tester.runAsync(
        () => seedProgram(db.repository, defaultSets: 1),
      );
      await tester.runAsync(() => db.repository.saveSettings(
            languageCode: 'en',
            onboardingCompleted: true,
          ));
      await tester.runAsync(() async {
        await controller.startWorkout(seeded!.dayId);
        final set = controller.activeSession!.exercises.single.sets.first;
        await controller.updateSetAndRefresh(
          set.copyWith(weight: 40, reps: 10, isCompleted: true),
        );
      });
      await pumpWorkoutOnly(tester);

      await pressButton<FilledButton>(tester, find.text('Finish Workout'));

      // The summary dialog renders with the computed counts.
      expect(find.text('Workout Summary'), findsOneWidget);
      expect(find.text('Completed sets'), findsOneWidget);
      expect(controller.latestSummary, isNotNull);
      expect(controller.latestSummary!.completedSetCount, 1);
      expect(controller.latestSummary!.newBestCount, 1);
      expect(controller.activeSession, isNull);

      // Dismiss the dialog to leave the tree clean.
      await pressButton<FilledButton>(tester, find.text('Done'));
    });
  });

  group('IT-004 previous session', () {
    testWidgets('second workout shows previous values per set',
        (tester) async {
      final seeded = await tester.runAsync(
        () => seedProgram(db.repository, defaultSets: 2),
      );
      await tester.runAsync(
        () => completeSession(db.repository, seeded!.dayId,
            <({double? weight, int reps})>[
              (weight: 40, reps: 10),
              (weight: 42.5, reps: 8),
            ]),
      );
      await tester.runAsync(() => db.repository.saveSettings(
            languageCode: 'en',
            onboardingCompleted: true,
          ));
      await tester.runAsync(() => controller.startWorkout(seeded!.dayId));
      await pumpWorkoutOnly(tester);

      expect(find.text('Previous'), findsOneWidget);
      // Set lines are color-coded RichText (weight blue, reps orange).
      expect(
        find.textContaining('40kg x 10', findRichText: true),
        findsWidgets,
      );
      expect(
        find.textContaining('42.5kg x 8', findRichText: true),
        findsWidgets,
      );
      // Highlight: highest weight with last-achieved date (spec 12.2.1).
      expect(find.textContaining('Highest weight'), findsWidgets);
      expect(find.textContaining('Last achieved'), findsWidgets);
      // Today's set rows start EMPTY — the program supplies no weights.
      final weightField = find.byType(TextField).first;
      expect(tester.widget<TextField>(weightField).controller!.text, '');
    });
  });

  group('home states', () {
    testWidgets('rest day shows the no-workout state', (tester) async {
      final restWeekDay = (currentAppWeekDay(DateTime.now()) + 1) % 7;
      await tester.runAsync(
        () => seedProgram(db.repository, weekDay: restWeekDay),
      );
      await pumpApp(tester);
      expect(find.text('No scheduled workout today.'), findsOneWidget);
    });

    testWidgets('training day shows the hero card with start button',
        (tester) async {
      final todayWeekDay = currentAppWeekDay(DateTime.now());
      await tester.runAsync(
        () => seedProgram(db.repository, weekDay: todayWeekDay),
      );
      await pumpApp(tester);
      expect(find.text('Start Workout'), findsWidgets);
      expect(find.text('Push'), findsWidgets);
      expect(find.textContaining('Hla'), findsOneWidget);
    });

    testWidgets('in-progress banner supports finish later', (tester) async {
      final seeded = await tester.runAsync(() => seedProgram(db.repository));
      await tester.runAsync(() => db.repository.startWorkout(seeded!.dayId));
      await pumpApp(tester);

      expect(find.text('Workout in progress'), findsWidgets);
      await tester.tap(find.text('Finish later'));
      await tester.pump();
      expect(find.text('Workout in progress'), findsNothing);
      expect(controller.activeSession, isNotNull);
    });
  });

  group('IT-008 localization switch', () {
    testWidgets('switching to Arabic flips direction and labels',
        (tester) async {
      await tester.runAsync(() => seedProgram(db.repository));
      await pumpApp(tester);

      await pressIconButton(
        tester,
        find.ancestor(
          of: find.byIcon(Icons.settings_outlined),
          matching: find.byType(IconButton),
        ),
      );
      // Let the settings route finish its push transition before interacting.
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Language'), findsOneWidget);

      await act(tester, () => tester.tap(find.text('Arabic')));

      expect(find.text('اللغة'), findsOneWidget);
      final context = tester.element(find.text('اللغة'));
      expect(Directionality.of(context), TextDirection.rtl);
    });

    testWidgets('changing weight unit relabels weight fields', (tester) async {
      final seeded = await tester.runAsync(() => seedProgram(db.repository));
      await tester.runAsync(() => db.repository.saveSettings(
            languageCode: 'en',
            onboardingCompleted: true,
          ));
      await tester.runAsync(() => controller.changeWeightUnit('lb'));
      await tester.runAsync(() => controller.startWorkout(seeded!.dayId));
      await pumpWorkoutOnly(tester);

      expect(find.text('Weight lb'), findsWidgets);
    });
  });

  group('program building via UI', () {
    testWidgets('create program sheet validates and saves', (tester) async {
      await pumpApp(tester);
      expect(
        find.text(
            'Create your first workout program to start tracking progress.'),
        findsWidgets,
      );

      await tester.tap(find.text('Create Program').first);
      await tester.pump();
      await tester.pump();

      await tester.enterText(find.byType(TextFormField), 'My Plan');
      await pressButton<FilledButton>(tester, find.text('Save'));

      expect(controller.program!.program.name, 'My Plan');
      expect(controller.selectedTab, 1);
      expect(find.text('My Plan'), findsWidgets);
    });

    testWidgets('exercise form switches type and saves reps-only exercise',
        (tester) async {
      await tester.runAsync(() => seedProgram(db.repository));
      await pumpApp(tester);
      controller.selectTab(1);
      await tester.pump();

      await tester.tap(find.text('Add Exercise').first);
      await tester.pump();
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, 'Push-ups');
      await tester.tap(find.text('Reps-only'));
      await tester.pump();
      await pressButton<FilledButton>(tester, find.text('Save'));

      expect(find.text('Push-ups'), findsWidgets);
    });
  });
}
