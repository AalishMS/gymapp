import '../services/cache_service.dart';
import '../models/workout_session.dart';

class StatsRepository {
  final CacheService _cacheService = CacheService();

  Future<double> getExercisePR(String exerciseName) async {
    return await _cacheService.getExercisePR(exerciseName);
  }

  Future<List<String>> getAllExerciseNames() async {
    return await _cacheService.getAllExerciseNames();
  }

  Future<Map<String, double>> getAllExercisePRs() async {
    return await _cacheService.getAllExercisePRs();
  }

  Future<List<Map<String, dynamic>>> getExerciseProgression(
      String exerciseName) async {
    return await _cacheService.getExerciseProgression(exerciseName);
  }

  Future<int> getWorkoutsThisWeek() async {
    return await _cacheService.getWorkoutsThisWeek();
  }

  Future<Map<int, int>> getWorkoutFrequency(int weeksBack) async {
    return await _cacheService.getWorkoutFrequency(weeksBack);
  }

  Future<List<WorkoutSession>> getSessionsForPlan(String planName) async {
    return await _cacheService.getSessionsForPlan(planName);
  }
}
