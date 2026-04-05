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

  // Getter for cached plans
  List<WorkoutPlan> get cachedPlans => _cachedPlans;

  Future<List<WorkoutPlan>> getPlans() async {
    final isOnline = await _connectivityService.isOnline();

    if (isOnline) {
      try {
        final response = await _apiService.get('/plans');
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          _cachedPlans = data.map((json) => _planFromJson(json)).toList();

          // Save to cache
          await _cacheService.savePlans(_cachedPlans);

          return _cachedPlans;
        } else {
          // API returned error status, fall back to cache
          print('API returned ${response.statusCode}, falling back to cache');
          _cachedPlans = await _cacheService.getPlans();
          return _cachedPlans;
        }
      } catch (e) {
        // API call failed (network error, timeout, etc.), fall back to cache
        print('API call failed: $e, falling back to cache');
        _cachedPlans = await _cacheService.getPlans();
        return _cachedPlans;
      }
    } else {
      // Return cached plans when offline
      _cachedPlans = await _cacheService.getPlans();
      return _cachedPlans;
    }
  }

  Future<void> addPlan(WorkoutPlan plan) async {
    // 1. Update local cache immediately for instant UI response
    _cachedPlans.add(plan);
    await _cacheService.savePlans(_cachedPlans);

    // 2. Add to local Hive storage for compatibility
    await HiveService.addPlan(plan);

    // 3. Sync to API in background - don't await
    _syncPlanToApi(plan, 'create');
  }

  Future<void> updatePlan(int index, WorkoutPlan plan) async {
    // 1. Update local cache immediately
    if (index >= 0 && index < _cachedPlans.length) {
      _cachedPlans[index] = plan;
      await _cacheService.savePlans(_cachedPlans);
    }

    // 2. Update local Hive storage for compatibility
    await HiveService.updatePlan(index, plan);

    // 3. Sync to API in background - don't await
    _syncPlanToApi(plan, 'update');
  }

  Future<void> deletePlan(int index) async {
    // 1. Update local cache immediately
    if (index >= 0 && index < _cachedPlans.length) {
      _cachedPlans.removeAt(index);
      await _cacheService.savePlans(_cachedPlans);
    }

    // 2. Update local Hive storage for compatibility
    await HiveService.deletePlan(index);

    // 3. Sync to API in background - don't await
    // Note: Delete sync would need plan ID, which we don't have in this structure
    // For now, just handle offline queue if needed
    final isOnline = await _connectivityService.isOnline();
    if (!isOnline) {
      // Queue delete operation if we had plan IDs
      // await _syncQueueService.addPlanDelete(planId);
    }
  }

  Future<void> _syncPlanToApi(WorkoutPlan plan, String operation) async {
    final isOnline = await _connectivityService.isOnline();

    if (!isOnline) {
      // Queue the operation for later sync
      if (operation == 'create') {
        await _syncQueueService.addPlanCreate(plan);
      }
      return;
    }

    try {
      if (operation == 'create') {
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
          print(
              'Failed to sync plan to API: ${response.statusCode} ${response.body}');
          // Could optionally queue for retry here
        }
      }
    } catch (e) {
      print('Error syncing plan to API: $e');
      // Could optionally queue for retry here
    }
  }

  WorkoutPlan _planFromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      id: json['id'],
      name: json['name'],
      exercises: (json['exercises'] as List)
          .map((e) => ExerciseTemplate(
                name: e['name'],
                sets: e['sets'],
                orderIndex: e['order_index'],
              ))
          .toList(),
    );
  }
}
