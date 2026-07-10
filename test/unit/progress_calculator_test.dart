import 'package:flutter_test/flutter_test.dart';
import 'package:personal_gym_progress_notebook/features/workout/domain/models.dart';
import 'package:personal_gym_progress_notebook/features/workout/domain/progress_calculator.dart';

void main() {
  group('ProgressCalculator', () {
    test('returns null when no previous weighted sets exist', () {
      final best = ProgressCalculator.bestWeighted(
        exerciseId: 1,
        sets: const <PerformanceSet>[],
      );

      expect(best, isNull);
    });

    test('uses highest reps as tie breaker for same weight', () {
      final date = DateTime.utc(2026, 1, 1);
      final best = ProgressCalculator.bestWeighted(
        exerciseId: 1,
        sets: <PerformanceSet>[
          PerformanceSet(
            exerciseId: 1,
            type: ExerciseType.weighted,
            weight: 45,
            reps: 6,
            completedAt: date,
          ),
          PerformanceSet(
            exerciseId: 1,
            type: ExerciseType.weighted,
            weight: 45,
            reps: 8,
            completedAt: date.add(const Duration(days: 1)),
          ),
        ],
      );

      expect(best?.weight, 45);
      expect(best?.reps, 8);
    });

    test('ignores cancelled sessions for best values', () {
      final best = ProgressCalculator.bestWeighted(
        exerciseId: 1,
        sets: <PerformanceSet>[
          PerformanceSet(
            exerciseId: 1,
            type: ExerciseType.weighted,
            weight: 80,
            reps: 1,
            status: WorkoutSessionStatus.cancelled,
            completedAt: DateTime.utc(2026, 1, 1),
          ),
          PerformanceSet(
            exerciseId: 1,
            type: ExerciseType.weighted,
            weight: 50,
            reps: 10,
            completedAt: DateTime.utc(2026, 1, 2),
          ),
        ],
      );

      expect(best?.weight, 50);
      expect(best?.reps, 10);
    });

    test('finds best reps-only value', () {
      final best = ProgressCalculator.bestRepsOnly(
        exerciseId: 2,
        sets: <PerformanceSet>[
          PerformanceSet(
            exerciseId: 2,
            type: ExerciseType.repsOnly,
            reps: 20,
            completedAt: DateTime.utc(2026, 1, 1),
          ),
          PerformanceSet(
            exerciseId: 2,
            type: ExerciseType.repsOnly,
            reps: 25,
            completedAt: DateTime.utc(2026, 1, 2),
          ),
        ],
      );

      expect(best?.reps, 25);
    });

    test('calculates weighted volume', () {
      expect(ProgressCalculator.volume(40, 10), 400);
    });

    test('detects more reps at same weight', () {
      final result = ProgressCalculator.compareWeighted(
        previousWeight: 42.5,
        previousReps: 8,
        currentWeight: 42.5,
        currentReps: 10,
      );

      expect(result, ImprovementType.moreRepsAtSameWeight);
    });
  });
}
