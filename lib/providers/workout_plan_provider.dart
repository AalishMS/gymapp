import 'package:flutter/foundation.dart';
import '../models/workout_plan.dart';
import '../repositories/workout_plan_repository.dart';

class WorkoutPlanProvider with ChangeNotifier {
  final WorkoutPlanRepository _repository = WorkoutPlanRepository();
  List<WorkoutPlan> _plans = [];

  List<WorkoutPlan> get plans => _plans;

  WorkoutPlanProvider() {
    loadPlans();
  }

  void loadPlans() async {
    _plans = await _repository.getPlans();
    notifyListeners();
  }

  Future<void> addPlan(WorkoutPlan plan) async {
    await _repository.addPlan(plan);
    loadPlans();
  }

  Future<void> updatePlan(int index, WorkoutPlan plan) async {
    await _repository.updatePlan(index, plan);
    loadPlans();
  }

  Future<void> deletePlan(int index) async {
    await _repository.deletePlan(index);
    loadPlans();
  }
}
