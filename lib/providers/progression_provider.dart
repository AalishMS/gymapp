import 'package:flutter/foundation.dart';
import '../models/set.dart' as gym;
import '../models/exercise.dart';
import '../repositories/workout_session_repository.dart';

class ProgressionProvider with ChangeNotifier {
  final WorkoutSessionRepository _repository = WorkoutSessionRepository();

  String getSuggestion(String exerciseName, int targetReps) {
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
      return 'Last: ${_formatSets(lastExercise.sets)} → Try completing all sets';
    }

    // Get last weight and reps
    double lastWeight = lastExercise.sets.last.weight;
    int lastReps = lastExercise.sets.last.reps;

    // Progression logic
    if (lastReps >= targetReps) {
      // Hit target reps, increase weight
      double newWeight = lastWeight + 2.5;
      return 'Last: ${lastWeight}kg x $lastReps → Suggested: ${newWeight}kg x $targetReps';
    } else {
      // Didn't hit target reps, increase reps
      int newReps = lastReps + 1;
      return 'Last: ${lastWeight}kg x $lastReps → Suggested: ${lastWeight}kg x $newReps';
    }
  }

  String _formatSets(List<gym.Set> sets) {
    return sets.map((s) => '${s.weight}kg x ${s.reps}').join(', ');
  }
}
