import 'dart:convert';
import '../models/workout_plan.dart';
import '../models/exercise_template.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/cache_service.dart';
import '../services/sync_queue_service.dart';
import '../services/hive_service.dart';

class WorkoutPlanRepository {
  final ApiService _apiService = ApiService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final CacheService _cacheService = CacheService();
  final SyncQueueService _syncQueueService = SyncQueueService.instance;
  List<WorkoutPlan> _cachedPlans = [];

  Future<List<WorkoutPlan>> getPlans() async {
    final isOnline = await _connectivityService.isOnline();

    if (isOnline) {
      final response = await _apiService.get('/plans');
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to load plans: ${response.statusCode} ${response.body}');
      }
      final List<dynamic> data = jsonDecode(response.body);
      _cachedPlans = data.map((json) => _planFromJson(json)).toList();

      // Save to cache
      await _cacheService.savePlans(_cachedPlans);

      return _cachedPlans;
    } else {
      // Return cached plans when offline
      return await _cacheService.getPlans();
    }
  }

  Future<void> addPlan(WorkoutPlan plan) async {
    final isOnline = await _connectivityService.isOnline();

    if (!isOnline) {
      // Queue the operation for later sync
      await _syncQueueService.addPlanCreate(plan);

      // Update local cache immediately for seamless UX
      await HiveService.addPlan(plan);
      _cachedPlans.add(plan);
      await _cacheService.savePlans(_cachedPlans);
      return;
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
    final response = await _apiService.post('/plans', body);
    if (response.statusCode != 201) {
      throw Exception(
          'Failed to add plan: ${response.statusCode} ${response.body}');
    }

    // Refresh cache
    await getPlans();
  }

  Future<void> updatePlan(int index, WorkoutPlan plan) async {
    final isOnline = await _connectivityService.isOnline();

    if (!isOnline) {
      // Queue the operation for later sync
      await _syncQueueService.addPlanUpdate(plan);

      // Update local cache immediately for seamless UX
      await HiveService.updatePlan(index, plan);
      if (index < _cachedPlans.length) {
        _cachedPlans[index] = plan;
        await _cacheService.savePlans(_cachedPlans);
      }
      return;
    }

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

    // Refresh cache
    await getPlans();
  }

  Future<void> deletePlan(int index) async {
    final isOnline = await _connectivityService.isOnline();

    if (index < 0 || index >= _cachedPlans.length) {
      throw Exception('Invalid index');
    }
    final plan = _cachedPlans[index];

    if (!isOnline) {
      // Queue the operation for later sync (only if plan has an ID from server)
      if (plan.id != null) {
        await _syncQueueService.addPlanDelete(plan.id!);
      }

      // Update local cache immediately for seamless UX
      await HiveService.deletePlan(index);
      _cachedPlans.removeAt(index);
      await _cacheService.savePlans(_cachedPlans);
      return;
    }

    if (plan.id == null) {
      throw Exception('Plan ID is required for delete');
    }
    final response = await _apiService.delete('/plans/${plan.id}');
    if (response.statusCode != 204) {
      throw Exception(
          'Failed to delete plan: ${response.statusCode} ${response.body}');
    }

    // Refresh cache
    await getPlans();
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
