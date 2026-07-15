import 'package:sqflite/sqflite.dart';

import '../core/errors/app_exception.dart';
import '../database/app_database.dart';
import '../features/workout/domain/models.dart';

class GymRepository {
  GymRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<void> init() async {
    final db = await _appDatabase.database;
    await _ensureSettings(db);
  }

  Future<AppSettings> settings() async {
    final db = await _appDatabase.database;
    await _ensureSettings(db);
    final rows = await db.query(
      'app_settings',
      where: 'id = ?',
      whereArgs: <Object?>[1],
      limit: 1,
    );
    return AppSettings.fromMap(rows.single);
  }

  Future<void> saveSettings({
    required String languageCode,
    required bool onboardingCompleted,
    String? displayName,
    String? weightUnit,
    bool? remindersEnabled,
    int? reminderHour,
  }) async {
    final db = await _appDatabase.database;
    await _ensureSettings(db);
    await db.update(
      'app_settings',
      <String, Object?>{
        'language_code': languageCode,
        'onboarding_completed': onboardingCompleted ? 1 : 0,
        'display_name': _emptyToNull(displayName),
        if (weightUnit != null) 'weight_unit': weightUnit,
        if (remindersEnabled != null)
          'reminders_enabled': remindersEnabled ? 1 : 0,
        if (reminderHour != null) 'reminder_hour': reminderHour,
        'updated_at': _now(),
      },
      where: 'id = ?',
      whereArgs: <Object?>[1],
    );
  }

  Future<ProgramSnapshot?> activeProgram() async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'programs',
      where: 'is_active = 1 AND archived_at IS NULL',
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    final program = Program.fromMap(rows.single);
    return ProgramSnapshot(
      program: program,
      days: await _daysForProgram(db, program.id),
    );
  }

  Future<int> createProgram({
    required String name,
    required List<WorkoutDayDraft> days,
  }) async {
    if (days.isEmpty) {
      throw const AppException('atLeastOneDay');
    }
    final db = await _appDatabase.database;
    return db.transaction<int>((txn) async {
      final stamp = _now();
      await txn.update(
          'programs',
          <String, Object?>{
            'is_active': 0,
            'updated_at': stamp,
          },
          where: 'is_active = 1');
      final programId = await txn.insert('programs', <String, Object?>{
        'name': name.trim(),
        'is_active': 1,
        'created_at': stamp,
        'updated_at': stamp,
      });
      for (var index = 0; index < days.length; index += 1) {
        final day = days[index];
        await txn.insert('workout_days', <String, Object?>{
          'program_id': programId,
          'name': day.name.trim(),
          'week_day': day.weekDay,
          'sort_order': index,
          'created_at': stamp,
          'updated_at': stamp,
        });
      }
      return programId;
    });
  }

  Future<void> updateProgramName(int programId, String name) async {
    final db = await _appDatabase.database;
    await db.update(
      'programs',
      <String, Object?>{'name': name.trim(), 'updated_at': _now()},
      where: 'id = ?',
      whereArgs: <Object?>[programId],
    );
  }

  Future<void> archiveProgram(int programId) async {
    final db = await _appDatabase.database;
    final stamp = _now();
    await db.update(
      'programs',
      <String, Object?>{
        'is_active': 0,
        'archived_at': stamp,
        'updated_at': stamp,
      },
      where: 'id = ?',
      whereArgs: <Object?>[programId],
    );
  }

  Future<List<Program>> archivedPrograms() async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'programs',
      where: 'archived_at IS NOT NULL',
      orderBy: 'archived_at DESC, id DESC',
    );
    return rows.map(Program.fromMap).toList();
  }

  Future<void> restoreProgram(int programId) async {
    final db = await _appDatabase.database;
    await db.transaction<void>((txn) async {
      final stamp = _now();
      await txn.update(
          'programs',
          <String, Object?>{
            'is_active': 0,
            'updated_at': stamp,
          },
          where: 'is_active = 1');
      await txn.update(
        'programs',
        <String, Object?>{
          'is_active': 1,
          'archived_at': null,
          'updated_at': stamp,
        },
        where: 'id = ?',
        whereArgs: <Object?>[programId],
      );
    });
  }

  Future<int> addWorkoutDay({
    required int programId,
    required String name,
    required int weekDay,
  }) async {
    final db = await _appDatabase.database;
    final stamp = _now();
    final order = await _nextSortOrder(
      db,
      table: 'workout_days',
      where: 'program_id = ? AND deleted_at IS NULL',
      whereArgs: <Object?>[programId],
    );
    return db.insert('workout_days', <String, Object?>{
      'program_id': programId,
      'name': name.trim(),
      'week_day': weekDay,
      'sort_order': order,
      'created_at': stamp,
      'updated_at': stamp,
    });
  }

  Future<void> updateWorkoutDay({
    required int workoutDayId,
    required String name,
    required int weekDay,
  }) async {
    final db = await _appDatabase.database;
    await db.update(
      'workout_days',
      <String, Object?>{
        'name': name.trim(),
        'week_day': weekDay,
        'updated_at': _now(),
      },
      where: 'id = ?',
      whereArgs: <Object?>[workoutDayId],
    );
  }

  Future<void> deleteWorkoutDay(int workoutDayId) async {
    final db = await _appDatabase.database;
    final stamp = _now();
    await db.update(
      'workout_days',
      <String, Object?>{'deleted_at': stamp, 'updated_at': stamp},
      where: 'id = ?',
      whereArgs: <Object?>[workoutDayId],
    );
  }

  Future<void> moveWorkoutDay({
    required int programId,
    required int workoutDayId,
    required int direction,
  }) async {
    final db = await _appDatabase.database;
    await db.transaction<void>((txn) async {
      final days = await txn.query(
        'workout_days',
        where: 'program_id = ? AND deleted_at IS NULL',
        whereArgs: <Object?>[programId],
        orderBy: 'sort_order ASC, id ASC',
      );
      final index = days.indexWhere((row) => row['id'] == workoutDayId);
      if (index == -1) {
        return;
      }
      final targetIndex = index + direction;
      if (targetIndex < 0 || targetIndex >= days.length) {
        return;
      }
      final current = days[index];
      final target = days[targetIndex];
      final stamp = _now();
      await txn.update(
        'workout_days',
        <String, Object?>{
          'sort_order': target['sort_order'],
          'updated_at': stamp,
        },
        where: 'id = ?',
        whereArgs: <Object?>[current['id']],
      );
      await txn.update(
        'workout_days',
        <String, Object?>{
          'sort_order': current['sort_order'],
          'updated_at': stamp,
        },
        where: 'id = ?',
        whereArgs: <Object?>[target['id']],
      );
    });
  }

  // Program setup stores structure only: name, type, muscle, set COUNT and
  // optional TARGET REPS per set. Weights are never planned — they live
  // exclusively in workout_set_logs (WORKOUT_FLOW.md §1, spec §4.5).
  Future<int> addExercise({
    required int workoutDayId,
    required String name,
    required ExerciseType type,
    required int defaultSets,
    String? targetMuscle,
    String? muscleIconKey,
    List<int?> targetReps = const <int?>[],
  }) async {
    final db = await _appDatabase.database;
    return db.transaction<int>((txn) async {
      final stamp = _now();
      final exerciseId = await txn.insert('exercises', <String, Object?>{
        'name': name.trim(),
        'type': type.dbValue,
        'target_muscle': _emptyToNull(targetMuscle),
        'muscle_icon_key': _emptyToNull(muscleIconKey),
        'created_at': stamp,
        'updated_at': stamp,
      });
      final order = await _nextSortOrder(
        txn,
        table: 'workout_day_exercises',
        where: 'workout_day_id = ?',
        whereArgs: <Object?>[workoutDayId],
      );
      final sets = targetReps.isEmpty ? defaultSets : targetReps.length;
      final assignmentId = await txn.insert(
        'workout_day_exercises',
        <String, Object?>{
          'workout_day_id': workoutDayId,
          'exercise_id': exerciseId,
          'default_sets': sets,
          'sort_order': order,
          'created_at': stamp,
          'updated_at': stamp,
        },
      );
      await _replaceTargetReps(txn, assignmentId, targetReps, stamp);
      return exerciseId;
    });
  }

  Future<void> updateExercise({
    required int assignmentId,
    required int exerciseId,
    required String name,
    required ExerciseType type,
    required int defaultSets,
    String? targetMuscle,
    String? muscleIconKey,
    List<int?> targetReps = const <int?>[],
  }) async {
    final db = await _appDatabase.database;
    await db.transaction<void>((txn) async {
      final stamp = _now();
      await txn.update(
        'exercises',
        <String, Object?>{
          'name': name.trim(),
          'type': type.dbValue,
          'target_muscle': _emptyToNull(targetMuscle),
          'muscle_icon_key': _emptyToNull(muscleIconKey),
          'updated_at': stamp,
        },
        where: 'id = ?',
        whereArgs: <Object?>[exerciseId],
      );
      final sets = targetReps.isEmpty ? defaultSets : targetReps.length;
      await txn.update(
        'workout_day_exercises',
        <String, Object?>{'default_sets': sets, 'updated_at': stamp},
        where: 'id = ?',
        whereArgs: <Object?>[assignmentId],
      );
      await _replaceTargetReps(txn, assignmentId, targetReps, stamp);
    });
  }

  /// Rewrites per-set target reps. `target_weight` is intentionally never
  /// written: the program must not plan weights.
  Future<void> _replaceTargetReps(
    DatabaseExecutor txn,
    int assignmentId,
    List<int?> targetReps,
    String stamp,
  ) async {
    await txn.delete(
      'workout_day_exercise_sets',
      where: 'workout_day_exercise_id = ?',
      whereArgs: <Object?>[assignmentId],
    );
    for (var index = 0; index < targetReps.length; index += 1) {
      await txn.insert('workout_day_exercise_sets', <String, Object?>{
        'workout_day_exercise_id': assignmentId,
        'set_number': index + 1,
        'target_reps': targetReps[index],
        'created_at': stamp,
        'updated_at': stamp,
      });
    }
  }

  Future<void> deleteExerciseAssignment({
    required int assignmentId,
    required int exerciseId,
  }) async {
    final db = await _appDatabase.database;
    await db.transaction<void>((txn) async {
      await txn.delete(
        'workout_day_exercises',
        where: 'id = ?',
        whereArgs: <Object?>[assignmentId],
      );
      await txn.update(
        'exercises',
        <String, Object?>{'deleted_at': _now(), 'updated_at': _now()},
        where: 'id = ?',
        whereArgs: <Object?>[exerciseId],
      );
    });
  }

  Future<ActiveSessionSnapshot?> inProgressSession() async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'workout_sessions',
      where: 'status = ?',
      whereArgs: <Object?>[WorkoutSessionStatus.inProgress.dbValue],
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return sessionSnapshot(rows.single['id'] as int);
  }

  Future<ActiveSessionSnapshot> startWorkout(int workoutDayId) async {
    final existing = await inProgressSession();
    if (existing != null) {
      return existing;
    }

    final db = await _appDatabase.database;
    final sessionId = await db.transaction<int>((txn) async {
      final dayRows = await txn.query(
        'workout_days',
        where: 'id = ? AND deleted_at IS NULL',
        whereArgs: <Object?>[workoutDayId],
        limit: 1,
      );
      if (dayRows.isEmpty) {
        throw const AppException('workoutDayNotFound');
      }
      final day = WorkoutDay.fromMap(dayRows.single);
      final assignments = await _assignmentsForDay(txn, workoutDayId);
      if (assignments.isEmpty) {
        throw const AppException('addAtLeastOneExercise');
      }

      final stamp = _now();
      final sessionId = await txn.insert('workout_sessions', <String, Object?>{
        'workout_day_id': workoutDayId,
        'program_id': day.programId,
        'session_date': DateTime.now().toIso8601String(),
        'started_at': stamp,
        'status': WorkoutSessionStatus.inProgress.dbValue,
        'created_at': stamp,
        'updated_at': stamp,
      });

      for (var exerciseIndex = 0;
          exerciseIndex < assignments.length;
          exerciseIndex += 1) {
        final assignment = assignments[exerciseIndex];
        final logId =
            await txn.insert('workout_exercise_logs', <String, Object?>{
          'workout_session_id': sessionId,
          'exercise_id': assignment.exercise.id,
          'sort_order': exerciseIndex,
          'created_at': stamp,
          'updated_at': stamp,
        });
        // WORKOUT_FLOW.md §3.2: weight is ALWAYS null (logged live); reps
        // pre-fill from the program's target reps and stay editable.
        for (var setIndex = 0;
            setIndex < assignment.assignment.defaultSets;
            setIndex += 1) {
          await txn.insert('workout_set_logs', <String, Object?>{
            'workout_exercise_log_id': logId,
            'set_number': setIndex + 1,
            'reps': setIndex < assignment.targetReps.length
                ? assignment.targetReps[setIndex]
                : null,
            'is_completed': 0,
            'created_at': stamp,
            'updated_at': stamp,
          });
        }
      }
      return sessionId;
    });
    return sessionSnapshot(sessionId);
  }

  Future<ActiveSessionSnapshot> sessionSnapshot(int sessionId) async {
    final db = await _appDatabase.database;
    final sessionRows = await db.query(
      'workout_sessions',
      where: 'id = ?',
      whereArgs: <Object?>[sessionId],
      limit: 1,
    );
    if (sessionRows.isEmpty) {
      throw const AppException('sessionNotFound');
    }
    final session = WorkoutSession.fromMap(sessionRows.single);
    final dayRows = await db.query(
      'workout_days',
      where: 'id = ?',
      whereArgs: <Object?>[session.workoutDayId],
      limit: 1,
    );
    if (dayRows.isEmpty) {
      throw const AppException('workoutDayNotFound');
    }
    final day = WorkoutDay.fromMap(dayRows.single);
    final logRows = await db.query(
      'workout_exercise_logs',
      where: 'workout_session_id = ?',
      whereArgs: <Object?>[sessionId],
      orderBy: 'sort_order ASC, id ASC',
    );

    final exercises = <ActiveExerciseLog>[];
    for (final logRow in logRows) {
      final log = WorkoutExerciseLog.fromMap(logRow);
      final exerciseRows = await db.query(
        'exercises',
        where: 'id = ?',
        whereArgs: <Object?>[log.exerciseId],
        limit: 1,
      );
      if (exerciseRows.isEmpty) {
        continue;
      }
      final exercise = Exercise.fromMap(exerciseRows.single);
      final setRows = await db.query(
        'workout_set_logs',
        where: 'workout_exercise_log_id = ?',
        whereArgs: <Object?>[log.id],
        orderBy: 'set_number ASC, id ASC',
      );
      // Program targets for this exercise on this day ("Target: X reps").
      final targetRows = await db.rawQuery(
        '''
        SELECT ts.set_number, ts.target_reps
        FROM workout_day_exercise_sets ts
        INNER JOIN workout_day_exercises wde
          ON wde.id = ts.workout_day_exercise_id
        WHERE wde.workout_day_id = ? AND wde.exercise_id = ?
        ORDER BY ts.set_number ASC
      ''',
        <Object?>[session.workoutDayId, exercise.id],
      );
      final targetReps = <int?>[
        for (final row in targetRows) row['target_reps'] as int?,
      ];
      exercises.add(
        ActiveExerciseLog(
          log: log,
          exercise: exercise,
          sets: setRows.map(WorkoutSetLog.fromMap).toList(),
          previous: await previousSessionForExercise(
            exercise.id,
            excludeSessionId: sessionId,
          ),
          best: await bestForExercise(
            exercise.id,
            exercise.type,
            excludeSessionId: sessionId,
          ),
          targetReps: targetReps,
        ),
      );
    }

    return ActiveSessionSnapshot(
      session: session,
      day: day,
      exercises: exercises,
    );
  }

  Future<void> updateSet(WorkoutSetLog set) async {
    final db = await _appDatabase.database;
    await db.update(
      'workout_set_logs',
      <String, Object?>{
        'set_number': set.setNumber,
        'weight': set.weight,
        'reps': set.reps,
        'is_completed': set.isCompleted ? 1 : 0,
        'updated_at': _now(),
      },
      where: 'id = ?',
      whereArgs: <Object?>[set.id],
    );
  }

  Future<void> addSet(int workoutExerciseLogId) async {
    final db = await _appDatabase.database;
    final order = await _nextSortOrder(
      db,
      table: 'workout_set_logs',
      column: 'set_number',
      where: 'workout_exercise_log_id = ?',
      whereArgs: <Object?>[workoutExerciseLogId],
      startAtOne: true,
    );
    final stamp = _now();
    await db.insert('workout_set_logs', <String, Object?>{
      'workout_exercise_log_id': workoutExerciseLogId,
      'set_number': order,
      'is_completed': 0,
      'created_at': stamp,
      'updated_at': stamp,
    });
  }

  Future<void> deleteSet(int setId, int workoutExerciseLogId) async {
    final db = await _appDatabase.database;
    await db.transaction<void>((txn) async {
      await txn.delete(
        'workout_set_logs',
        where: 'id = ?',
        whereArgs: <Object?>[setId],
      );
      final rows = await txn.query(
        'workout_set_logs',
        where: 'workout_exercise_log_id = ?',
        whereArgs: <Object?>[workoutExerciseLogId],
        orderBy: 'set_number ASC, id ASC',
      );
      for (var index = 0; index < rows.length; index += 1) {
        await txn.update(
          'workout_set_logs',
          <String, Object?>{'set_number': index + 1, 'updated_at': _now()},
          where: 'id = ?',
          whereArgs: <Object?>[rows[index]['id']],
        );
      }
    });
  }

  Future<WorkoutSummary> finishSession(int sessionId) async {
    final before = await sessionSnapshot(sessionId);
    var completedSetCount = 0;
    var newBestCount = 0;

    for (final exerciseLog in before.exercises) {
      final validSets = exerciseLog.sets.where(
        (set) => _isValidCompletedSet(set, exerciseLog.exercise.type),
      );
      completedSetCount += validSets.length;

      // A first-ever result for an exercise also counts as a new best.
      if (exerciseLog.exercise.type == ExerciseType.weighted) {
        final currentBest = _bestWeightedFromSets(validSets);
        final previousBest = exerciseLog.best;
        if (currentBest != null &&
            (previousBest?.weight == null ||
                currentBest.weight! > previousBest!.weight!)) {
          newBestCount += 1;
        }
      } else {
        final currentBest = _bestRepsFromSets(validSets);
        final previousBest = exerciseLog.best;
        if (currentBest != null &&
            (previousBest?.reps == null ||
                currentBest.reps! > previousBest!.reps!)) {
          newBestCount += 1;
        }
      }
    }

    if (completedSetCount == 0) {
      throw const AppException('emptyWorkoutWarning');
    }

    final db = await _appDatabase.database;
    await db.update(
      'workout_sessions',
      <String, Object?>{
        'status': WorkoutSessionStatus.completed.dbValue,
        'finished_at': _now(),
        'updated_at': _now(),
      },
      where: 'id = ?',
      whereArgs: <Object?>[sessionId],
    );

    return WorkoutSummary(
      exerciseCount: before.exercises.length,
      completedSetCount: completedSetCount,
      newBestCount: newBestCount,
    );
  }

  Future<void> discardSession(int sessionId) async {
    final db = await _appDatabase.database;
    await db.update(
      'workout_sessions',
      <String, Object?>{
        'status': WorkoutSessionStatus.cancelled.dbValue,
        'updated_at': _now(),
      },
      where: 'id = ?',
      whereArgs: <Object?>[sessionId],
    );
  }

  Future<PreviousSessionResult?> previousSessionForExercise(
    int exerciseId, {
    int? excludeSessionId,
  }) async {
    final db = await _appDatabase.database;
    final args = <Object?>[
      exerciseId,
      WorkoutSessionStatus.completed.dbValue,
      if (excludeSessionId != null) excludeSessionId,
    ];
    final rows = await db.rawQuery('''
      SELECT s.*
      FROM workout_sessions s
      INNER JOIN workout_exercise_logs l ON l.workout_session_id = s.id
      WHERE l.exercise_id = ?
        AND s.status = ?
        ${excludeSessionId == null ? '' : 'AND s.id != ?'}
      ORDER BY s.finished_at DESC, s.id DESC
      LIMIT 1
    ''', args);
    if (rows.isEmpty) {
      return null;
    }
    final session = WorkoutSession.fromMap(rows.single);
    final logRows = await db.query(
      'workout_exercise_logs',
      where: 'workout_session_id = ? AND exercise_id = ?',
      whereArgs: <Object?>[session.id, exerciseId],
      limit: 1,
    );
    if (logRows.isEmpty) {
      return null;
    }
    final log = WorkoutExerciseLog.fromMap(logRows.single);
    final sets = await db.query(
      'workout_set_logs',
      where: 'workout_exercise_log_id = ? AND is_completed = 1',
      whereArgs: <Object?>[log.id],
      orderBy: 'set_number ASC, id ASC',
    );
    return PreviousSessionResult(
      session: session,
      sets: sets.map(WorkoutSetLog.fromMap).toList(),
    );
  }

  Future<BestResult?> bestForExercise(
    int exerciseId,
    ExerciseType type, {
    int? excludeSessionId,
  }) async {
    final db = await _appDatabase.database;
    final args = <Object?>[
      exerciseId,
      WorkoutSessionStatus.completed.dbValue,
      if (excludeSessionId != null) excludeSessionId,
    ];
    final excludeClause = excludeSessionId == null ? '' : 'AND s.id != ?';
    final rows = await db.rawQuery('''
      SELECT ws.weight, ws.reps, s.finished_at, s.session_date
      FROM workout_set_logs ws
      INNER JOIN workout_exercise_logs l ON l.id = ws.workout_exercise_log_id
      INNER JOIN workout_sessions s ON s.id = l.workout_session_id
      WHERE l.exercise_id = ?
        AND s.status = ?
        AND ws.is_completed = 1
        $excludeClause
        ${type == ExerciseType.weighted ? 'AND ws.weight IS NOT NULL' : ''}
        AND ws.reps IS NOT NULL
      ORDER BY
        ${type == ExerciseType.weighted ? 'ws.weight DESC,' : ''}
        ws.reps DESC,
        COALESCE(s.finished_at, s.session_date) DESC,
        ws.id DESC
      LIMIT 1
    ''', args);
    if (rows.isEmpty) {
      return null;
    }
    final row = rows.single;
    final dateValue = row['finished_at'] ?? row['session_date'];
    return BestResult(
      exerciseId: exerciseId,
      type: type,
      weight: row['weight'] == null ? null : (row['weight'] as num).toDouble(),
      reps: row['reps'] as int?,
      date: DateTime.parse(dateValue as String),
    );
  }

  Future<ProgressOverview> progressOverview() async {
    final db = await _appDatabase.database;
    final exerciseRows = await db.rawQuery(
      '''
      SELECT DISTINCT e.*
      FROM exercises e
      INNER JOIN workout_exercise_logs l ON l.exercise_id = e.id
      INNER JOIN workout_sessions s ON s.id = l.workout_session_id
      WHERE s.status = ?
      ORDER BY e.name ASC
    ''',
      <Object?>[WorkoutSessionStatus.completed.dbValue],
    );

    final bests = <ExerciseBestSummary>[];
    for (final row in exerciseRows) {
      final exercise = Exercise.fromMap(row);
      bests.add(
        ExerciseBestSummary(
          exercise: exercise,
          best: await bestForExercise(exercise.id, exercise.type),
        ),
      );
    }

    final sessionRows = await db.rawQuery(
      '''
      SELECT s.*, COALESCE(d.name, 'Workout') AS day_name
      FROM workout_sessions s
      LEFT JOIN workout_days d ON d.id = s.workout_day_id
      WHERE s.status = ?
      ORDER BY s.finished_at DESC, s.id DESC
      LIMIT 10
    ''',
      <Object?>[WorkoutSessionStatus.completed.dbValue],
    );

    final recent = <RecentSessionSummary>[];
    for (final row in sessionRows) {
      final session = WorkoutSession.fromMap(row);
      final count = Sqflite.firstIntValue(
            await db.rawQuery(
              '''
              SELECT COUNT(*)
              FROM workout_set_logs ws
              INNER JOIN workout_exercise_logs l ON l.id = ws.workout_exercise_log_id
              WHERE l.workout_session_id = ?
                AND ws.is_completed = 1
            ''',
              <Object?>[session.id],
            ),
          ) ??
          0;
      recent.add(
        RecentSessionSummary(
          session: session,
          dayName: row['day_name'] as String,
          completedSetCount: count,
        ),
      );
    }

    return ProgressOverview(bests: bests, recentSessions: recent);
  }

  /// Completed sessions within [start, end) with everything that was played,
  /// newest first. Backs the monthly report.
  Future<List<SessionReport>> sessionsBetween(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _appDatabase.database;
    final sessionRows = await db.rawQuery(
      '''
      SELECT s.*, COALESCE(d.name, 'Workout') AS day_name
      FROM workout_sessions s
      LEFT JOIN workout_days d ON d.id = s.workout_day_id
      WHERE s.status = ?
        AND s.session_date >= ?
        AND s.session_date < ?
      ORDER BY s.session_date DESC, s.id DESC
    ''',
      <Object?>[
        WorkoutSessionStatus.completed.dbValue,
        start.toIso8601String(),
        end.toIso8601String(),
      ],
    );

    final reports = <SessionReport>[];
    for (final row in sessionRows) {
      final session = WorkoutSession.fromMap(row);
      final logRows = await db.query(
        'workout_exercise_logs',
        where: 'workout_session_id = ?',
        whereArgs: <Object?>[session.id],
        orderBy: 'sort_order ASC, id ASC',
      );
      final exercises = <ExerciseReport>[];
      for (final logRow in logRows) {
        final log = WorkoutExerciseLog.fromMap(logRow);
        final exerciseRows = await db.query(
          'exercises',
          where: 'id = ?',
          whereArgs: <Object?>[log.exerciseId],
          limit: 1,
        );
        if (exerciseRows.isEmpty) {
          continue;
        }
        final sets = await db.query(
          'workout_set_logs',
          where: 'workout_exercise_log_id = ? AND is_completed = 1',
          whereArgs: <Object?>[log.id],
          orderBy: 'set_number ASC, id ASC',
        );
        if (sets.isEmpty) {
          continue;
        }
        exercises.add(
          ExerciseReport(
            exercise: Exercise.fromMap(exerciseRows.single),
            sets: sets.map(WorkoutSetLog.fromMap).toList(),
          ),
        );
      }
      reports.add(
        SessionReport(
          session: session,
          dayName: row['day_name'] as String,
          exercises: exercises,
        ),
      );
    }
    return reports;
  }

  Future<List<ExerciseHistoryEntry>> exerciseHistory(int exerciseId) async {
    final db = await _appDatabase.database;
    final sessionRows = await db.rawQuery(
      '''
      SELECT s.*
      FROM workout_sessions s
      INNER JOIN workout_exercise_logs l ON l.workout_session_id = s.id
      WHERE l.exercise_id = ?
        AND s.status = ?
      ORDER BY s.finished_at DESC, s.id DESC
      LIMIT 50
    ''',
      <Object?>[exerciseId, WorkoutSessionStatus.completed.dbValue],
    );

    final history = <ExerciseHistoryEntry>[];
    for (final row in sessionRows) {
      final session = WorkoutSession.fromMap(row);
      final logRows = await db.query(
        'workout_exercise_logs',
        where: 'workout_session_id = ? AND exercise_id = ?',
        whereArgs: <Object?>[session.id, exerciseId],
        limit: 1,
      );
      if (logRows.isEmpty) {
        continue;
      }
      final log = WorkoutExerciseLog.fromMap(logRows.single);
      final sets = await db.query(
        'workout_set_logs',
        where: 'workout_exercise_log_id = ? AND is_completed = 1',
        whereArgs: <Object?>[log.id],
        orderBy: 'set_number ASC, id ASC',
      );
      history.add(
        ExerciseHistoryEntry(
          session: session,
          sets: sets.map(WorkoutSetLog.fromMap).toList(),
        ),
      );
    }
    return history;
  }

  Future<void> _ensureSettings(Database db) async {
    final rows = await db.query(
      'app_settings',
      where: 'id = ?',
      whereArgs: <Object?>[1],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return;
    }
    final stamp = _now();
    await db.insert('app_settings', <String, Object?>{
      'id': 1,
      'weight_unit': 'kg',
      'onboarding_completed': 0,
      'created_at': stamp,
      'updated_at': stamp,
    });
  }

  Future<List<WorkoutDayWithExercises>> _daysForProgram(
    DatabaseExecutor executor,
    int programId,
  ) async {
    final dayRows = await executor.query(
      'workout_days',
      where: 'program_id = ? AND deleted_at IS NULL',
      whereArgs: <Object?>[programId],
      orderBy: 'sort_order ASC, id ASC',
    );
    final days = <WorkoutDayWithExercises>[];
    for (final dayRow in dayRows) {
      final day = WorkoutDay.fromMap(dayRow);
      days.add(
        WorkoutDayWithExercises(
          day: day,
          exercises: await _assignmentsForDay(executor, day.id),
        ),
      );
    }
    return days;
  }

  Future<List<ExerciseAssignment>> _assignmentsForDay(
    DatabaseExecutor executor,
    int workoutDayId,
  ) async {
    final rows = await executor.rawQuery(
      '''
      SELECT wde.*
      FROM workout_day_exercises wde
      INNER JOIN exercises e ON e.id = wde.exercise_id
      WHERE wde.workout_day_id = ?
        AND e.deleted_at IS NULL
      ORDER BY wde.sort_order ASC, wde.id ASC
    ''',
      <Object?>[workoutDayId],
    );
    final assignments = <ExerciseAssignment>[];
    for (final row in rows) {
      final assignment = WorkoutDayExercise.fromMap(row);
      final exerciseRows = await executor.query(
        'exercises',
        where: 'id = ?',
        whereArgs: <Object?>[assignment.exerciseId],
        limit: 1,
      );
      if (exerciseRows.isEmpty) {
        continue;
      }
      assignments.add(
        ExerciseAssignment(
          assignment: assignment,
          exercise: Exercise.fromMap(exerciseRows.single),
          targetReps: await _targetRepsForAssignment(
            executor,
            assignment.id,
            assignment.defaultSets,
          ),
        ),
      );
    }
    return assignments;
  }

  /// Target reps per set for an assignment, padded with nulls to [setCount].
  Future<List<int?>> _targetRepsForAssignment(
    DatabaseExecutor executor,
    int assignmentId,
    int setCount,
  ) async {
    final rows = await executor.query(
      'workout_day_exercise_sets',
      where: 'workout_day_exercise_id = ?',
      whereArgs: <Object?>[assignmentId],
      orderBy: 'set_number ASC, id ASC',
    );
    final targets = List<int?>.filled(setCount, null, growable: true);
    for (final row in rows) {
      final index = (row['set_number'] as int) - 1;
      if (index >= 0 && index < targets.length) {
        targets[index] = row['target_reps'] as int?;
      }
    }
    return targets;
  }

  Future<int> _nextSortOrder(
    DatabaseExecutor executor, {
    required String table,
    required String where,
    required List<Object?> whereArgs,
    String column = 'sort_order',
    bool startAtOne = false,
  }) async {
    final value = Sqflite.firstIntValue(
      await executor.rawQuery(
        'SELECT MAX($column) FROM $table WHERE $where',
        whereArgs,
      ),
    );
    if (value == null) {
      return startAtOne ? 1 : 0;
    }
    return value + 1;
  }

  bool _isValidCompletedSet(WorkoutSetLog set, ExerciseType type) {
    if (!set.isCompleted || set.reps == null || set.reps! < 0) {
      return false;
    }
    if (type == ExerciseType.weighted) {
      return set.weight != null && set.weight! >= 0;
    }
    return true;
  }

  BestResult? _bestWeightedFromSets(Iterable<WorkoutSetLog> sets) {
    WorkoutSetLog? best;
    for (final set in sets) {
      if (set.weight == null || set.reps == null) {
        continue;
      }
      if (best == null ||
          set.weight! > best.weight! ||
          (set.weight == best.weight && set.reps! > best.reps!)) {
        best = set;
      }
    }
    if (best == null) {
      return null;
    }
    return BestResult(
      exerciseId: 0,
      type: ExerciseType.weighted,
      weight: best.weight,
      reps: best.reps,
      date: DateTime.now(),
    );
  }

  BestResult? _bestRepsFromSets(Iterable<WorkoutSetLog> sets) {
    WorkoutSetLog? best;
    for (final set in sets) {
      if (set.reps == null) {
        continue;
      }
      if (best == null || set.reps! > best.reps!) {
        best = set;
      }
    }
    if (best == null) {
      return null;
    }
    return BestResult(
      exerciseId: 0,
      type: ExerciseType.repsOnly,
      reps: best.reps,
      date: DateTime.now(),
    );
  }

  String _now() => DateTime.now().toIso8601String();

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}

class WorkoutDayDraft {
  const WorkoutDayDraft({required this.weekDay, required this.name});

  final int weekDay;
  final String name;
}
