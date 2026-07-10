# Personal Gym Progress Notebook

Offline-first Flutter app for creating a personal workout program, logging set-by-set progress, and reviewing previous gym performance.

## Implemented MVP Scope

- Light-mode Flutter source project.
- English and Arabic localization with RTL/LTR direction switching.
- Offline SQLite persistence for settings, programs, workout days, exercises, sessions, exercise logs, and set logs.
- First-launch onboarding with language and optional display name.
- Program builder with training days and exercise management.
- Active workout logging with auto-saved set edits, add/delete set actions, previous-session display, and best-value display.
- In-progress workout recovery and discard flow.
- Workout finish validation and summary.
- Progress view with bests, recent completed sessions, and exercise history with best-set highlighting.
- Editing of past sessions from exercise history (bests update automatically).
- Archived programs list with restore.
- Weight unit setting (kg/lb).
- Localized (English/Arabic) error messages via `AppException`.
- Unit tests including a repository suite that runs against a real SQLite database (`sqflite_common_ffi`).
- GitHub Actions CI: analyze, test, and debug APK build.

## Local Setup

This environment does not have the Flutter SDK installed, so platform scaffolding was not generated here.

After installing Flutter, run:

```sh
flutter create --platforms=android,ios .
flutter pub get
flutter test
flutter run
```

If you also want desktop/web targets, include them in the `--platforms` list.

## Architecture

The app is organized around the documentation's MVP loop:

```text
Create Program -> Start Workout -> See Previous -> Record Today -> Review Progress
```

Key layers:

- `lib/database`: SQLite table creation and database access.
- `lib/features/workout/domain`: Core domain models and progress/validation logic.
- `lib/data`: Repository methods for offline CRUD and queries.
- `lib/app`: App shell, theme, and localization.
- `lib/features/*/presentation`: Flutter screens and reusable widgets.

No backend, login, network access, or cloud dependency is required for MVP features.
