import 'dart:async';

import '../models/queued_operation.dart';
import '../services/api_service.dart';
import '../services/sync_queue_service.dart';
import '../services/app_logger.dart';
import '../repositories/workout_plan_repository.dart';
import '../repositories/workout_session_repository.dart';

class SyncService {
  static SyncService? _instance;
  static SyncService get instance {
    _instance ??= SyncService._internal();
    return _instance!;
  }

  SyncService._internal();

  final ApiService _apiService = ApiService();
  final SyncQueueService _syncQueueService = SyncQueueService.instance;

  // Repository instances for refreshing cache after sync
  WorkoutPlanRepository? _planRepository;
  WorkoutSessionRepository? _sessionRepository;

  void setRepositories(
      WorkoutPlanRepository planRepo, WorkoutSessionRepository sessionRepo) {
    _planRepository = planRepo;
    _sessionRepository = sessionRepo;
  }

  Completer<void>? _activeSyncCompleter;
  bool get isSyncing => _activeSyncCompleter != null;

  Future<void> processQueue() async {
    final activeSync = _activeSyncCompleter;
    if (activeSync != null) {
      AppLogger.d('Sync already in progress; waiting for active sync');
      return activeSync.future;
    }

    final completer = Completer<void>();
    _activeSyncCompleter = completer;

    try {
      final queue = _syncQueueService.getQueue();
      AppLogger.i('Starting sync with ${queue.length} queued operations');

      if (queue.isEmpty) {
        AppLogger.d('No queued operations to sync');
        return;
      }

      int successCount = 0;

      for (final operation in queue) {
        try {
          AppLogger.d(
              'Syncing ${operation.entity}_${operation.action} (${operation.id})');
          await _processOperation(operation);
          await _syncQueueService.removeFromQueue(operation.id);
          successCount++;
          AppLogger.d(
              'Synced ${operation.entity}_${operation.action} successfully');
        } catch (e) {
          // Log error but stop processing on first failure to maintain order
          AppLogger.e('Sync failed for operation ${operation.id}', error: e);
          break;
        }
      }

      final remainingCount = queue.length - successCount;
      if (successCount > 0) {
        AppLogger.i(
            'Sync completed: $successCount operations synced, $remainingCount remaining');
        // After successful partial/full sync, refresh repositories
        await _refreshRepositories();
      } else {
        AppLogger.w('No operations were synced successfully');
      }
      if (!completer.isCompleted) {
        completer.complete();
      }
    } catch (e, stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(e, stackTrace);
      }
      rethrow;
    } finally {
      if (identical(_activeSyncCompleter, completer)) {
        _activeSyncCompleter = null;
      }
    }
  }

  Future<void> _processOperation(QueuedOperation operation) async {
    final operationKey =
        '${operation.entity}_${operation.action}'.toUpperCase();

    switch (operationKey) {
      case 'PLAN_CREATE':
        await _processPlanCreate(operation.payload);
        break;
      case 'PLAN_UPDATE':
        await _processPlanUpdate(operation.payload);
        break;
      case 'PLAN_DELETE':
        await _processPlanDelete(operation.payload);
        break;
      case 'SESSION_CREATE':
        await _processSessionCreate(operation.payload);
        break;
      case 'SESSION_UPDATE':
        await _processSessionUpdate(operation.payload);
        break;
      case 'SESSION_DELETE':
        await _processSessionDelete(operation.payload);
        break;
      default:
        throw Exception('Unknown operation: $operationKey');
    }
  }

  Future<void> _processPlanCreate(Map<String, dynamic> payload) async {
    final body = {
      'name': payload['name'],
      'exercises': (payload['exercises'] as List<dynamic>?)
              ?.map((e) => {
                    'name': e['name'],
                    'sets': e['sets'],
                    'order_index': e['orderIndex'] ?? e['order_index'] ?? 0,
                  })
              .toList() ??
          [],
    };

    final response = await _apiService.post('/plans', body);
    if (response.statusCode != 201) {
      throw Exception(
          'Failed to create plan: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> _processPlanUpdate(Map<String, dynamic> payload) async {
    final planId = payload['id'];
    if (planId == null) {
      throw Exception('Plan ID is required for update');
    }

    final body = {
      'name': payload['name'],
      'exercises': (payload['exercises'] as List<dynamic>?)
              ?.map((e) => {
                    'name': e['name'],
                    'sets': e['sets'],
                    'order_index': e['orderIndex'] ?? e['order_index'] ?? 0,
                  })
              .toList() ??
          [],
    };

    final response = await _apiService.put('/plans/$planId', body);
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to update plan: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> _processPlanDelete(Map<String, dynamic> payload) async {
    final planId = payload['id'];
    if (planId == null) {
      throw Exception('Plan ID is required for delete');
    }

    final response = await _apiService.delete('/plans/$planId');
    if (response.statusCode != 204) {
      throw Exception(
          'Failed to delete plan: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> _processSessionCreate(Map<String, dynamic> payload) async {
    final body = {
      'plan_name': payload['planName'] ?? payload['plan_name'],
      'date': payload['date'],
      'week_number': payload['weekNumber'] ?? payload['week_number'],
      'exercises': (payload['exercises'] as List<dynamic>?)
              ?.map((e) => {
                    'name': e['name'],
                    'note': e['note'],
                    'order_index': e['orderIndex'] ?? e['order_index'] ?? 0,
                    'sets': (e['sets'] as List<dynamic>?)
                            ?.map((s) => {
                                  'reps': s['reps'],
                                  'weight': s['weight'],
                                  'rpe': s['rpe'],
                                  'note': s['note'],
                                })
                            .toList() ??
                        [],
                  })
              .toList() ??
          [],
    };

    final response = await _apiService.post('/sessions', body);
    if (response.statusCode != 201) {
      throw Exception(
          'Failed to create session: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> _processSessionUpdate(Map<String, dynamic> payload) async {
    final sessionId = payload['id'];
    if (sessionId == null) {
      throw Exception('Session ID is required for update');
    }

    final body = {
      'plan_name': payload['planName'] ?? payload['plan_name'],
      'date': payload['date'],
      'week_number': payload['weekNumber'] ?? payload['week_number'],
      'exercises': (payload['exercises'] as List<dynamic>?)
              ?.map((e) => {
                    'name': e['name'],
                    'note': e['note'],
                    'order_index': e['orderIndex'] ?? e['order_index'] ?? 0,
                    'sets': (e['sets'] as List<dynamic>?)
                            ?.map((s) => {
                                  'reps': s['reps'],
                                  'weight': s['weight'],
                                  'rpe': s['rpe'],
                                  'note': s['note'],
                                })
                            .toList() ??
                        [],
                  })
              .toList() ??
          [],
    };

    final response = await _apiService.put('/sessions/$sessionId', body);
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to update session: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> _processSessionDelete(Map<String, dynamic> payload) async {
    final sessionId = payload['id'];
    if (sessionId == null) {
      throw Exception('Session ID is required for delete');
    }

    final response = await _apiService.delete('/sessions/$sessionId');
    if (response.statusCode != 204) {
      throw Exception(
          'Failed to delete session: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> _refreshRepositories() async {
    try {
      // Refresh both repositories to sync with the latest API data
      if (_planRepository != null) {
        await _planRepository!.getPlans();
      }
      if (_sessionRepository != null) {
        await _sessionRepository!.getSessionsAsync();
      }
    } catch (e) {
      AppLogger.w('Failed to refresh repositories after sync', error: e);
      // Don't throw here as the sync operations themselves were successful
    }
  }
}
