import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_gym_progress_notebook/core/week_days.dart';
import 'package:personal_gym_progress_notebook/features/common/presentation/common_widgets.dart';
import 'package:personal_gym_progress_notebook/features/workout/domain/progress_calculator.dart';

void main() {
  group('formatWeight', () {
    test('drops trailing zeros for whole numbers', () {
      expect(formatWeight(45), '45');
      expect(formatWeight(45.0), '45');
    });

    test('keeps one decimal for fractional weights', () {
      expect(formatWeight(42.5), '42.5');
    });
  });

  group('week days', () {
    test('maps Sunday to app week day 0', () {
      // 2026-07-05 is a Sunday.
      expect(currentAppWeekDay(DateTime(2026, 7, 5)), 0);
      // 2026-07-06 is a Monday.
      expect(currentAppWeekDay(DateTime(2026, 7, 6)), 1);
      // 2026-07-11 is a Saturday.
      expect(currentAppWeekDay(DateTime(2026, 7, 11)), 6);
    });

    test('localizes week day names', () {
      expect(weekDayName(0, const Locale('en')), 'Sunday');
      expect(weekDayName(0, const Locale('ar')), 'الأحد');
      expect(weekDayName(5, const Locale('ar')), 'الجمعة');
    });
  });

  group('ProgressCalculator validation', () {
    test('rejects negative weight and accepts zero', () {
      expect(ProgressCalculator.isValidWeight(-5, required: true), isFalse);
      expect(ProgressCalculator.isValidWeight(0, required: true), isTrue);
      expect(ProgressCalculator.isValidWeight(null, required: true), isFalse);
      expect(ProgressCalculator.isValidWeight(null, required: false), isTrue);
    });

    test('rejects decimal and negative reps', () {
      expect(ProgressCalculator.isValidReps(10.5), isFalse);
      expect(ProgressCalculator.isValidReps(-1), isFalse);
      expect(ProgressCalculator.isValidReps(10), isTrue);
    });
  });
}
