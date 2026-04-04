import 'dart:convert';
import '../models/workout_plan.dart';
import '../models/exercise_template.dart';
import '../services/api_service.dart';

class WorkoutPlanRepository {
  final ApiService _apiService = ApiService();
  List<WorkoutPlan> _cachedPlans = [];

  Future<List<WorkoutPlan>> getPlans() async {
    final response = await _apiService.get('/plans');
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load plans: ${response.statusCode} ${response.body}');
    }
    final List<dynamic> data = jsonDecode(response.body);
    _cachedPlans = data.map((json) => _planFromJson(json)).toList();
    return _cachedPlans;
  }

  Future<void> addPlan(WorkoutPlan plan) async {
    final body = {
      'name': plan.name,
      'exercises': plan.exercises
          .map((e) => {
                'name': e.name,
                'sets': e.sets,
                'order_index': e.orderIndex,
              })
          .toList(),
    };
    final response = await _apiService.post('/plans', body);
    if (response.statusCode != 201) {
      throw Exception(
          'Failed to add plan: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> updatePlan(int index, WorkoutPlan plan) async {
    if (plan.id == null) {
      throw Exception('Plan ID is required for update');
    }
    final body = {
      'name': plan.name,
      'exercises': plan.exercises
          .map((e) => {
                'name': e.name,
                'sets': e.sets,
                'order_index': e.orderIndex,
              })
          .toList(),
    };
    final response = await _apiService.put('/plans/${plan.id}', body);
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to update plan: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> deletePlan(int index) async {
    if (index < 0 || index >= _cachedPlans.length) {
      throw Exception('Invalid index');
    }
    final plan = _cachedPlans[index];
    if (plan.id == null) {
      throw Exception('Plan ID is required for delete');
    }
    final response = await _apiService.delete('/plans/${plan.id}');
    if (response.statusCode != 204) {
      throw Exception(
          'Failed to delete plan: ${response.statusCode} ${response.body}');
    }
  }

  WorkoutPlan _planFromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      id: json['id'] as String?,
      name: json['name'] as String,
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => ExerciseTemplate(
                    id: e['id'] as String?,
                    name: e['name'] as String,
                    sets: e['sets'] as int,
                    orderIndex: e['order_index'] as int? ?? 0,
                  ))
              .toList() ??
          [],
    );
  }
}
