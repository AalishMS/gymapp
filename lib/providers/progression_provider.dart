import 'package:flutter/foundation.dart';
import '../models/set.dart' as gym;
import '../models/exercise.dart';
import '../repositories/workout_session_repository.dart';
import '../utils/weight_utils.dart';

class ProgressionProvider with ChangeNotifier {
  final WorkoutSessionRepository _repository = WorkoutSessionRepository();

  String getSuggestion(String exerciseName, int targetReps, String weightUnit) {
    final lastSession = _repository.getLastSessionForExercise(exerciseName);

    if (lastSession == null) {
      return 'No previous data';
    }

    Exercise? lastExercise;
    for (var exercise in lastSession.exercises) {
      if (exercise.name.toLowerCase() == exerciseName.toLowerCase()) {
        lastExercise = exercise;
        break;
      }
    }

    if (lastExercise == null || lastExercise.sets.isEmpty) {
      return 'No previous data';
    }

    // Check if all sets were completed (all have reps > 0)
    bool allSetsCompleted = lastExercise.sets.every((set) => set.reps > 0);

    if (!allSetsCompleted) {
      return 'Last: ${_formatSets(lastExercise.sets, weightUnit)} → Try completing all sets';
    }

    // Get last weight and reps
    double lastWeight = lastExercise.sets.last.weight;
    int lastReps = lastExercise.sets.last.reps;

    // Progression logic
    if (lastReps >= targetReps) {
      // Hit target reps, increase weight
      double newWeight = lastWeight + 2.5;
      return 'Last: ${WeightUtils.formatWeight(lastWeight, weightUnit)} x $lastReps → Suggested: ${WeightUtils.formatWeight(newWeight, weightUnit)} x $targetReps';
    } else {
      // Didn't hit target reps, increase reps
      int newReps = lastReps + 1;
      return 'Last: ${WeightUtils.formatWeight(lastWeight, weightUnit)} x $lastReps → Suggested: ${WeightUtils.formatWeight(lastWeight, weightUnit)} x $newReps';
    }
  }

  String _formatSets(List<gym.Set> sets, String weightUnit) {
    return sets
        .map((s) => WeightUtils.formatSetWeight(s.weight, weightUnit, s.reps))
        .join(', ');
  }
}
