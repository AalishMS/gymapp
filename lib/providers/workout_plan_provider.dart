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

  Future<void> addPlan(WorkoutPlan plan) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.addPlan(plan);
      loadPlans();
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updatePlan(int index, WorkoutPlan plan) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.updatePlan(index, plan);
      loadPlans();
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deletePlan(int index) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.deletePlan(index);
      loadPlans();
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }
}
