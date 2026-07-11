import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase({this.databaseName = 'gym_notebook.db'});

  final String databaseName;
  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }
    final opened = await _open();
    _database = opened;
    return opened;
  }

  Future<void> close() async {
    final existing = _database;
    if (existing != null) {
      await existing.close();
      _database = null;
    }
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      p.join(dbPath, databaseName),
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _migrateToV2(db);
        }
      },
    );
  }

  /// v2: planned per-set targets (coach sheet) + reminder settings.
  Future<void> _migrateToV2(Database db) async {
    await db.execute('''
      CREATE TABLE workout_day_exercise_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_day_exercise_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        target_weight REAL,
        target_reps INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (workout_day_exercise_id)
          REFERENCES workout_day_exercises(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_planned_sets_assignment '
      'ON workout_day_exercise_sets(workout_day_exercise_id, set_number)',
    );
    await db.execute(
      'ALTER TABLE app_settings ADD COLUMN reminders_enabled INTEGER NOT NULL '
      'DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE app_settings ADD COLUMN reminder_hour INTEGER NOT NULL '
      'DEFAULT 18',
    );
  }

  Future<void> _createSchema(Database db) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE app_settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        language_code TEXT,
        weight_unit TEXT NOT NULL DEFAULT 'kg',
        onboarding_completed INTEGER NOT NULL DEFAULT 0,
        display_name TEXT,
        reminders_enabled INTEGER NOT NULL DEFAULT 0,
        reminder_hour INTEGER NOT NULL DEFAULT 18,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE programs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        archived_at TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE workout_days (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        program_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        week_day INTEGER NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (program_id) REFERENCES programs(id)
      )
    ''');

    batch.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        target_muscle TEXT,
        muscle_icon_key TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE workout_day_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_day_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        default_sets INTEGER NOT NULL DEFAULT 3,
        notes TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (workout_day_id) REFERENCES workout_days(id),
        FOREIGN KEY (exercise_id) REFERENCES exercises(id)
      )
    ''');

    batch.execute('''
      CREATE TABLE workout_day_exercise_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_day_exercise_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        target_weight REAL,
        target_reps INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (workout_day_exercise_id)
          REFERENCES workout_day_exercises(id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE workout_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_day_id INTEGER NOT NULL,
        program_id INTEGER NOT NULL,
        session_date TEXT NOT NULL,
        started_at TEXT NOT NULL,
        finished_at TEXT,
        status TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (workout_day_id) REFERENCES workout_days(id),
        FOREIGN KEY (program_id) REFERENCES programs(id)
      )
    ''');

    batch.execute('''
      CREATE TABLE workout_exercise_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_session_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (workout_session_id) REFERENCES workout_sessions(id),
        FOREIGN KEY (exercise_id) REFERENCES exercises(id)
      )
    ''');

    batch.execute('''
      CREATE TABLE workout_set_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_exercise_log_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        weight REAL,
        reps INTEGER,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (workout_exercise_log_id) REFERENCES workout_exercise_logs(id) ON DELETE CASCADE
      )
    ''');

    batch.execute(
      'CREATE INDEX idx_programs_active ON programs(is_active, archived_at)',
    );
    batch.execute(
      'CREATE INDEX idx_workout_days_program ON workout_days(program_id, sort_order)',
    );
    batch.execute(
      'CREATE INDEX idx_day_exercises_day ON workout_day_exercises(workout_day_id, sort_order)',
    );
    batch.execute(
      'CREATE INDEX idx_planned_sets_assignment '
      'ON workout_day_exercise_sets(workout_day_exercise_id, set_number)',
    );
    batch.execute(
      'CREATE INDEX idx_sessions_status ON workout_sessions(status, finished_at)',
    );
    batch.execute(
      'CREATE INDEX idx_exercise_logs_exercise ON workout_exercise_logs(exercise_id)',
    );
    batch.execute(
      'CREATE INDEX idx_set_logs_exercise_log ON workout_set_logs(workout_exercise_log_id, set_number)',
    );

    await batch.commit(noResult: true);
  }
}
