import 'dart:convert';
import '../models/workout_plan.dart';
import '../models/exercise_template.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/cache_service.dart';
import '../services/sync_queue_service.dart';
import '../services/hive_service.dart';
import '../services/app_logger.dart';

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
          _filterPendingDeletedPlans();

          // Save to cache
          await _cacheService.savePlans(_cachedPlans);

          return _cachedPlans;
        } else {
          // API returned error status, fall back to cache
          AppLogger.w(
              'Plans API returned ${response.statusCode}; using cached data');
          _cachedPlans = await _cacheService.getPlans();
          _filterPendingDeletedPlans();
          return _cachedPlans;
        }
      } catch (e) {
        // API call failed (network error, timeout, etc.), fall back to cache
        AppLogger.w('Plans API request failed; using cached data', error: e);
        _cachedPlans = await _cacheService.getPlans();
        _filterPendingDeletedPlans();
        return _cachedPlans;
      }
    } else {
      // Return cached plans when offline
      _cachedPlans = await _cacheService.getPlans();
      _filterPendingDeletedPlans();
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
    if (index < 0 || index >= _cachedPlans.length) {
      return;
    }

    final planToDelete = _cachedPlans[index];

    // 1. Update local cache immediately
    _cachedPlans.removeAt(index);
    await _cacheService.savePlans(_cachedPlans);

    // 2. Update local Hive storage for compatibility
    await HiveService.deletePlanByReference(planToDelete, fallbackIndex: index);

    // 3. Sync delete to API or queue
    await _syncPlanDeleteToApi(planToDelete);
  }

  Future<void> _syncPlanDeleteToApi(WorkoutPlan plan) async {
    if (plan.id == null || plan.id!.isEmpty) {
      await _syncQueueService.removeQueuedPlanMutations(plan);
      return;
    }

    final isOnline = await _connectivityService.isOnline();
    if (isOnline) {
      try {
        final response = await _apiService.delete('/plans/${plan.id}');
        if (response.statusCode == 204 || response.statusCode == 404) {
          return;
        }
      } catch (e) {
        AppLogger.w('Plan delete API call failed; queuing delete', error: e);
      }
    }

    await _syncQueueService.addPlanDelete(plan.id!);
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
          AppLogger.w(
              'Failed to sync plan create; status=${response.statusCode}');
          // Could optionally queue for retry here
        }
      }
    } catch (e) {
      AppLogger.e('Error syncing plan to API', error: e);
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

  void _filterPendingDeletedPlans() {
    final pendingDeleteIds = _syncQueueService.getPendingDeleteIds('plan');
    if (pendingDeleteIds.isEmpty) {
      return;
    }

    _cachedPlans.removeWhere(
      (plan) => plan.id != null && pendingDeleteIds.contains(plan.id),
    );
  }
}
