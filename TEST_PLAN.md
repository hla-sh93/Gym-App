# Test Plan — Personal Gym Progress Notebook

**Version:** 1.2.0
**Author:** QA
**Scope:** Full functional, logic, flow, localization, and edge-case coverage of the
offline gym-notebook app, mapped to automated tests under `test/`.

---

## 1. Strategy

| Layer | Location | What it proves |
|---|---|---|
| Unit — validation & formatting | `test/unit/input_validation_test.dart`, `test/unit/format_and_week_days_test.dart` | Numeric parsing, weight formatting, week-day mapping, progress math |
| Unit — progress logic | `test/unit/progress_calculator_test.dart` | Best-weight/best-reps selection, tie-breakers, improvement detection |
| Integration — repository (real SQLite) | `test/unit/gym_repository_test.dart`, `test/unit/gym_repository_full_test.dart` | Every CRUD path, queries, history retention, archive/restore, session lifecycle |
| Integration — controller | `test/unit/gym_app_controller_test.dart` | State transitions, tab routing, error propagation, set editing sync |
| Widget — components & flows | `test/widget/*.dart` | Rendering, RTL, and the critical set-logging UI wiring end-to-end |

All database tests run against a **real SQLite database** (`sqflite_common_ffi`) with a
fresh file per test, so schema, foreign keys, and SQL are exercised — not mocked.

---

## 2. Requirement → Test coverage matrix

| # | Requirement (from product doc) | Test(s) |
|---|---|---|
| R1 | Create program, becomes active | `program management > creating a program makes it active` |
| R2 | One active program at a time | `creating a second program deactivates the first` |
| R3 | Program name required | controller `createProgram rejects blank names` |
| R4 | At least one training day | repo `createProgram with no days throws` |
| R5 | Add / edit / delete / reorder workout days | `workout day management > *` |
| R6 | Delete day keeps history | `deleteWorkoutDay hides day but keeps completed history` |
| R7 | Add weighted & reps-only exercises | `exercise management`, widget `exercise form switches type` |
| R8 | Edit exercise (name/type/sets/muscle) | `updateExercise changes name, type and default sets` |
| R9 | Delete exercise keeps history (soft delete) | repo `deleting an exercise keeps its workout history` |
| R10 | Start workout builds default sets | `startWorkout creates default sets` |
| R11 | Reps-only sets carry no weight | same test asserts `weight == null` |
| R12 | Resume existing in-progress session | `starting again returns the same in-progress session` |
| R13 | Record weight & reps per set | widget **CRITICAL** typing test |
| R14 | **Completing a set never loses typed values** | widget **CRITICAL** + stepper test |
| R15 | Add / delete sets, renumber sequentially | repo + controller + widget `add set and delete set` |
| R16 | Finish requires ≥1 completed set | repo & widget `finish with no completed sets` |
| R17 | Finish summary: exercises, sets, new bests | `finishing a logged workout produces a summary` |
| R18 | First-ever result counts as a new best | repo `first-ever completed workout counts as a new best` |
| R19 | Previous session shown per exercise | widget `second workout shows previous values` |
| R20 | Previous is per exercise identity | repo `previous session tracks per exercise` |
| R21 | Best weight w/ reps tie-breaker | repo `uses highest reps as tie breaker` |
| R22 | Best reps for reps-only | repo `finds best reps for reps-only` |
| R23 | Cancelled sessions excluded from stats | repo `ignores cancelled sessions` |
| R24 | Editing a past session updates bests | repo `editing a past session set updates the best value` |
| R25 | Archive program keeps history; restore | repo + controller archive/restore tests |
| R26 | Session recovery after app close | repo `in-progress session is recoverable` |
| R27 | Discard cancels session | controller `discardWorkout cancels the active session` |
| R28 | Settings: language, name, unit persist | repo `settings edge cases`, controller language/unit tests |
| R29 | Blank display name → null | repo `blank display name is stored as null` |
| R30 | Errors localized (AppException) | every `throwsA(isA<AppException>())` assertion |
| R31 | Onboarding → RTL Arabic home | widget `IT-001 onboarding` |
| R32 | Language switch flips direction live | widget `switching to Arabic flips direction` |
| R33 | Weight unit relabels fields | widget `changing weight unit relabels weight fields` |
| R34 | Home rest-day vs training-day states | widget `home states` |
| R35 | In-progress banner: continue/finish-later/discard | widget `in-progress banner supports finish later` |
| R36 | Negative weights / decimal reps rejected | `input_validation_test`, `progress_calculator` validation |
| R37 | Decimal weight incl. trailing separator | `input_validation` trailing-separator test |

---

## 3. Edge cases explicitly covered

- Empty database on first launch (controller `load initializes defaults`).
- Starting a day whose only exercise was deleted (`throws addAtLeastOneExercise`).
- Starting a missing day (`throws workoutDayNotFound`).
- Finishing with no active session (`throws sessionNotFound`).
- Two exercises with the same name — history stays keyed by id.
- Deleting a middle set renumbers the rest 1..n.
- Moving the last day further down is a no-op.
- Weight `42.` (mid-typing) parses as `42`; `.` alone is invalid.
- `42.25` shows two decimals, `42.50` shows one.

---

## 4. Manual / device checklist (per release)

Automated tests cannot verify device rendering. Before shipping an APK:

1. Install over previous version — confirm **version bumped** (`aapt dump badging`).
2. Launch on the target device (Xiaomi/MIUI) — active workout page renders (Impeller off).
3. Log a set, mark complete, confirm value persists; finish; reopen exercise → Previous shows it.
4. Switch to Arabic — layout is RTL, no overflow.
5. Rotate / small screen — no horizontal overflow.

---

## 5. How to run

```sh
flutter test                 # full suite
flutter test test/unit       # logic + repository + controller
flutter test test/widget     # UI flows
flutter analyze              # zero issues required
```

CI (`.github/workflows/ci.yml`) runs analyze + the full suite + a release APK build on every push.
