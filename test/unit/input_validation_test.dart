import 'package:flutter_test/flutter_test.dart';
import 'package:personal_gym_progress_notebook/core/input_validation.dart';

void main() {
  group('InputValidation', () {
    test('rejects empty names', () {
      expect(InputValidation.requiredText(''), isFalse);
      expect(InputValidation.requiredText('   '), isFalse);
    });

    test('parses decimal weights and rejects negatives', () {
      expect(InputValidation.parseWeight('42.5'), 42.5);
      expect(InputValidation.parseWeight('42,5'), 42.5);
      expect(InputValidation.parseWeight('-5'), isNull);
    });

    test('reps must be whole non-negative numbers', () {
      expect(InputValidation.parseReps('10'), 10);
      expect(InputValidation.parseReps('10.5'), isNull);
      expect(InputValidation.parseReps('-1'), isNull);
    });

    test('clamps default sets between one and twenty', () {
      expect(InputValidation.clampDefaultSets(0), 1);
      expect(InputValidation.clampDefaultSets(21), 20);
      expect(InputValidation.clampDefaultSets(3), 3);
    });
  });
}
