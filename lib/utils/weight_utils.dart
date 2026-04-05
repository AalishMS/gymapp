class WeightUtils {
  static const double kgToLbsMultiplier = 2.20462;

  /// Converts weight from kg to lbs if needed
  static double convertWeight(double weightInKg, String targetUnit) {
    if (targetUnit.toLowerCase() == 'lbs') {
      return weightInKg * kgToLbsMultiplier;
    }
    return weightInKg;
  }

  /// Converts weight from display unit back to kg for storage
  static double convertToKg(double displayWeight, String currentUnit) {
    if (currentUnit.toLowerCase() == 'lbs') {
      return displayWeight / kgToLbsMultiplier;
    }
    return displayWeight;
  }

  /// Formats weight with appropriate unit
  static String formatWeight(double weightInKg, String unit) {
    final convertedWeight = convertWeight(weightInKg, unit);
    final unitLabel = unit.toLowerCase();

    // Round to 1 decimal place for lbs, whole numbers for kg
    if (unitLabel == 'lbs') {
      return '${convertedWeight.toStringAsFixed(1)}$unitLabel';
    } else {
      // For kg, show decimal only if it's not a whole number
      if (convertedWeight == convertedWeight.round()) {
        return '${convertedWeight.round()}$unitLabel';
      } else {
        return '${convertedWeight.toStringAsFixed(1)}$unitLabel';
      }
    }
  }

  /// Format weight for set display (e.g., "75kg x 8" or "165.3lbs x 8")
  static String formatSetWeight(double weightInKg, String unit, int reps,
      {int? rpe}) {
    final weightStr = formatWeight(weightInKg, unit);
    final rpeStr = rpe != null ? ' @$rpe' : '';
    return '$weightStr x $reps$rpeStr';
  }
}
