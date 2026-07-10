# Personal Gym Progress Notebook — Flutter App Documentation

**Document type:** Product + Technical + QA Documentation  
**Role perspective:** Senior Product Manager  
**Platform:** Flutter-based mobile app  
**Mode:** Offline-first  
**App type:** Personal workout progress notebook  
**Version:** 1.0  
**Date:** 2026-07-09  

---

## 1. Product Summary

### 1.1 Product Vision

Build a simple, personal, offline-first mobile app that helps a gym user design their own workout program and track workout progress over time.

The app should feel like a clean digital gym notebook, not a complex fitness platform.

The core value is:

> The user can open today's workout, clearly see what they lifted last time, record today's sets, weights, and reps, then compare progress from session to session.

---

## 2. Product Positioning

### 2.1 What This App Is

The app is a:

- Personal workout notebook.
- Gym progress tracker.
- Offline workout log.
- Simple program planner.
- Set-by-set weight and reps recorder.

### 2.2 What This App Is Not

The app is not:

- A social fitness platform.
- A trainer/client management system.
- A subscription-based app.
- A video exercise library.
- A nutrition tracker.
- A complex AI coaching app.
- A gym management system.
- A cardio tracking platform.

---

## 3. Target User

### 3.1 Primary User

A person who trains at the gym and wants to:

- Create a custom workout program.
- Decide which days they train.
- Add exercises manually.
- Record each set separately.
- Track the exact weight and reps used per set.
- See previous performance clearly.
- Decide whether to increase weight or reps manually.
- Use the app without internet.

### 3.2 User Context

During a workout, the user is usually:

- Tired.
- Between sets.
- Holding the phone quickly.
- Not interested in long forms.
- Focused on recording numbers fast.
- Interested in previous performance, not complex analytics.

Therefore, the UX must prioritize:

- Speed.
- Clarity.
- Large touch targets.
- Minimal taps.
- Clear previous session data.
- Simple set editing.

---

## 4. Product Principles

### 4.1 Simplicity First

Every feature must support the main goal:

> Record gym progress quickly and clearly.

If a feature does not directly support that goal, it should not be included in MVP.

### 4.2 Offline First

The app must work fully without internet.

The user should be able to:

- Create programs.
- Add workout days.
- Add exercises.
- Start workouts.
- Record sets.
- View history.
- View progress.

All without network access.

### 4.3 User Controls Progression

The app must not force workout progression logic.

The app should show:

- Previous weight.
- Previous reps.
- Best weight.
- Last session history.

The user decides whether to increase, decrease, or keep the same weight.

### 4.4 Notebook Feel

The app should feel like a modern notebook:

- Clean.
- Light mode only.
- Not visually heavy.
- Minimal sports branding.
- No unnecessary gamification.

---

## 5. MVP Scope

### 5.1 Included in MVP

| Feature | Included |
|---|---:|
| Flutter mobile app | Yes |
| Arabic / English localization | Yes |
| Light mode only | Yes |
| Offline storage | Yes |
| No login required | Yes |
| Create custom program | Yes |
| Add workout days | Yes |
| Assign workout days to week days | Yes |
| Add custom exercises | Yes |
| Select exercise type: weighted or reps-only | Yes |
| Optional target muscle/icon | Yes |
| Start workout session | Yes |
| Record sets | Yes |
| Record weight per set | Yes |
| Record reps per set | Yes |
| Add/delete/edit sets | Yes |
| Show previous session per exercise | Yes |
| Show best weight per exercise | Yes |
| Exercise history | Yes |
| Basic progress summary | Yes |
| Fully responsive mobile UI | Yes |
| Unit/widget/integration tests | Yes |

### 5.2 Excluded from MVP

| Feature | Reason |
|---|---|
| Exercise videos | Adds complexity |
| Exercise image library | Not needed for notebook-style MVP |
| Trainer accounts | Not personal-use scope |
| Admin dashboard | Not required |
| Subscriptions | Not required |
| Social features | Out of scope |
| Cardio tracking | Later feature |
| Nutrition tracking | Out of scope |
| AI workout suggestions | Later feature |
| Cloud sync | Later feature |
| Dark mode | User requested light mode only |

---

## 6. Supported Languages

The app must support:

- Arabic.
- English.

### 6.1 Localization Rules

| Item | Arabic | English |
|---|---|---|
| App layout direction | RTL | LTR |
| Numbers | Arabic locale may use Arabic or Western digits depending on system settings | Western digits |
| Weight unit | kg by default | kg by default |
| Date format | Localized | Localized |
| Week days | Arabic names | English names |

### 6.2 Required Localization Testing

Test every main flow in both:

- Arabic RTL.
- English LTR.

No text should overflow, truncate incorrectly, or break layout.

---

## 7. Visual Design Direction

### 7.1 Theme

The app uses light mode only.

### 7.2 Suggested Design Style

- Clean white/soft-gray background.
- White cards.
- Subtle borders.
- Minimal shadows.
- Clear typography.
- Large numeric fields.
- Calm primary color.
- No heavy gradients.
- No decorative complexity.

### 7.3 Suggested Color Tokens

| Token | Value | Usage |
|---|---|---|
| `background` | `#F7F8FA` | App background |
| `surface` | `#FFFFFF` | Cards |
| `textPrimary` | `#111827` | Main text |
| `textSecondary` | `#6B7280` | Helper text |
| `border` | `#E5E7EB` | Card/input borders |
| `primary` | `#2563EB` | Main actions |
| `success` | `#16A34A` | Completed/new best |
| `warning` | `#F59E0B` | Missed/attention |
| `danger` | `#EF4444` | Delete/destructive |

### 7.4 Accessibility

Minimum accessibility standards:

- Large enough input fields.
- Good contrast.
- Tap targets should be at least 44px logical height.
- Font scaling should not break the layout.
- Icons should have semantic labels where needed.
- Do not rely on color alone to communicate progress.

---

## 8. Responsive Design Requirements

The app must be fully responsive across common mobile devices.

### 8.1 Required Screen Support

| Device Type | Requirement |
|---|---|
| Small phones | Must work without horizontal overflow |
| Standard phones | Primary target |
| Large phones | Use spacing well |
| Foldables/tablets | Layout should not stretch awkwardly |
| Landscape | Basic support; no broken layout |

### 8.2 Layout Rules

- Use responsive constraints, not fixed widths.
- Avoid hardcoded screen-size assumptions.
- Main content max width can be constrained on large screens.
- Use scrollable pages for workout forms.
- Bottom action buttons should remain reachable.
- Numeric inputs must remain readable on small screens.
- RTL layout must be tested separately.

### 8.3 Critical Responsive Screens

These screens require special testing:

1. Active Workout.
2. Create/Edit Program.
3. Create/Edit Exercise.
4. Exercise History.
5. Progress Summary.
6. Language switch flow.

---

## 9. App Navigation

### 9.1 Bottom Navigation

The MVP should use 4 main tabs:

| Tab | Purpose |
|---|---|
| Home | Today, next workout, quick start |
| Program | Manage program, workout days, exercises |
| Workout | Start or continue workout |
| Progress | Bests, history, simple progress |

Settings can be accessed from the Home/Profile area.

### 9.2 Main Screens

| Screen | Purpose |
|---|---|
| Splash | Load local data and settings |
| Language Selection | First-time language choice |
| Onboarding | Basic user name and app introduction |
| Home Dashboard | Today’s workout and quick actions |
| Program List | Current and archived programs |
| Create/Edit Program | Program setup |
| Program Details | Workout days inside a program |
| Create/Edit Workout Day | Day name and week-day assignment |
| Workout Day Details | Exercises in a selected day |
| Create/Edit Exercise | Exercise name, type, muscle/icon |
| Active Workout | Record sets, weight, reps |
| Workout Summary | After finishing session |
| Exercise History | Past sessions for one exercise |
| Progress | Best weights and recent improvements |
| Settings | Language, unit, data options |

---

## 10. User Flows

## 10.1 First Launch Flow

### Steps

1. User opens app.
2. App shows Splash.
3. App checks if language is selected.
4. If not selected, show Language Selection.
5. User chooses Arabic or English.
6. App asks for optional display name.
7. User lands on Home.
8. If no program exists, Home shows empty state.

### Empty State Copy

English:

> Create your first workout program to start tracking progress.

Arabic:

> أنشئ برنامجك التدريبي الأول لتبدأ بتسجيل تقدمك.

### Acceptance Criteria

- App must open without internet.
- Language selection must be saved locally.
- User should not be forced to create an account.
- Empty state must guide the user to create a program.

---

## 10.2 Create Program Flow

### Steps

1. User taps `Create Program`.
2. User enters program name.
3. User selects number of workout days per week.
4. User selects week days.
5. User saves program.
6. App creates the program as active.
7. User is redirected to Program Details.

### Example

Program name:

> My Gym Program

Training days:

- Sunday.
- Tuesday.
- Thursday.
- Saturday.

### Acceptance Criteria

- Program name is required.
- At least one workout day must be selected.
- Program must be saved offline.
- Created program becomes active by default.
- User can edit program later.

---

## 10.3 Create Workout Day Flow

### Steps

1. User opens Program Details.
2. User taps `Add Workout Day`.
3. User enters workout day name.
4. User assigns it to a week day.
5. User saves.

### Example

Workout day name:

> Push Day

Week day:

> Sunday

### Acceptance Criteria

- Workout day name is required.
- Week day is required.
- Multiple workout days can exist in one program.
- User can reorder workout days.
- User can edit or delete a workout day.

---

## 10.4 Add Exercise Flow

### Steps

1. User opens a workout day.
2. User taps `Add Exercise`.
3. User enters exercise name.
4. User selects exercise type:
   - Weighted.
   - Reps-only.
5. User optionally selects target muscle/icon.
6. User optionally sets default number of sets.
7. User saves exercise.

### Exercise Types

#### Weighted Exercise

Used for exercises like:

- Bench Press.
- Leg Press.
- Shoulder Press.
- Lat Pulldown.

Fields per set:

- Weight.
- Reps.

#### Reps-only Exercise

Used for exercises like:

- Push-ups.
- Pull-ups.
- Abs crunches.

Fields per set:

- Reps only.

### Acceptance Criteria

- Exercise name is required.
- Exercise type is required.
- Exercise must appear in the selected workout day.
- User can edit exercise later.
- User can delete exercise with confirmation.
- Deleting an exercise from a program must not delete historical workout records.

---

## 10.5 Start Workout Flow

### Steps

1. User opens Home.
2. App shows today’s scheduled workout if available.
3. User taps `Start Workout`.
4. App creates a new workout session.
5. Active Workout screen opens.
6. Exercises appear in the saved order.
7. Each exercise shows previous session data if available.

### Acceptance Criteria

- Workout must start offline.
- App must auto-save session data.
- If app closes, active session can be restored.
- If no previous session exists, show first-time state.
- User can also start a different workout day manually.

---

## 10.6 Record Set Flow

### Steps

1. User opens Active Workout.
2. User sees exercise card.
3. User enters weight and reps for Set 1.
4. User completes Set 1.
5. User adds or edits more sets.
6. App saves each change immediately.

### Acceptance Criteria

- Weighted exercises require weight and reps.
- Reps-only exercises require reps only.
- User can add a set.
- User can delete a set.
- User can edit a set.
- Every set must be saved locally.
- Input must handle decimals for weight, e.g. 42.5kg.
- Reps must be whole numbers.
- Negative numbers are not allowed.

---

## 10.7 Finish Workout Flow

### Steps

1. User taps `Finish Workout`.
2. App validates session.
3. App saves session as completed.
4. App calculates summary:
   - Number of exercises.
   - Number of sets.
   - New best weights.
   - Reps improvements.
5. App shows Workout Summary.

### Acceptance Criteria

- User can finish a workout with at least one completed set.
- App must warn if no sets were logged.
- Completed session must appear in history.
- Previous session for future workouts must now use the completed session.

---

## 10.8 View Exercise History Flow

### Steps

1. User opens Progress.
2. User selects an exercise.
3. App shows past sessions for that exercise.
4. App highlights:
   - Last session.
   - Best weight.
   - Best reps.
   - Session history.

### Acceptance Criteria

- History should use exercise identity, not only exercise name.
- History must remain available offline.
- Editing past sessions should update best values.
- Deleted program exercises should not delete history.

---

## 11. Data Model

The app should use local persistent storage.

Recommended storage approach:

- SQLite-based local database.
- Drift or sqflite can be used.
- SharedPreferences can be used only for simple settings like language and first-launch flag.

The data model should be relational because workout sessions, exercises, and sets have clear relationships.

---

## 11.1 Entities Overview

| Entity | Purpose |
|---|---|
| AppSettings | Stores language, unit, onboarding status |
| Program | User-created workout program |
| WorkoutDay | Training day inside a program |
| Exercise | User-created exercise |
| WorkoutDayExercise | Exercise assigned to a workout day |
| WorkoutSession | One actual performed workout |
| WorkoutExerciseLog | Exercise inside a session |
| WorkoutSetLog | Set-level data |
| MuscleIcon | Optional target muscle/icon |

---

## 11.2 AppSettings

```text
AppSettings
- id
- language_code
- weight_unit
- onboarding_completed
- display_name
- created_at
- updated_at
```

### Notes

- `language_code`: `ar` or `en`.
- `weight_unit`: default `kg`.

---

## 11.3 Program

```text
Program
- id
- name
- is_active
- created_at
- updated_at
- archived_at
```

### Rules

- One active program at a time.
- Old programs should be archived, not deleted by default.
- Historical workout sessions must remain even if a program is archived.

---

## 11.4 WorkoutDay

```text
WorkoutDay
- id
- program_id
- name
- week_day
- sort_order
- created_at
- updated_at
```

### Rules

- `week_day` can be Sunday through Saturday.
- `sort_order` controls display order.

---

## 11.5 Exercise

```text
Exercise
- id
- name
- type
- target_muscle
- muscle_icon_key
- created_at
- updated_at
- deleted_at
```

### Exercise Type Values

```text
weighted
reps_only
```

### Rules

- Soft-delete exercises when removed.
- Historical logs must remain connected to the exercise.

---

## 11.6 WorkoutDayExercise

```text
WorkoutDayExercise
- id
- workout_day_id
- exercise_id
- default_sets
- notes
- sort_order
- created_at
- updated_at
```

### Rules

- Same exercise can appear in multiple workout days.
- Same exercise history should still aggregate by `exercise_id`.

---

## 11.7 WorkoutSession

```text
WorkoutSession
- id
- workout_day_id
- program_id
- session_date
- started_at
- finished_at
- status
- notes
- created_at
- updated_at
```

### Status Values

```text
in_progress
completed
cancelled
```

### Rules

- In-progress session must be restorable.
- Completed session becomes part of history.
- Cancelled sessions should not affect progress stats.

---

## 11.8 WorkoutExerciseLog

```text
WorkoutExerciseLog
- id
- workout_session_id
- exercise_id
- sort_order
- notes
- created_at
- updated_at
```

### Rules

- Represents one exercise inside an actual workout session.
- Allows exercise-level notes.

---

## 11.9 WorkoutSetLog

```text
WorkoutSetLog
- id
- workout_exercise_log_id
- set_number
- weight
- reps
- is_completed
- created_at
- updated_at
```

### Rules

- For weighted exercises, `weight` and `reps` are used.
- For reps-only exercises, `weight` is null.
- Reps must be integer.
- Weight can be decimal.
- Set numbers should remain sequential after deletion.

---

## 12. Core Product Logic

## 12.1 Previous Session Logic

For each exercise in Active Workout:

1. Get the current `exercise_id`.
2. Find the latest completed `WorkoutSession`.
3. Include only sessions containing this `exercise_id`.
4. Exclude the active session.
5. Sort by `finished_at DESC`.
6. Return the latest result.

### Display

For weighted exercises:

```text
Previous
Set 1 · 40kg × 10
Set 2 · 42.5kg × 8
Set 3 · 42.5kg × 7
```

For reps-only exercises:

```text
Previous
Set 1 · 20 reps
Set 2 · 18 reps
Set 3 · 15 reps
```

### Edge Case

If no previous session exists:

```text
No previous data yet.
Start your first log.
```

---

## 12.2 Best Weight Logic

For weighted exercises:

1. Get all completed set logs for `exercise_id`.
2. Ignore cancelled sessions.
3. Find the highest `weight`.
4. If multiple sets have same highest weight, show highest reps at that weight.

Example:

```text
Best: 45kg × 8
```

### Tie-breaker

If two records have same weight and reps, show the latest date.

---

## 12.3 Best Reps Logic

For reps-only exercises:

1. Get all completed set logs for `exercise_id`.
2. Find max reps.
3. Show date and session.

Example:

```text
Best: 24 reps
```

---

## 12.4 Improvement Logic

The app should calculate basic improvements only.

### Improvement Types

| Type | Condition |
|---|---|
| New best weight | Today’s highest weight > previous best weight |
| More reps at same weight | Same weight as previous session but higher reps |
| Same result | Same weight and reps |
| Lower result | Lower weight or fewer reps |

### Important Rule

Do not force recommendations.

The app should display results only.

---

## 12.5 Volume Logic

Volume is optional in UI but useful internally.

For weighted exercises:

```text
Volume = weight × reps
Total Exercise Volume = sum of all set volumes
Workout Volume = sum of all exercise volumes
```

For reps-only exercises:

```text
Volume does not apply.
```

### MVP Display

Volume can be hidden in MVP unless needed in Progress.

---

## 12.6 Active Session Recovery Logic

If the app closes during a workout:

1. App checks for an `in_progress` session on launch.
2. If found, Home shows:

```text
Workout in progress
Continue or discard?
```

3. User chooses:
   - Continue.
   - Discard.
   - Finish later.

### Acceptance Criteria

- No workout data should be lost.
- Every set edit should be auto-saved.
- If the phone restarts, the session remains recoverable.

---

## 13. Input Validation Rules

### 13.1 Program

| Field | Validation |
|---|---|
| Name | Required, max 60 characters |
| Training days | At least 1 day |

### 13.2 Workout Day

| Field | Validation |
|---|---|
| Name | Required, max 60 characters |
| Week day | Required |

### 13.3 Exercise

| Field | Validation |
|---|---|
| Name | Required, max 80 characters |
| Type | Required |
| Target muscle | Optional |
| Default sets | Optional, 1–20 |

### 13.4 Set

| Field | Validation |
|---|---|
| Weight | Required for weighted exercises, decimal allowed, must be >= 0 |
| Reps | Required, integer, must be >= 0 |
| Completed | Boolean |

### 13.5 Numeric Input Rules

- Do not allow negative values.
- Allow decimal weights such as `42.5`.
- Reps must not allow decimals.
- Empty values should not crash the app.
- Invalid values should show inline validation, not blocking crashes.

---

## 14. UX Requirements

## 14.1 Active Workout Screen Requirements

This is the most important screen.

Each exercise card must include:

1. Exercise name.
2. Exercise type.
3. Optional muscle/icon.
4. Previous session.
5. Best value.
6. Today’s sets.
7. Add Set button.
8. Edit/delete set actions.

### Recommended Exercise Card Structure

```text
Bench Press

Previous
40kg × 10
42.5kg × 8
42.5kg × 7

Best
45kg × 6

Today
Set 1    [42.5 kg]    [10 reps]
Set 2    [45 kg]      [8 reps]
Set 3    [45 kg]      [6 reps]

+ Add Set
```

---

## 14.2 Quick Input Controls

For weight:

```text
[-2.5]  [45 kg]  [+2.5]
```

For reps:

```text
[-]  [10 reps]  [+]
```

### Notes

- Manual typing must still be possible.
- Step buttons reduce typing during workout.
- Weight increment can be 2.5kg by default.
- Later setting can allow custom increments.

---

## 14.3 Empty States

### No Program

```text
Create your first workout program.
```

### No Exercises

```text
Add exercises to this workout day.
```

### No Previous Data

```text
No previous data yet.
```

### No Progress

```text
Complete your first workout to see progress.
```

---

## 15. Technical Architecture

## 15.1 Recommended Architecture

Use a layered architecture:

```text
Presentation Layer
- Screens
- Widgets
- ViewModels / Controllers

Domain Layer
- Entities
- Use Cases
- Business Logic

Data Layer
- Local Database
- Repositories
- Data Mappers
```

### Why

This keeps the app:

- Easier to test.
- Easier to maintain.
- Less bug-prone.
- Easier to expand later.

---

## 15.2 Suggested Flutter Stack

| Area | Suggested Option |
|---|---|
| Framework | Flutter |
| Language | Dart |
| State Management | Riverpod or Bloc |
| Local Database | Drift/SQLite or sqflite |
| Simple Settings | SharedPreferences |
| Navigation | go_router |
| Localization | Flutter gen_l10n |
| Charts | fl_chart, later |
| Testing | flutter_test + integration_test |
| Linting | flutter_lints |
| CI | GitHub Actions |

### PM Recommendation

For this app, use:

```text
Flutter + Riverpod + Drift/SQLite + go_router + gen_l10n
```

Reason:

- The app has relational offline data.
- Previous session lookup needs reliable queries.
- Drift/SQLite is better than simple key-value storage for workout history.
- Riverpod keeps state predictable without overengineering.

---

## 15.3 Local Storage Recommendation

Use:

- SQLite/Drift for workout data.
- SharedPreferences for language, onboarding, and small settings.

### Why SQLite/Drift

The data has relationships:

- Program → Workout Days.
- Workout Day → Exercises.
- Workout Session → Exercise Logs.
- Exercise Logs → Set Logs.

This is naturally relational.

---

## 15.4 Offline-First Requirements

The app should not depend on internet for any MVP feature.

### Rules

- No API calls required.
- No remote login.
- No cloud dependency.
- Data saved locally.
- App must behave the same in airplane mode.
- App must never block workout logging because of connection state.

---

## 15.5 Error Handling

The app must handle:

- Empty local database.
- Invalid input.
- Deleted exercises.
- Archived programs.
- Interrupted active sessions.
- App force close.
- App update/migration.
- Language change.
- RTL layout rebuild.

### User-Facing Error Style

Errors should be:

- Short.
- Clear.
- Non-technical.

Example:

```text
Please enter reps before saving this set.
```

Arabic:

```text
يرجى إدخال عدد العدات قبل حفظ الدفعة.
```

---

## 16. Suggested Folder Structure

```text
lib/
  app/
    app.dart
    router.dart
    theme.dart
    localization/
  core/
    constants/
    errors/
    utils/
    widgets/
  features/
    onboarding/
      presentation/
      application/
      data/
    program/
      presentation/
      application/
      domain/
      data/
    workout/
      presentation/
      application/
      domain/
      data/
    progress/
      presentation/
      application/
      domain/
      data/
    settings/
      presentation/
      application/
      data/
  database/
    app_database.dart
    tables/
    daos/
  l10n/
    app_ar.arb
    app_en.arb
test/
  unit/
  widget/
integration_test/
```

---

## 17. Quality Standard

The user requested a bugless app.

No software can be guaranteed 100% bugless, but the project must be managed with a “zero known critical bugs” release standard.

### Release Quality Target

Before release:

- 0 critical bugs.
- 0 blocker bugs.
- 0 data-loss bugs.
- 0 crash bugs in main flows.
- 0 known RTL layout blockers.
- 0 known offline-mode blockers.
- 95%+ pass rate on planned test cases.
- All critical flows covered by integration tests.

---

## 18. Test Strategy

Testing must be planned from day one.

Flutter officially supports several test types, and the app should use all relevant layers:

- Unit tests for business logic.
- Widget tests for UI components.
- Integration tests for full user flows.
- Manual QA for real workout usability.
- Device testing for responsiveness and RTL.

---

## 18.1 Unit Tests

Unit tests should cover logic that does not require UI.

### Required Unit Test Areas

| Area | Examples |
|---|---|
| Previous session lookup | Latest completed session per exercise |
| Best weight logic | Highest weight + reps tie-breaker |
| Best reps logic | Reps-only exercise best |
| Volume calculation | weight × reps |
| Improvement detection | New best, more reps, same, lower |
| Validation | No negative weight, no decimal reps |
| Session status | in_progress/completed/cancelled |
| Archive logic | Archived program keeps history |
| Localization helpers | Week-day names |

### Sample Unit Test Cases

| ID | Scenario | Expected Result |
|---|---|---|
| UT-001 | No previous session exists | Return empty previous state |
| UT-002 | One previous completed session exists | Return that session |
| UT-003 | Multiple previous sessions exist | Return latest completed |
| UT-004 | Previous session is cancelled | Ignore cancelled session |
| UT-005 | Weighted exercise has 45kg × 6 and 45kg × 8 | Best = 45kg × 8 |
| UT-006 | Reps-only exercise has 20, 18, 25 reps | Best = 25 reps |
| UT-007 | Weight is -5 | Invalid |
| UT-008 | Reps value is 10.5 | Invalid |
| UT-009 | Volume for 40kg × 10 | 400 |
| UT-010 | Deleted exercise has old logs | History remains accessible |

---

## 18.2 Widget Tests

Widget tests should verify individual UI parts.

### Required Widget Test Areas

| Screen/Widget | Test Focus |
|---|---|
| Exercise Card | Previous data renders clearly |
| Set Row | Weight/reps fields work |
| Add Set Button | Adds new set row |
| Delete Set Action | Deletes selected set |
| Program Form | Validation messages |
| Exercise Form | Exercise type changes fields |
| Empty State | Correct message appears |
| Language Switch | Arabic/English labels update |
| RTL Layout | Arabic layout direction applies |
| Bottom Navigation | Correct selected tab |

### Sample Widget Test Cases

| ID | Scenario | Expected Result |
|---|---|---|
| WT-001 | Exercise has previous data | Previous section appears |
| WT-002 | Exercise has no previous data | Empty previous state appears |
| WT-003 | Weighted exercise set row | Weight and reps fields appear |
| WT-004 | Reps-only exercise set row | Only reps field appears |
| WT-005 | Tap Add Set | New set row appears |
| WT-006 | Delete set | Set row removed and numbers reorder |
| WT-007 | Arabic selected | App direction is RTL |
| WT-008 | English selected | App direction is LTR |
| WT-009 | Very long exercise name | Layout does not overflow |
| WT-010 | Small phone width | Active workout card remains usable |

---

## 18.3 Integration Tests

Integration tests should cover real user journeys.

### Required Integration Flows

| ID | Flow |
|---|---|
| IT-001 | First launch → select language → create program |
| IT-002 | Create program → create workout day → add exercise |
| IT-003 | Start workout → add sets → finish workout |
| IT-004 | Second workout → previous session appears |
| IT-005 | Edit set → best value updates |
| IT-006 | Reps-only exercise flow |
| IT-007 | App closes during active workout → restore session |
| IT-008 | Change language to Arabic → verify RTL |
| IT-009 | Airplane mode → complete full workout |
| IT-010 | Archive program → history remains |

---

## 18.4 Manual QA Scenarios

Manual QA is required because this app will be used during a real workout.

### Real Gym Usability Test

Tester should use the app during an actual gym session.

Check:

- Can user record a set quickly?
- Is previous weight visible enough?
- Are numeric buttons easy to tap?
- Can user edit mistakes quickly?
- Does the app feel distracting?
- Are inputs too small?
- Is scrolling comfortable?
- Does app stay responsive with many exercises?
- Does app recover if user locks phone?

---

## 18.5 Regression Test Checklist

Before every release:

- Create program.
- Edit program.
- Delete/archive program.
- Add workout day.
- Edit workout day.
- Add weighted exercise.
- Add reps-only exercise.
- Start workout.
- Add set.
- Delete set.
- Finish workout.
- View summary.
- View exercise history.
- View progress.
- Switch Arabic/English.
- Test offline mode.
- Kill app during active workout.
- Restore workout.
- Test small phone layout.
- Test large phone layout.

---

## 19. Bug Severity Levels

| Severity | Definition | Release Rule |
|---|---|---|
| Blocker | App cannot be used | Must fix |
| Critical | Data loss/crash/main flow broken | Must fix |
| High | Important feature broken | Must fix for MVP |
| Medium | Workaround exists | Can defer if documented |
| Low | Cosmetic/minor | Can defer |
| Enhancement | Improvement request | Backlog |

### Data Loss Rule

Any bug that causes workout data loss is automatically Critical.

---

## 20. Acceptance Criteria by Feature

## 20.1 Program Creation

- User can create a program offline.
- Program name is required.
- User can select training days.
- Program appears on Home and Program tab.
- Program can be edited.

## 20.2 Workout Day Management

- User can add workout days.
- User can assign week days.
- User can edit workout day name.
- User can reorder workout days.
- User can delete workout days with confirmation.

## 20.3 Exercise Management

- User can add custom exercises.
- User can select weighted or reps-only.
- User can optionally select target muscle/icon.
- User can edit exercises.
- User can delete exercises without deleting history.

## 20.4 Active Workout

- User can start workout from Home.
- User can start workout from Program details.
- Previous session appears per exercise.
- User can add sets.
- User can edit sets.
- User can delete sets.
- App auto-saves data.
- User can finish workout.
- Completed workout appears in history.

## 20.5 Progress

- User can see best weight per weighted exercise.
- User can see best reps per reps-only exercise.
- User can see recent completed workouts.
- User can open exercise history.
- Progress updates after editing a past workout.

## 20.6 Localization

- User can switch Arabic/English.
- Arabic layout is RTL.
- English layout is LTR.
- All MVP screens are translated.
- No hardcoded text remains.

## 20.7 Offline

- App works in airplane mode.
- All data saves locally.
- App does not require login.
- App does not require backend.
- App can reopen saved data after restart.

---

## 21. Milestones

## Milestone 0 — Scope Lock & Product Setup

### Goal

Freeze MVP scope and avoid feature creep.

### Deliverables

- Final feature list.
- Final app map.
- Final data model.
- Final acceptance criteria.
- Final UI direction.

### Exit Criteria

- MVP scope approved.
- Excluded features documented.
- Main flows approved.

---

## Milestone 1 — UX Wireframes

### Goal

Create low-fidelity wireframes for core screens.

### Screens

- Splash.
- Language Selection.
- Home.
- Create Program.
- Program Details.
- Workout Day Details.
- Create Exercise.
- Active Workout.
- Workout Summary.
- Progress.
- Exercise History.
- Settings.

### Exit Criteria

- All MVP screens mapped.
- Active Workout screen approved.
- RTL/LTR structure considered.
- No major UX blockers.

---

## Milestone 2 — UI Design System

### Goal

Create consistent light-mode UI system.

### Deliverables

- Color tokens.
- Typography.
- Buttons.
- Input fields.
- Cards.
- Set row component.
- Exercise card.
- Empty states.
- Error states.
- RTL/LTR examples.

### Exit Criteria

- Components approved.
- Active Workout component tested visually.
- Responsive behavior defined.

---

## Milestone 3 — Flutter Project Setup

### Goal

Prepare technical foundation.

### Deliverables

- Flutter project initialized.
- Folder structure created.
- Routing configured.
- Theme configured.
- Localization configured.
- Local database package configured.
- State management configured.
- Linting configured.
- Basic CI pipeline configured.

### Exit Criteria

- App builds successfully.
- App runs on Android emulator.
- App runs on iOS simulator if available.
- Unit test command runs.
- Widget test command runs.

---

## Milestone 4 — Local Database & Domain Logic

### Goal

Implement offline data model and business logic.

### Deliverables

- Database tables.
- DAOs/repositories.
- Program CRUD.
- WorkoutDay CRUD.
- Exercise CRUD.
- WorkoutSession CRUD.
- Set logs CRUD.
- Previous session query.
- Best weight query.
- Best reps query.

### Exit Criteria

- Database migration works.
- Unit tests pass.
- No data lost after app restart.
- Previous session logic verified.

---

## Milestone 5 — Program Builder

### Goal

Allow user to create and manage workout program.

### Deliverables

- Create Program screen.
- Edit Program screen.
- Program Details screen.
- Workout Day management.
- Exercise management.

### Exit Criteria

- User can create full program offline.
- User can edit program.
- User can add exercises.
- Widget tests pass.

---

## Milestone 6 — Active Workout Logging

### Goal

Build the core logging experience.

### Deliverables

- Start Workout flow.
- Active Workout screen.
- Weighted set rows.
- Reps-only set rows.
- Add/delete/edit sets.
- Previous session display.
- Best display.
- Auto-save.
- Session recovery.

### Exit Criteria

- User can complete workout.
- App can recover interrupted workout.
- Previous values appear in second session.
- Integration test for full workout passes.

---

## Milestone 7 — History & Progress

### Goal

Allow user to review performance.

### Deliverables

- Workout Summary.
- Exercise History.
- Progress screen.
- Best values.
- Recent improvements.
- Basic completed workout list.

### Exit Criteria

- Completed sessions appear correctly.
- Best values update correctly.
- Editing old session updates progress.
- Tests pass.

---

## Milestone 8 — Localization & Responsive QA

### Goal

Make app production-ready in Arabic and English.

### Deliverables

- Arabic translations.
- English translations.
- RTL support.
- LTR support.
- Small/large phone QA.
- Text overflow fixes.

### Exit Criteria

- Arabic screens are usable.
- English screens are usable.
- No major layout overflow.
- Active Workout works on small devices.

---

## Milestone 9 — Full QA & Bug Fixing

### Goal

Reach release-quality build.

### Deliverables

- Unit test suite.
- Widget test suite.
- Integration test suite.
- Manual QA report.
- Bug tracker.
- Fixed critical/high bugs.
- Regression test pass.

### Exit Criteria

- 0 blocker bugs.
- 0 critical bugs.
- 0 known data-loss bugs.
- 0 known crash bugs in main flows.
- Offline testing passed.
- RTL/LTR testing passed.

---

## Milestone 10 — Release Candidate

### Goal

Prepare final app build.

### Deliverables

- Release build.
- App icon.
- Splash screen.
- Version number.
- Privacy note.
- Local data disclaimer.
- Final QA checklist.
- Release notes.

### Exit Criteria

- Release build tested.
- No critical issues.
- App ready for personal use or closed testing.

---

## 22. Suggested Development Timeline

This depends on team size, but a realistic timeline is:

| Milestone | Estimated Duration |
|---|---:|
| Scope Lock | 1–2 days |
| UX Wireframes | 3–5 days |
| UI Design System | 3–5 days |
| Flutter Setup | 1–2 days |
| Database & Logic | 5–7 days |
| Program Builder | 5–7 days |
| Active Workout Logging | 7–10 days |
| History & Progress | 4–6 days |
| Localization & Responsive QA | 3–5 days |
| Full QA & Fixing | 5–10 days |
| Release Candidate | 2–3 days |

### Total Estimate

Approximately:

```text
5–8 weeks for a polished MVP
```

This assumes one Flutter developer plus design/product support.

---

## 23. Development Workflow

### 23.1 Recommended Sprint Structure

Each sprint should include:

1. Planning.
2. Development.
3. Code review.
4. Unit tests.
5. Widget tests.
6. Manual QA.
7. Bug fixing.
8. Demo.

### 23.2 Definition of Ready

A task is ready for development only when it has:

- Clear user story.
- Acceptance criteria.
- Design or wireframe.
- Data requirements.
- Edge cases.
- Test expectations.

### 23.3 Definition of Done

A task is done only when:

- Code is implemented.
- Code reviewed.
- Unit/widget tests added where needed.
- Manual QA passed.
- No critical bugs.
- Works offline.
- Works in Arabic and English if UI-facing.
- Responsive behavior checked.

---

## 24. User Stories

## 24.1 Program

```text
As a user,
I want to create my own workout program,
so that I can organize my gym days.
```

### Acceptance Criteria

- User can name the program.
- User can select training days.
- Program is saved locally.
- Program appears on Home.

---

## 24.2 Exercise

```text
As a user,
I want to add custom exercises,
so that my program matches my real gym routine.
```

### Acceptance Criteria

- User can add exercise name.
- User can choose weighted or reps-only.
- User can choose optional target muscle/icon.
- Exercise appears inside the selected workout day.

---

## 24.3 Previous Performance

```text
As a user,
I want to see what I lifted last time,
so that I can decide whether to increase weight or reps.
```

### Acceptance Criteria

- Previous session appears on Active Workout.
- Previous data is shown per set.
- If no previous data exists, empty state appears.

---

## 24.4 Set Logging

```text
As a user,
I want to record each set separately,
so that I can track gradual weight increases during the exercise.
```

### Acceptance Criteria

- User can add multiple sets.
- Each set has separate weight and reps.
- Weighted exercise uses weight + reps.
- Reps-only exercise uses reps only.

---

## 24.5 Offline Use

```text
As a user,
I want the app to work without internet,
so that I can use it inside the gym anytime.
```

### Acceptance Criteria

- User can complete all main flows offline.
- No login is required.
- All data is saved locally.

---

## 25. Edge Cases

| Edge Case | Expected Behavior |
|---|---|
| User starts workout and closes app | Session can be restored |
| User deletes exercise from program | History remains |
| User archives program | Old sessions remain |
| User enters negative weight | Validation error |
| User enters decimal reps | Validation error |
| User changes language mid-session | Data remains, layout updates |
| User has no program | Home shows create program CTA |
| User has no previous session | Show first-time state |
| User adds many sets | Screen remains scrollable |
| User has very long exercise name | Text wraps safely |
| Phone is offline | App works normally |
| App database is empty | App initializes safely |
| App update includes DB migration | Existing data preserved |

---

## 26. Performance Requirements

| Requirement | Target |
|---|---|
| App launch | Fast enough for daily use |
| Active Workout screen | Smooth scrolling |
| Set save | Immediate local save |
| Previous session query | No visible delay |
| History loading | Paginate or limit if needed |
| Offline mode | No blocking operations |
| Memory usage | No unnecessary large assets |

### Performance Notes

- Avoid loading all historical sessions at once.
- Use efficient database queries.
- Keep exercise history paginated if it grows.
- Avoid heavy animations on Active Workout.
- Minimize rebuilds in set rows.

---

## 27. Security & Privacy

Since this is a personal offline app:

- No account required.
- No backend.
- No personal data sent to server.
- Data remains on the device.
- User should be warned that deleting the app may delete local data unless backup/export exists.

### Privacy Note Copy

English:

> Your workout data is stored locally on this device.

Arabic:

> يتم حفظ بيانات التمرين محلياً على هذا الجهاز.

---

## 28. Future Enhancements

These are not MVP features.

| Feature | Priority Later |
|---|---|
| Export workout history as CSV/PDF | High |
| Backup to Google Drive/iCloud | High |
| Optional account sync | Medium |
| Dark mode | Medium |
| Rest timer | Medium |
| Charts | Medium |
| Time-based exercises | Medium |
| Exercise templates | Low |
| AI suggestions | Low |
| Cardio tracking | Low |

---

## 29. Key Risks

| Risk | Impact | Mitigation |
|---|---|---|
| App becomes too complex | High | Keep MVP strict |
| Data loss | Critical | Auto-save, tests, migrations |
| Active Workout is slow | High | Optimize UI and queries |
| RTL bugs | Medium | Test Arabic from early stage |
| User input mistakes | Medium | Easy edit/delete |
| Database migration bugs | High | Migration tests |
| Layout breaks on small phones | High | Responsive QA |

---

## 30. Final MVP Success Criteria

The MVP is successful if the user can:

1. Open the app without internet.
2. Create a custom workout program.
3. Add training days.
4. Add exercises.
5. Start a workout.
6. See previous performance clearly.
7. Record every set with weight and reps.
8. Finish workout.
9. Open the same exercise later and see progress.
10. Use the app comfortably in Arabic or English.
11. Use the app on different phone sizes without broken UI.
12. Trust that data is saved and not lost.

---

## 31. References

The following official Flutter resources should guide implementation:

- Flutter app architecture guide: https://docs.flutter.dev/app-architecture/guide
- Flutter offline-first design pattern: https://docs.flutter.dev/app-architecture/design-patterns/offline-first
- Flutter persistence cookbook: https://docs.flutter.dev/cookbook/persistence
- Flutter SQLite persistence recipe: https://docs.flutter.dev/cookbook/persistence/sqlite
- Flutter testing overview: https://docs.flutter.dev/testing/overview
- Flutter integration testing: https://docs.flutter.dev/testing/integration-tests
- Flutter performance best practices: https://docs.flutter.dev/perf/best-practices
- Flutter deployment guide: https://docs.flutter.dev/deployment

---

## 32. PM Final Recommendation

Build this app as a strict MVP first.

The best version is not the one with the most features.  
The best version is the one the user can actually open during a workout and use in seconds.

The product should remain focused on the main loop:

```text
Create Program → Start Workout → See Previous → Record Today → Review Progress
```

Everything else should be considered secondary.
