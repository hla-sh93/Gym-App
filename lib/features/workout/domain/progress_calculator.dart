import 'models.dart';

enum ImprovementType {
  newBestWeight,
  moreRepsAtSameWeight,
  sameResult,
  lowerResult,
  noPreviousData,
}

class PerformanceSet {
  const PerformanceSet({
    required this.exerciseId,
    required this.type,
    required this.reps,
    required this.completedAt,
    this.weight,
    this.status = WorkoutSessionStatus.completed,
    this.isCompleted = true,
  });

  final int exerciseId;
  final ExerciseType type;
  final double? weight;
  final int reps;
  final DateTime completedAt;
  final WorkoutSessionStatus status;
  final bool isCompleted;
}

class ProgressCalculator {
  const ProgressCalculator._();

  static double volume(double weight, int reps) => weight * reps;

  static bool isValidWeight(double? value, {required bool required}) {
    if (value == null) {
      return !required;
    }
    return value >= 0;
  }

  static bool isValidReps(num? value) {
    if (value == null) {
      return false;
    }
    return value >= 0 && value % 1 == 0;
  }

  static BestResult? bestWeighted({
    required int exerciseId,
    required Iterable<PerformanceSet> sets,
  }) {
    final eligible = sets.where(
      (set) =>
          set.exerciseId == exerciseId &&
          set.type == ExerciseType.weighted &&
          set.status == WorkoutSessionStatus.completed &&
          set.isCompleted &&
          set.weight != null,
    );
    PerformanceSet? best;
    for (final set in eligible) {
      if (best == null ||
          set.weight! > best.weight! ||
          (set.weight == best.weight && set.reps > best.reps) ||
          (set.weight == best.weight &&
              set.reps == best.reps &&
              set.completedAt.isAfter(best.completedAt))) {
        best = set;
      }
    }
    if (best == null) {
      return null;
    }
    return BestResult(
      exerciseId: exerciseId,
      type: ExerciseType.weighted,
      weight: best.weight,
      reps: best.reps,
      date: best.completedAt,
    );
  }

  static BestResult? bestRepsOnly({
    required int exerciseId,
    required Iterable<PerformanceSet> sets,
  }) {
    final eligible = sets.where(
      (set) =>
          set.exerciseId == exerciseId &&
          set.type == ExerciseType.repsOnly &&
          set.status == WorkoutSessionStatus.completed &&
          set.isCompleted,
    );
    PerformanceSet? best;
    for (final set in eligible) {
      if (best == null ||
          set.reps > best.reps ||
          (set.reps == best.reps &&
              set.completedAt.isAfter(best.completedAt))) {
        best = set;
      }
    }
    if (best == null) {
      return null;
    }
    return BestResult(
      exerciseId: exerciseId,
      type: ExerciseType.repsOnly,
      reps: best.reps,
      date: best.completedAt,
    );
  }

  static ImprovementType compareWeighted({
    required double? previousWeight,
    required int? previousReps,
    required double? currentWeight,
    required int? currentReps,
  }) {
    if (previousWeight == null || previousReps == null) {
      return ImprovementType.noPreviousData;
    }
    if (currentWeight == null || currentReps == null) {
      return ImprovementType.lowerResult;
    }
    if (currentWeight > previousWeight) {
      return ImprovementType.newBestWeight;
    }
    if (currentWeight == previousWeight && currentReps > previousReps) {
      return ImprovementType.moreRepsAtSameWeight;
    }
    if (currentWeight == previousWeight && currentReps == previousReps) {
      return ImprovementType.sameResult;
    }
    return ImprovementType.lowerResult;
  }
}
