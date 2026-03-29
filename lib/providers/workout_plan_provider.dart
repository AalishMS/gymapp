import 'package:flutter/foundation.dart';
import '../models/workout_plan.dart';
import '../services/hive_service.dart';

class WorkoutPlanProvider with ChangeNotifier {
  List<WorkoutPlan> _plans = [];

  List<WorkoutPlan> get plans => _plans;

  WorkoutPlanProvider() {
    loadPlans();
  }

  void loadPlans() {
    _plans = HiveService.getPlans();
    notifyListeners();
  }

  Future<void> addPlan(WorkoutPlan plan) async {
    await HiveService.addPlan(plan);
    loadPlans();
  }

  Future<void> updatePlan(int index, WorkoutPlan plan) async {
    await HiveService.updatePlan(index, plan);
    loadPlans();
  }

  Future<void> deletePlan(int index) async {
    await HiveService.deletePlan(index);
    loadPlans();
  }
}
