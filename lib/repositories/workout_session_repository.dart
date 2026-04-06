import 'dart:convert';
import '../models/workout_session.dart';
import '../models/exercise.dart';
import '../models/set.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/cache_service.dart';
import '../services/sync_queue_service.dart';
import '../services/hive_service.dart';
import '../services/app_logger.dart';

class WorkoutSessionRepository {
  final ApiService _apiService = ApiService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final CacheService _cacheService = CacheService();
  final SyncQueueService _syncQueueService = SyncQueueService.instance;
  List<WorkoutSession> _cachedSessions = [];

  List<WorkoutSession> get cachedSessions => _cachedSessions;

  List<WorkoutSession> getSessions() {
    return _cachedSessions;
  }

  Future<List<WorkoutSession>> getSessionsAsync() async {
    final isOnline = await _connectivityService.isOnline();

    if (isOnline) {
      try {
        final response = await _apiService.get('/sessions');
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          _cachedSessions = data.map((json) => _sessionFromJson(json)).toList();
          _filterPendingDeletedSessions();
          _cachedSessions.sort((a, b) => b.date.compareTo(a.date));

          // Save to cache
          await _cacheService.saveSessions(_cachedSessions);

          return _cachedSessions;
        } else {
          // API returned error status, fall back to cache
          AppLogger.w(
              'Sessions API returned ${response.statusCode}; using cached data');
          _cachedSessions = await _cacheService.getSessions();
          _filterPendingDeletedSessions();
          _cachedSessions.sort((a, b) => b.date.compareTo(a.date));
          return _cachedSessions;
        }
      } catch (e) {
        // API call failed (network error, timeout, etc.), fall back to cache
        AppLogger.w('Sessions API request failed; using cached data', error: e);
        _cachedSessions = await _cacheService.getSessions();
        _filterPendingDeletedSessions();
        _cachedSessions.sort((a, b) => b.date.compareTo(a.date));
        return _cachedSessions;
      }
    } else {
      // Return cached sessions when offline
      _cachedSessions = await _cacheService.getSessions();
      _filterPendingDeletedSessions();
      _cachedSessions.sort((a, b) => b.date.compareTo(a.date));
      return _cachedSessions;
    }
  }

  Future<void> addSession(WorkoutSession session) async {
    // 1. Update local cache immediately for instant UI response
    _cachedSessions.add(session);
    _cachedSessions.sort((a, b) => b.date.compareTo(a.date));
    await _cacheService.saveSessions(_cachedSessions);

    // 2. Add to local Hive storage for compatibility
    await HiveService.addSession(session);

    // 3. Sync to API in background - don't await
    _syncSessionToApi(session, 'create');
  }

  Future<void> updateSession(int index, WorkoutSession session) async {
    // 1. Update local cache immediately
    if (index >= 0 && index < _cachedSessions.length) {
      _cachedSessions[index] = session;
      _cachedSessions.sort((a, b) => b.date.compareTo(a.date));
      await _cacheService.saveSessions(_cachedSessions);
    }

    // 2. Update local Hive storage for compatibility
    await HiveService.updateSession(index, session);

    // 3. Sync to API in background - don't await
    _syncSessionToApi(session, 'update');
  }

  Future<void> deleteSession(int index) async {
    if (index < 0 || index >= _cachedSessions.length) {
      return;
    }

    final sessionToDelete = _cachedSessions[index];

    // 1. Update local cache immediately
    _cachedSessions.removeAt(index);
    await _cacheService.saveSessions(_cachedSessions);

    // 2. Update local Hive storage for compatibility
    await HiveService.deleteSessionByReference(sessionToDelete,
        fallbackIndex: index);

    // 3. Sync delete to API or queue
    await _syncSessionDeleteToApi(sessionToDelete);
  }

  Future<void> _syncSessionDeleteToApi(WorkoutSession session) async {
    if (session.id == null || session.id!.isEmpty) {
      await _syncQueueService.removeQueuedSessionMutations(session);
      return;
    }

    final isOnline = await _connectivityService.isOnline();
    if (isOnline) {
      try {
        final response = await _apiService.delete('/sessions/${session.id}');
        if (response.statusCode == 204 || response.statusCode == 404) {
          return;
        }
      } catch (e) {
        AppLogger.w('Session delete API call failed; queuing delete', error: e);
      }
    }

    await _syncQueueService.addSessionDelete(session.id!);
  }

  Future<void> _syncSessionToApi(
      WorkoutSession session, String operation) async {
    final isOnline = await _connectivityService.isOnline();

    if (!isOnline) {
      // Queue the operation for later sync
      if (operation == 'create') {
        await _syncQueueService.addSessionCreate(session);
      } else if (operation == 'update') {
        await _syncQueueService.addSessionUpdate(session);
      }
      return;
    }

    try {
      final body = {
        'plan_name': session.planName,
        'date': session.date.toIso8601String(),
        'week_number': session.weekNumber,
        'exercises': session.exercises
            .map((e) => {
                  'name': e.name,
                  'note': e.note,
                  'order_index': e.orderIndex,
                  'sets': e.sets
                      .map((s) => {
                            'reps': s.reps,
                            'weight': s.weight,
                            'rpe': s.rpe,
                            'note': s.note,
                          })
                      .toList(),
                })
            .toList(),
      };

      if (operation == 'create') {
        final response = await _apiService.post('/sessions', body);
        if (response.statusCode != 201) {
          AppLogger.w(
              'Failed to sync session create; status=${response.statusCode}');
        }
      } else if (operation == 'update' && session.id != null) {
        final response = await _apiService.put('/sessions/${session.id}', body);
        if (response.statusCode != 200) {
          AppLogger.w(
              'Failed to sync session update; status=${response.statusCode}');
        }
      }
    } catch (e) {
      AppLogger.e('Error syncing session to API', error: e);
    }
  }

  List<WorkoutSession> getSessionsForPlan(String planName) {
    return _cachedSessions
        .where((s) => s.planName.toLowerCase() == planName.toLowerCase())
        .toList();
  }

  List<int> getWeeksForPlan(String planName) {
    final sessions = getSessionsForPlan(planName);
    final weeks = sessions.map((s) => s.weekNumber).toSet().toList();
    weeks.sort();
    return weeks;
  }

  WorkoutSession? getSessionForPlanAndWeek(String planName, int weekNumber) {
    final sessions = getSessionsForPlan(planName);
    for (var session in sessions) {
      if (session.weekNumber == weekNumber) {
        return session;
      }
    }
    return null;
  }

  WorkoutSession? getLastSessionForExercise(String exerciseName) {
    for (var session in _cachedSessions) {
      for (var exercise in session.exercises) {
        if (exercise.name.toLowerCase() == exerciseName.toLowerCase()) {
          return session;
        }
      }
    }
    return null;
  }

  Set? getLastSetForExercise(String exerciseName) {
    for (var session in _cachedSessions) {
      for (var exercise in session.exercises) {
        if (exercise.name.toLowerCase() == exerciseName.toLowerCase() &&
            exercise.sets.isNotEmpty) {
          return exercise.sets.last;
        }
      }
    }
    return null;
  }

  int get workoutsThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    return _cachedSessions.where((s) => s.date.isAfter(startDate)).length;
  }

  Future<void> renameSessionWeek(
      String planName, int oldWeek, int newWeek) async {
    // 1. Update local cache immediately
    for (int i = 0; i < _cachedSessions.length; i++) {
      if (_cachedSessions[i].planName.toLowerCase() == planName.toLowerCase() &&
          _cachedSessions[i].weekNumber == oldWeek) {
        _cachedSessions[i] = _cachedSessions[i].copyWith(weekNumber: newWeek);
      }
    }
    await _cacheService.saveSessions(_cachedSessions);

    // 2. Update local Hive storage for compatibility
    await HiveService.renameSessionWeek(planName, oldWeek, newWeek);

    // 3. Sync to API in background - don't await
    // Find sessions to update and sync each one
    final sessionsToUpdate = _cachedSessions
        .where((s) =>
            s.planName.toLowerCase() == planName.toLowerCase() &&
            s.weekNumber == newWeek) // Now they have the new week number
        .toList();

    for (var session in sessionsToUpdate) {
      _syncSessionToApi(session, 'update');
    }
  }

  Future<void> deleteSessionForPlanAndWeek(
      String planName, int weekNumber) async {
    final sessionsToDelete = _cachedSessions
        .where((s) =>
            s.planName.toLowerCase() == planName.toLowerCase() &&
            s.weekNumber == weekNumber)
        .toList();

    // 1. Update local cache immediately
    _cachedSessions.removeWhere((s) =>
        s.planName.toLowerCase() == planName.toLowerCase() &&
        s.weekNumber == weekNumber);
    await _cacheService.saveSessions(_cachedSessions);

    // 2. Update local Hive storage for compatibility
    await HiveService.deleteSessionForPlanAndWeek(planName, weekNumber);

    // 3. Sync to API in background - don't await
    for (final session in sessionsToDelete) {
      await _syncSessionDeleteToApi(session);
    }
  }

  WorkoutSession _sessionFromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'],
      planName: json['plan_name'],
      date: DateTime.parse(json['date']),
      weekNumber: json['week_number'],
      exercises: (json['exercises'] as List)
          .map((e) => Exercise(
                name: e['name'],
                note: e['note'] ?? '',
                orderIndex: e['order_index'] ?? 0,
                sets: (e['sets'] as List)
                    .map((s) => Set(
                          reps: s['reps'],
                          weight: s['weight'].toDouble(),
                          rpe: s['rpe'],
                          note: s['note'] ?? '',
                        ))
                    .toList(),
              ))
          .toList(),
    );
  }

  void _filterPendingDeletedSessions() {
    final pendingDeleteIds = _syncQueueService.getPendingDeleteIds('session');
    if (pendingDeleteIds.isEmpty) {
      return;
    }

    _cachedSessions.removeWhere(
      (session) => session.id != null && pendingDeleteIds.contains(session.id),
    );
  }
}
