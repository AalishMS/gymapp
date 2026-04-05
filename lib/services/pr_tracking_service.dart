import '../models/exercise.dart';
import '../repositories/stats_repository.dart';

class PRResult {
  final String exerciseName;
  final double previousPR;
  final double newPR;
  final int reps;
  final bool isWeightPR;
  final bool isRepsPR;

  PRResult({
    required this.exerciseName,
    required this.previousPR,
    required this.newPR,
    required this.reps,
    this.isWeightPR = true,
    this.isRepsPR = false,
  });
}

class PRTrackingService {
  static final StatsRepository _statsRepo = StatsRepository();

  static Future<List<PRResult>> checkForNewPRs(List<Exercise> exercises) async {
    final results = <PRResult>[];

    for (var exercise in exercises) {
      if (exercise.sets.isEmpty) continue;

      for (var set in exercise.sets) {
        final currentPR = await _statsRepo.getExercisePR(exercise.name);

        if (set.weight > currentPR) {
          results.add(PRResult(
            exerciseName: exercise.name,
            previousPR: currentPR,
            newPR: set.weight,
            reps: set.reps,
            isWeightPR: true,
          ));
        }
      }
    }

    return results;
  }
}
