import '../services/hive_service.dart';

class StatsRepository {
  double getExercisePR(String exerciseName) {
    return HiveService.getExercisePR(exerciseName);
  }

  List<String> getAllExerciseNames() {
    return HiveService.getAllExerciseNames();
  }

  Map<String, double> getAllExercisePRs() {
    return HiveService.getAllExercisePRs();
  }

  List<Map<String, dynamic>> getExerciseProgression(String exerciseName) {
    return HiveService.getExerciseProgression(exerciseName);
  }

  int getWorkoutsThisWeek() {
    return HiveService.getWorkoutsThisWeek();
  }

  Map<int, int> getWorkoutFrequency(int weeksBack) {
    return HiveService.getWorkoutFrequency(weeksBack);
  }
}
