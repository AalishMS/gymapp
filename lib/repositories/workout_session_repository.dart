import '../models/workout_session.dart';
import '../services/hive_service.dart';

class WorkoutSessionRepository {
  List<WorkoutSession> getSessions() {
    return HiveService.getSessions();
  }

  Future<void> addSession(WorkoutSession session) async {
    await HiveService.addSession(session);
  }

  Future<void> deleteSession(int index) async {
    await HiveService.deleteSession(index);
  }

  Future<void> updateSession(int index, WorkoutSession session) async {
    await HiveService.updateSession(index, session);
  }

  List<WorkoutSession> getSessionsForPlan(String planName) {
    return HiveService.getSessionsForPlan(planName);
  }

  List<int> getWeeksForPlan(String planName) {
    return HiveService.getWeeksForPlan(planName);
  }

  WorkoutSession? getSessionForPlanAndWeek(String planName, int weekNumber) {
    return HiveService.getSessionForPlanAndWeek(planName, weekNumber);
  }

  WorkoutSession? getLastSessionForExercise(String exerciseName) {
    return HiveService.getLastSessionForExercise(exerciseName);
  }
}
