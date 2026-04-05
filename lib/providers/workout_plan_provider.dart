import 'package:flutter/foundation.dart';
import '../models/workout_plan.dart';
import '../repositories/workout_plan_repository.dart';

class WorkoutPlanProvider with ChangeNotifier {
  final WorkoutPlanRepository _repository = WorkoutPlanRepository();
  List<WorkoutPlan> _plans = [];
  String? _error;
  bool _isLoading = false;

  List<WorkoutPlan> get plans => _plans;
  String? get error => _error;
  bool get isLoading => _isLoading;
  WorkoutPlanRepository get repository => _repository;

  WorkoutPlanProvider() {
    loadPlans();
  }

  void loadPlans() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _plans = await _repository.getPlans();
    } catch (e) {
      // The ApiService now provides user-friendly error messages
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addPlan(WorkoutPlan plan) {
    try {
      _error = null;
      _repository.addPlan(plan); // No await - optimistic update
      _plans = _repository.cachedPlans;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  void updatePlan(int index, WorkoutPlan plan) {
    try {
      _error = null;
      _repository.updatePlan(index, plan); // No await - optimistic update
      _plans = _repository.cachedPlans;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  void deletePlan(int index) {
    try {
      _error = null;
      _repository.deletePlan(index); // No await - optimistic update
      _plans = _repository.cachedPlans;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }
}
