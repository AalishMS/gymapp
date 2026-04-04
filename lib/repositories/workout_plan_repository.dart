import '../models/workout_plan.dart';
import '../services/hive_service.dart';

class WorkoutPlanRepository {
  List<WorkoutPlan> getPlans() {
    return HiveService.getPlans();
  }

  Future<void> addPlan(WorkoutPlan plan) async {
    await HiveService.addPlan(plan);
  }

  Future<void> updatePlan(int index, WorkoutPlan plan) async {
    await HiveService.updatePlan(index, plan);
  }

  Future<void> deletePlan(int index) async {
    await HiveService.deletePlan(index);
  }
}
