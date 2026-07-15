import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:personal_gym_progress_notebook/data/gym_repository.dart';
import 'package:personal_gym_progress_notebook/database/app_database.dart';
import 'package:personal_gym_progress_notebook/features/workout/domain/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

var _dbCounter = 0;

/// Creates an isolated on-disk SQLite database + repository for one test.
class TestDb {
  TestDb._(this.appDatabase, this.repository);

  final AppDatabase appDatabase;
  final GymRepository repository;

  static Future<TestDb> create() async {
    _dbCounter += 1;
    final appDatabase = AppDatabase(
      databaseName:
          'qa_${DateTime.now().microsecondsSinceEpoch}_$_dbCounter.db',
    );
    final repository = GymRepository(appDatabase);
    await repository.init();
    return TestDb._(appDatabase, repository);
  }

  Future<void> dispose() async {
    final path = p.join(
      await databaseFactory.getDatabasesPath(),
      appDatabase.databaseName,
    );
    await appDatabase.close();
    await databaseFactory.deleteDatabase(path);
  }
}

/// Seeds a program with one workout day and one exercise (optionally with
/// per-set target reps — never target weights, per WORKOUT_FLOW.md §1).
Future<({int programId, int dayId, int exerciseId})> seedProgram(
  GymRepository repository, {
  String programName = 'Test Program',
  String dayName = 'Push',
  int weekDay = 0,
  String exerciseName = 'Bench Press',
  ExerciseType type = ExerciseType.weighted,
  int defaultSets = 2,
  List<int?> targetReps = const <int?>[],
}) async {
  await repository.createProgram(
    name: programName,
    days: <WorkoutDayDraft>[WorkoutDayDraft(weekDay: weekDay, name: dayName)],
  );
  final snapshot = await repository.activeProgram();
  final dayId = snapshot!.days.first.day.id;
  final exerciseId = await repository.addExercise(
    workoutDayId: dayId,
    name: exerciseName,
    type: type,
    defaultSets: defaultSets,
    targetReps: targetReps,
  );
  return (
    programId: snapshot.program.id,
    dayId: dayId,
    exerciseId: exerciseId,
  );
}

/// Starts a session, records the given sets as completed, finishes it.
Future<WorkoutSummary> completeSession(
  GymRepository repository,
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

/// Performs a UI [action] (tap, enterText) that triggers real database I/O,
/// settles that I/O inside a real-async zone, then pumps frames so the widget
/// tree rebuilds. This is the reliable pattern for driving this app's
/// async-controller-backed UI in widget tests.
Future<void> act(
  WidgetTester tester,
  Future<void> Function() action, {
  int settleMs = 120,
}) async {
  await tester.runAsync(() async {
    await action();
    await Future<void>.delayed(Duration(milliseconds: settleMs));
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

/// Invokes the onPressed of the nearest ButtonStyleButton (Filled/Outlined/
/// Text/Elevated) that contains [finder]. Reliable alternative to tapping
/// when hit-testing is flaky.
Future<void> pressButton<T extends Widget>(
  WidgetTester tester,
  Finder finder,
) async {
  final element = finder.evaluate().first;
  VoidCallback? onPressed;
  element.visitAncestorElements((ancestor) {
    if (ancestor.widget is ButtonStyleButton) {
      onPressed = (ancestor.widget as ButtonStyleButton).onPressed;
      return false;
    }
    return true;
  });
  // Fire-and-forget: do NOT await the handler's future — handlers that open a
  // dialog await showDialog, which would never complete and hang runAsync.
  await act(tester, () async {
    onPressed?.call();
  });
}

/// Invokes the onPressed of an [IconButton] located by [finder].
Future<void> pressIconButton(WidgetTester tester, Finder finder) async {
  final button = tester.widget<IconButton>(finder);
  await act(tester, () async {
    button.onPressed!.call();
  });
}

/// Invokes the onTap of the nearest [InkWell] ancestor of [finder] and pumps
/// through the resulting route transition.
Future<void> tapTile(WidgetTester tester, Finder finder) async {
  final element = finder.evaluate().first;
  VoidCallback? onTap;
  element.visitAncestorElements((ancestor) {
    if (ancestor.widget is InkWell) {
      onTap = (ancestor.widget as InkWell).onTap;
      return false;
    }
    return true;
  });
  onTap!();
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

/// Gives the test a tall, narrow phone-like surface so full pages fit without
/// scrolling — keeps every control on-screen and tappable in widget tests.
void useTallSurface(WidgetTester tester) {
  // Logical 900 x 3000 — wide enough for the 760px content column and tall
  // enough that no page overflows, so every control is on-screen.
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Enters text into a field (fake-async, so the controller updates and
/// onChanged fires) and pumps a frame. Freshly-built fields occasionally
/// miss the first keyboard attach in tests, so verify and retry.
Future<void> typeText(
  WidgetTester tester,
  Finder finder,
  String text,
) async {
  for (var attempt = 0; attempt < 3; attempt += 1) {
    await tester.showKeyboard(finder);
    await tester.pump();
    await tester.enterText(finder, text);
    await tester.pump();
    if (tester.widget<TextField>(finder).controller!.text == text) {
      return;
    }
  }
  fail('typeText: field did not accept "$text" after 3 attempts');
}

/// Invokes a [Checkbox]'s onChanged callback directly and settles the DB I/O.
/// Material checkboxes are unreliable to hit-test under fake-async, so this
/// exercises the real wiring without depending on pointer geometry.
Future<void> toggleCheckbox(
  WidgetTester tester,
  Finder finder,
  bool value,
) async {
  final checkbox = tester.widget<Checkbox>(finder);
  await act(tester, () async {
    checkbox.onChanged!(value);
  });
}
