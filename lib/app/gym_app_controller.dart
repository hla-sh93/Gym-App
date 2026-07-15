import 'package:flutter/widgets.dart';

import '../core/errors/app_exception.dart';
import '../core/input_validation.dart';
import '../data/gym_repository.dart';
import '../features/workout/domain/models.dart';

class GymAppController extends ChangeNotifier {
  GymAppController(this.repository);

  final GymRepository repository;

  bool isReady = false;
  bool isBusy = false;
  int selectedTab = 0;
  String? lastError;

  AppSettings? settings;
  ProgramSnapshot? program;
  ActiveSessionSnapshot? activeSession;
  List<Program> archivedPrograms = const <Program>[];
  ProgressOverview progress = const ProgressOverview(
    bests: <ExerciseBestSummary>[],
    recentSessions: <RecentSessionSummary>[],
  );
  WorkoutSummary? latestSummary;

  /// Detailed end-of-day report of the last finished workout.
  SessionReport? lastWorkoutReport;

  /// Session id whose Home banner was dismissed with "Finish later".
  int? snoozedSessionId;

  Locale get locale => Locale(settings?.languageCode ?? 'en');

  String get weightUnit => settings?.weightUnit ?? 'kg';

  Future<void> load() async {
    isBusy = true;
    notifyListeners();
    try {
      await repository.init();
      await _refresh(notify: false);
      isReady = true;
    } catch (error) {
      lastError = error.toString();
      isReady = true;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => _refresh();

  void selectTab(int index) {
    selectedTab = index;
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required String languageCode,
    String? displayName,
  }) async {
    await repository.saveSettings(
      languageCode: languageCode,
      onboardingCompleted: true,
      displayName: displayName,
    );
    await _refresh();
  }

  Future<void> changeLanguage(String languageCode) async {
    final current = settings;
    await repository.saveSettings(
      languageCode: languageCode,
      onboardingCompleted: current?.onboardingCompleted ?? true,
      displayName: current?.displayName,
    );
    await _refresh();
  }

  Future<void> updateDisplayName(String displayName) async {
    final current = settings;
    await repository.saveSettings(
      languageCode: current?.languageCode ?? 'en',
      onboardingCompleted: current?.onboardingCompleted ?? true,
      displayName: displayName,
    );
    await _refresh();
  }

  Future<void> changeWeightUnit(String weightUnit) async {
    final current = settings;
    await repository.saveSettings(
      languageCode: current?.languageCode ?? 'en',
      onboardingCompleted: current?.onboardingCompleted ?? true,
      displayName: current?.displayName,
      weightUnit: weightUnit,
    );
    await _refresh();
  }

  Future<void> setReminders({required bool enabled, int? hour}) async {
    final current = settings;
    await repository.saveSettings(
      languageCode: current?.languageCode ?? 'en',
      onboardingCompleted: current?.onboardingCompleted ?? true,
      displayName: current?.displayName,
      remindersEnabled: enabled,
      reminderHour: hour,
    );
    await _refresh();
  }

  Future<void> createProgram({
    required String name,
    required List<WorkoutDayDraft> days,
  }) async {
    if (!InputValidation.requiredText(name)) {
      throw const AppException('nameRequired');
    }
    await repository.createProgram(name: name, days: days);
    selectedTab = 1;
    await _refresh();
  }

  Future<void> updateProgramName(int programId, String name) async {
    if (!InputValidation.requiredText(name)) {
      throw const AppException('nameRequired');
    }
    await repository.updateProgramName(programId, name);
    await _refresh();
  }

  Future<void> archiveProgram(int programId) async {
    await repository.archiveProgram(programId);
    await _refresh();
  }

  Future<void> restoreProgram(int programId) async {
    await repository.restoreProgram(programId);
    await _refresh();
  }

  Future<void> addWorkoutDay({
    required int programId,
    required String name,
    required int weekDay,
  }) async {
    if (!InputValidation.requiredText(name)) {
      throw const AppException('nameRequired');
    }
    await repository.addWorkoutDay(
      programId: programId,
      name: name,
      weekDay: weekDay,
    );
    await _refresh();
  }

  Future<void> updateWorkoutDay({
    required int workoutDayId,
    required String name,
    required int weekDay,
  }) async {
    if (!InputValidation.requiredText(name)) {
      throw const AppException('nameRequired');
    }
    await repository.updateWorkoutDay(
      workoutDayId: workoutDayId,
      name: name,
      weekDay: weekDay,
    );
    await _refresh();
  }

  Future<void> deleteWorkoutDay(int workoutDayId) async {
    await repository.deleteWorkoutDay(workoutDayId);
    await _refresh();
  }

  Future<void> moveWorkoutDay({
    required int programId,
    required int workoutDayId,
    required int direction,
  }) async {
    await repository.moveWorkoutDay(
      programId: programId,
      workoutDayId: workoutDayId,
      direction: direction,
    );
    await _refresh();
  }

  Future<void> addExercise({
    required int workoutDayId,
    required String name,
    required ExerciseType type,
    required int defaultSets,
    String? targetMuscle,
    List<int?> targetReps = const <int?>[],
  }) async {
    if (!InputValidation.requiredText(name, maxLength: 80)) {
      throw const AppException('nameRequired');
    }
    await repository.addExercise(
      workoutDayId: workoutDayId,
      name: name,
      type: type,
      defaultSets: InputValidation.clampDefaultSets(defaultSets),
      targetMuscle: targetMuscle,
      muscleIconKey: targetMuscle,
      targetReps: targetReps,
    );
    await _refresh();
  }

  Future<void> updateExercise({
    required int assignmentId,
    required int exerciseId,
    required String name,
    required ExerciseType type,
    required int defaultSets,
    String? targetMuscle,
    List<int?> targetReps = const <int?>[],
  }) async {
    if (!InputValidation.requiredText(name, maxLength: 80)) {
      throw const AppException('nameRequired');
    }
    await repository.updateExercise(
      assignmentId: assignmentId,
      exerciseId: exerciseId,
      name: name,
      type: type,
      defaultSets: InputValidation.clampDefaultSets(defaultSets),
      targetMuscle: targetMuscle,
      muscleIconKey: targetMuscle,
      targetReps: targetReps,
    );
    await _refresh();
  }

  /// WORKOUT_FLOW.md §3.3 — Complete Exercise:
  /// valid sets become completed, empty sets are deleted (renumbered),
  /// and with no valid set at all a localized error is thrown.
  Future<void> completeExercise(int logId) async {
    // Typed values are saved silently without refreshing the in-memory
    // snapshot, so ALWAYS validate against fresh database state.
    final session = await repository.inProgressSession();
    if (session == null) {
      throw const AppException('sessionNotFound');
    }
    ActiveExerciseLog? log;
    for (final candidate in session.exercises) {
      if (candidate.log.id == logId) {
        log = candidate;
        break;
      }
    }
    if (log == null) {
      throw const AppException('sessionNotFound');
    }

    bool isValid(WorkoutSetLog set) {
      if (set.reps == null) {
        return false;
      }
      return log!.exercise.type == ExerciseType.repsOnly ||
          set.weight != null;
    }

    if (!log.sets.any(isValid)) {
      throw const AppException('emptyExerciseWarning');
    }
    for (final set in log.sets) {
      if (isValid(set)) {
        if (!set.isCompleted) {
          await repository.updateSet(set.copyWith(isCompleted: true));
        }
      } else {
        await repository.deleteSet(set.id, set.workoutExerciseLogId);
      }
    }
    activeSession = await repository.inProgressSession();
    notifyListeners();
  }

  Future<void> deleteExercise({
    required int assignmentId,
    required int exerciseId,
  }) async {
    await repository.deleteExerciseAssignment(
      assignmentId: assignmentId,
      exerciseId: exerciseId,
    );
    await _refresh();
  }

  /// Starts a workout for [workoutDayId], or resumes the existing in-progress
  /// session. Returns true when an existing session for a different day was
  /// resumed instead of starting the requested one.
  Future<bool> startWorkout(int workoutDayId) async {
    final existing = await repository.inProgressSession();
    final resumedOtherDay =
        existing != null && existing.session.workoutDayId != workoutDayId;
    activeSession = await repository.startWorkout(workoutDayId);
    selectedTab = 2;
    notifyListeners();
    return resumedOtherDay;
  }

  void snoozeActiveSessionBanner() {
    snoozedSessionId = activeSession?.session.id;
    notifyListeners();
  }

  Future<void> reloadActiveSession() async {
    activeSession = await repository.inProgressSession();
    notifyListeners();
  }

  Future<void> updateSetSilently(WorkoutSetLog set) async {
    await repository.updateSet(set);
  }

  Future<void> updateSetAndRefresh(WorkoutSetLog set) async {
    await repository.updateSet(set);
    activeSession = await repository.inProgressSession();
    notifyListeners();
  }

  Future<void> addSet(int workoutExerciseLogId) async {
    await repository.addSet(workoutExerciseLogId);
    activeSession = await repository.inProgressSession();
    notifyListeners();
  }

  Future<void> deleteSet(int setId, int workoutExerciseLogId) async {
    await repository.deleteSet(setId, workoutExerciseLogId);
    activeSession = await repository.inProgressSession();
    notifyListeners();
  }

  Future<WorkoutSummary> finishWorkout() async {
    final active = activeSession;
    final sessionId = active?.session.id;
    if (active == null || sessionId == null) {
      throw const AppException('sessionNotFound');
    }
    final summary = await repository.finishSession(sessionId);
    // End-of-day report: what was actually played, from the in-memory
    // snapshot (completed sets only), available synchronously to the UI.
    lastWorkoutReport = SessionReport(
      session: active.session,
      dayName: active.day.name,
      exercises: <ExerciseReport>[
        for (final log in active.exercises)
          if (log.sets.any((set) => set.isCompleted))
            ExerciseReport(
              exercise: log.exercise,
              sets: log.sets.where((set) => set.isCompleted).toList(),
            ),
      ],
    );
    latestSummary = summary;
    await _refresh(notify: false);
    selectedTab = 3;
    notifyListeners();
    return summary;
  }

  Future<void> discardWorkout() async {
    final sessionId = activeSession?.session.id;
    if (sessionId == null) {
      return;
    }
    await repository.discardSession(sessionId);
    await _refresh();
  }

  Future<List<ExerciseHistoryEntry>> exerciseHistory(int exerciseId) {
    return repository.exerciseHistory(exerciseId);
  }

  Future<void> _refresh({bool notify = true}) async {
    settings = await repository.settings();
    program = await repository.activeProgram();
    activeSession = await repository.inProgressSession();
    archivedPrograms = await repository.archivedPrograms();
    progress = await repository.progressOverview();
    if (notify) {
      notifyListeners();
    }
  }
}
