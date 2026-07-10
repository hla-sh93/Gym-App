import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:personal_gym_progress_notebook/app/app.dart';
import 'package:personal_gym_progress_notebook/app/gym_app_controller.dart';
import 'package:personal_gym_progress_notebook/data/gym_repository.dart';
import 'package:personal_gym_progress_notebook/database/app_database.dart';
import 'package:personal_gym_progress_notebook/features/workout/domain/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('starting a workout shows the exercise logging cards',
      (tester) async {
    final appDatabase = AppDatabase(
      databaseName: 'widget_test_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    final repository = GymRepository(appDatabase);

    // Database calls are real I/O, so they must run inside runAsync.
    await tester.runAsync(() async {
      await repository.init();
      await repository.saveSettings(
        languageCode: 'en',
        onboardingCompleted: true,
      );
      await repository.createProgram(
        name: 'My Program',
        days: const <WorkoutDayDraft>[
          WorkoutDayDraft(weekDay: 0, name: 'Push Day'),
        ],
      );
      final program = await repository.activeProgram();
      await repository.addExercise(
        workoutDayId: program!.days.first.day.id,
        name: 'Bench Press',
        type: ExerciseType.weighted,
        defaultSets: 3,
      );
    });

    final controller = GymAppController(repository);
    // Load state with real async before pumping; the widget's own load()
    // call is then a no-op refresh.
    await tester.runAsync(controller.load);
    await tester.pumpWidget(GymNotebookApp(controller: controller));
    await tester.pump();
    expect(find.text('Workout'), findsWidgets);

    // Go to the Workout tab and start the workout.
    await tester.tap(find.text('Workout').last);
    await tester.pump();
    await tester.runAsync(() async {
      final program = await repository.activeProgram();
      await controller.startWorkout(program!.days.first.day.id);
    });
    await tester.pump();

    // The active workout page must show the exercise card with its sets.
    expect(find.text('Push Day'), findsWidgets);
    expect(find.text('Bench Press'), findsWidgets);
    expect(find.text('Finish Workout'), findsOneWidget);
    expect(find.textContaining('Set 1'), findsWidgets);

    await tester.runAsync(() async {
      final path = p.join(
        await databaseFactory.getDatabasesPath(),
        appDatabase.databaseName,
      );
      await appDatabase.close();
      await databaseFactory.deleteDatabase(path);
    });
  });
}
