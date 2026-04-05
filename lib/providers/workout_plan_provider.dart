import 'package:flutter/foundation.dart';
import '../models/workout_plan.dart';
import '../repositories/workout_plan_repository.dart';

class WorkoutPlanProvider with ChangeNotifier {
  final WorkoutPlanRepository _repository = WorkoutPlanRepository();
  List<WorkoutPlan> _plans = [];
  String? _error;

  List<WorkoutPlan> get plans => _plans;
  String? get error => _error;
  WorkoutPlanRepository get repository => _repository;

  WorkoutPlanProvider() {
    loadPlans();
  }

  void loadPlans() async {
    try {
      _error = null;
      _plans = await _repository.getPlans();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addPlan(WorkoutPlan plan) async {
    try {
      _error = null;
      await _repository.addPlan(plan);
      loadPlans();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updatePlan(int index, WorkoutPlan plan) async {
    try {
      _error = null;
      await _repository.updatePlan(index, plan);
      loadPlans();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deletePlan(int index) async {
    try {
      _error = null;
      await _repository.deletePlan(index);
      loadPlans();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
