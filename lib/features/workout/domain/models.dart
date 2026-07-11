enum ExerciseType {
  weighted,
  repsOnly;

  String get dbValue => switch (this) {
        ExerciseType.weighted => 'weighted',
        ExerciseType.repsOnly => 'reps_only',
      };

  static ExerciseType fromDb(String value) {
    return value == 'reps_only' ? ExerciseType.repsOnly : ExerciseType.weighted;
  }
}

enum WorkoutSessionStatus {
  inProgress,
  completed,
  cancelled;

  String get dbValue => switch (this) {
        WorkoutSessionStatus.inProgress => 'in_progress',
        WorkoutSessionStatus.completed => 'completed',
        WorkoutSessionStatus.cancelled => 'cancelled',
      };

  static WorkoutSessionStatus fromDb(String value) {
    return switch (value) {
      'completed' => WorkoutSessionStatus.completed,
      'cancelled' => WorkoutSessionStatus.cancelled,
      _ => WorkoutSessionStatus.inProgress,
    };
  }
}

class AppSettings {
  const AppSettings({
    required this.id,
    required this.weightUnit,
    required this.onboardingCompleted,
    required this.createdAt,
    required this.updatedAt,
    this.languageCode,
    this.displayName,
    this.remindersEnabled = false,
    this.reminderHour = 18,
  });

  final int id;
  final String? languageCode;
  final String weightUnit;
  final bool onboardingCompleted;
  final String? displayName;
  final bool remindersEnabled;
  final int reminderHour;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isReady => languageCode != null && onboardingCompleted;

  factory AppSettings.fromMap(Map<String, Object?> map) {
    return AppSettings(
      id: map['id'] as int,
      languageCode: map['language_code'] as String?,
      weightUnit: map['weight_unit'] as String? ?? 'kg',
      onboardingCompleted: (map['onboarding_completed'] as int? ?? 0) == 1,
      displayName: map['display_name'] as String?,
      remindersEnabled: (map['reminders_enabled'] as int? ?? 0) == 1,
      reminderHour: map['reminder_hour'] as int? ?? 18,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class Program {
  const Program({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
  });

  final int id;
  final String name;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;

  factory Program.fromMap(Map<String, Object?> map) {
    return Program(
      id: map['id'] as int,
      name: map['name'] as String,
      isActive: (map['is_active'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      archivedAt: _nullableDate(map['archived_at']),
    );
  }
}

class WorkoutDay {
  const WorkoutDay({
    required this.id,
    required this.programId,
    required this.name,
    required this.weekDay,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final int id;
  final int programId;
  final String name;
  final int weekDay;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  factory WorkoutDay.fromMap(Map<String, Object?> map) {
    return WorkoutDay(
      id: map['id'] as int,
      programId: map['program_id'] as int,
      name: map['name'] as String,
      weekDay: map['week_day'] as int,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deletedAt: _nullableDate(map['deleted_at']),
    );
  }
}

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.targetMuscle,
    this.muscleIconKey,
    this.deletedAt,
  });

  final int id;
  final String name;
  final ExerciseType type;
  final String? targetMuscle;
  final String? muscleIconKey;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  factory Exercise.fromMap(Map<String, Object?> map) {
    return Exercise(
      id: map['id'] as int,
      name: map['name'] as String,
      type: ExerciseType.fromDb(map['type'] as String),
      targetMuscle: map['target_muscle'] as String?,
      muscleIconKey: map['muscle_icon_key'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deletedAt: _nullableDate(map['deleted_at']),
    );
  }
}

class WorkoutDayExercise {
  const WorkoutDayExercise({
    required this.id,
    required this.workoutDayId,
    required this.exerciseId,
    required this.defaultSets,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });

  final int id;
  final int workoutDayId;
  final int exerciseId;
  final int defaultSets;
  final String? notes;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory WorkoutDayExercise.fromMap(Map<String, Object?> map) {
    return WorkoutDayExercise(
      id: map['id'] as int,
      workoutDayId: map['workout_day_id'] as int,
      exerciseId: map['exercise_id'] as int,
      defaultSets: map['default_sets'] as int? ?? 3,
      notes: map['notes'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.workoutDayId,
    required this.programId,
    required this.sessionDate,
    required this.startedAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.finishedAt,
    this.notes,
  });

  final int id;
  final int workoutDayId;
  final int programId;
  final DateTime sessionDate;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final WorkoutSessionStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory WorkoutSession.fromMap(Map<String, Object?> map) {
    return WorkoutSession(
      id: map['id'] as int,
      workoutDayId: map['workout_day_id'] as int,
      programId: map['program_id'] as int,
      sessionDate: DateTime.parse(map['session_date'] as String),
      startedAt: DateTime.parse(map['started_at'] as String),
      finishedAt: _nullableDate(map['finished_at']),
      status: WorkoutSessionStatus.fromDb(map['status'] as String),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class WorkoutExerciseLog {
  const WorkoutExerciseLog({
    required this.id,
    required this.workoutSessionId,
    required this.exerciseId,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });

  final int id;
  final int workoutSessionId;
  final int exerciseId;
  final int sortOrder;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory WorkoutExerciseLog.fromMap(Map<String, Object?> map) {
    return WorkoutExerciseLog(
      id: map['id'] as int,
      workoutSessionId: map['workout_session_id'] as int,
      exerciseId: map['exercise_id'] as int,
      sortOrder: map['sort_order'] as int? ?? 0,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class WorkoutSetLog {
  const WorkoutSetLog({
    required this.id,
    required this.workoutExerciseLogId,
    required this.setNumber,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    this.weight,
    this.reps,
  });

  final int id;
  final int workoutExerciseLogId;
  final int setNumber;
  final double? weight;
  final int? reps;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkoutSetLog copyWith({
    int? setNumber,
    double? weight,
    bool clearWeight = false,
    int? reps,
    bool clearReps = false,
    bool? isCompleted,
  }) {
    return WorkoutSetLog(
      id: id,
      workoutExerciseLogId: workoutExerciseLogId,
      setNumber: setNumber ?? this.setNumber,
      weight: clearWeight ? null : weight ?? this.weight,
      reps: clearReps ? null : reps ?? this.reps,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  factory WorkoutSetLog.fromMap(Map<String, Object?> map) {
    final weightValue = map['weight'];
    return WorkoutSetLog(
      id: map['id'] as int,
      workoutExerciseLogId: map['workout_exercise_log_id'] as int,
      setNumber: map['set_number'] as int,
      weight: weightValue == null ? null : (weightValue as num).toDouble(),
      reps: map['reps'] as int?,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class WorkoutDayWithExercises {
  const WorkoutDayWithExercises({required this.day, required this.exercises});

  final WorkoutDay day;
  final List<ExerciseAssignment> exercises;
}

class ExerciseAssignment {
  const ExerciseAssignment({
    required this.assignment,
    required this.exercise,
    this.plannedSets = const <PlannedSet>[],
  });

  final WorkoutDayExercise assignment;
  final Exercise exercise;

  /// Coach-sheet target for each set (weight + reps), in set order.
  final List<PlannedSet> plannedSets;
}

/// A planned target set (weight + reps) inside a program exercise.
class PlannedSet {
  const PlannedSet({
    required this.setNumber,
    this.targetWeight,
    this.targetReps,
    this.id,
  });

  final int? id;
  final int setNumber;
  final double? targetWeight;
  final int? targetReps;

  factory PlannedSet.fromMap(Map<String, Object?> map) {
    final weight = map['target_weight'];
    return PlannedSet(
      id: map['id'] as int?,
      setNumber: map['set_number'] as int,
      targetWeight: weight == null ? null : (weight as num).toDouble(),
      targetReps: map['target_reps'] as int?,
    );
  }
}

class ProgramSnapshot {
  const ProgramSnapshot({required this.program, required this.days});

  final Program program;
  final List<WorkoutDayWithExercises> days;

  WorkoutDayWithExercises? dayForWeekDay(int weekDay) {
    for (final day in days) {
      if (day.day.weekDay == weekDay) {
        return day;
      }
    }
    return null;
  }
}

class PreviousSessionResult {
  const PreviousSessionResult({required this.session, required this.sets});

  final WorkoutSession session;
  final List<WorkoutSetLog> sets;
}

class BestResult {
  const BestResult({
    required this.exerciseId,
    required this.type,
    required this.date,
    this.weight,
    this.reps,
  });

  final int exerciseId;
  final ExerciseType type;
  final double? weight;
  final int? reps;
  final DateTime date;
}

class ActiveExerciseLog {
  const ActiveExerciseLog({
    required this.log,
    required this.exercise,
    required this.sets,
    this.previous,
    this.best,
  });

  final WorkoutExerciseLog log;
  final Exercise exercise;
  final List<WorkoutSetLog> sets;
  final PreviousSessionResult? previous;
  final BestResult? best;
}

class ActiveSessionSnapshot {
  const ActiveSessionSnapshot({
    required this.session,
    required this.day,
    required this.exercises,
  });

  final WorkoutSession session;
  final WorkoutDay day;
  final List<ActiveExerciseLog> exercises;
}

class WorkoutSummary {
  const WorkoutSummary({
    required this.exerciseCount,
    required this.completedSetCount,
    required this.newBestCount,
  });

  final int exerciseCount;
  final int completedSetCount;
  final int newBestCount;
}

class ProgressOverview {
  const ProgressOverview({required this.bests, required this.recentSessions});

  final List<ExerciseBestSummary> bests;
  final List<RecentSessionSummary> recentSessions;
}

class ExerciseBestSummary {
  const ExerciseBestSummary({required this.exercise, this.best});

  final Exercise exercise;
  final BestResult? best;
}

class RecentSessionSummary {
  const RecentSessionSummary({
    required this.session,
    required this.dayName,
    required this.completedSetCount,
  });

  final WorkoutSession session;
  final String dayName;
  final int completedSetCount;
}

class ExerciseHistoryEntry {
  const ExerciseHistoryEntry({required this.session, required this.sets});

  final WorkoutSession session;
  final List<WorkoutSetLog> sets;
}

DateTime? _nullableDate(Object? value) {
  if (value == null) {
    return null;
  }
  return DateTime.parse(value as String);
}
