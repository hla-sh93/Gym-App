class InputValidation {
  const InputValidation._();

  static bool requiredText(String value, {int maxLength = 60}) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty && trimmed.length <= maxLength;
  }

  static double? parseWeight(String value) {
    var normalized = value.trim().replaceAll(',', '.');
    // A trailing separator means the user is mid-typing ("42."): treat as 42.
    if (normalized.endsWith('.')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    if (normalized.isEmpty) {
      return null;
    }
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed < 0) {
      return null;
    }
    return parsed;
  }

  static int? parseReps(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.contains('.') || trimmed.contains(',')) {
      return null;
    }
    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed < 0) {
      return null;
    }
    return parsed;
  }

  static int clampDefaultSets(int value) {
    if (value < 1) {
      return 1;
    }
    if (value > 20) {
      return 20;
    }
    return value;
  }
}
