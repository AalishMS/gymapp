import 'dart:convert';
import '../models/workout_session.dart';
import '../models/exercise.dart';
import '../models/set.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/cache_service.dart';
import '../services/sync_queue_service.dart';
import '../services/hive_service.dart';

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
          _cachedSessions.sort((a, b) => b.date.compareTo(a.date));

          // Save to cache
          await _cacheService.saveSessions(_cachedSessions);

          return _cachedSessions;
        } else {
          // API returned error status, fall back to cache
          print(
              'Sessions API returned ${response.statusCode}, falling back to cache');
          final cached = await _cacheService.getSessions();
          cached.sort((a, b) => b.date.compareTo(a.date));
          return cached;
        }
      } catch (e) {
        // API call failed (network error, timeout, etc.), fall back to cache
        print('Sessions API call failed: $e, falling back to cache');
        final cached = await _cacheService.getSessions();
        cached.sort((a, b) => b.date.compareTo(a.date));
        return cached;
      }
    } else {
      // Return cached sessions when offline
      final cached = await _cacheService.getSessions();
      cached.sort((a, b) => b.date.compareTo(a.date));
      return cached;
    }
  }

  Future<void> addSession(WorkoutSession session) async {
    final isOnline = await _connectivityService.isOnline();

    if (!isOnline) {
      // Queue the operation for later sync
      await _syncQueueService.addSessionCreate(session);

      // Update local cache immediately for seamless UX
      await HiveService.addSession(session);
      _cachedSessions.add(session);
      _cachedSessions.sort((a, b) => b.date.compareTo(a.date));
      await _cacheService.saveSessions(_cachedSessions);
      return;
    }

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
    final response = await _apiService.post('/sessions', body);
    if (response.statusCode != 201) {
      throw Exception(
          'Failed to add session: ${response.statusCode} ${response.body}');
    }

    // Refresh cache
    await getSessionsAsync();
  }

  Future<void> deleteSession(int index) async {
    final isOnline = await _connectivityService.isOnline();

    if (index < 0 || index >= _cachedSessions.length) {
      throw Exception('Invalid index');
    }
    final session = _cachedSessions[index];

    if (!isOnline) {
      // Queue the operation for later sync (only if session has an ID from server)
      if (session.id != null) {
        await _syncQueueService.addSessionDelete(session.id!);
      }

      // Update local cache immediately for seamless UX
      await HiveService.deleteSession(index);
      _cachedSessions.removeAt(index);
      await _cacheService.saveSessions(_cachedSessions);
      return;
    }

    if (session.id == null) {
      throw Exception('Session ID is required for delete');
    }
    final response = await _apiService.delete('/sessions/${session.id}');
    if (response.statusCode != 204) {
      throw Exception(
          'Failed to delete session: ${response.statusCode} ${response.body}');
    }

    // Refresh cache
    await getSessionsAsync();
  }

  Future<void> updateSession(int index, WorkoutSession session) async {
    final isOnline = await _connectivityService.isOnline();

    if (!isOnline) {
      // Queue the operation for later sync
      await _syncQueueService.addSessionUpdate(session);

      // Update local cache immediately for seamless UX
      await HiveService.updateSession(index, session);
      if (index < _cachedSessions.length) {
        _cachedSessions[index] = session;
        _cachedSessions.sort((a, b) => b.date.compareTo(a.date));
        await _cacheService.saveSessions(_cachedSessions);
      }
      return;
    }

    if (session.id == null) {
      throw Exception('Session ID is required for update');
    }
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
    final response = await _apiService.put('/sessions/${session.id}', body);
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to update session: ${response.statusCode} ${response.body}');
    }

    // Refresh cache
    await getSessionsAsync();
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

  Future<void> renameSessionWeek(
      String planName, int oldWeek, int newWeek) async {
    final isOnline = await _connectivityService.isOnline();

    // Find sessions to update
    final sessionsToUpdate = _cachedSessions
        .where((s) =>
            s.planName.toLowerCase() == planName.toLowerCase() &&
            s.weekNumber == oldWeek)
        .toList();

    if (!isOnline) {
      // Queue the operations for later sync
      for (var session in sessionsToUpdate) {
        if (session.id != null) {
          final updatedSession = session.copyWith(weekNumber: newWeek);
          await _syncQueueService.addSessionUpdate(updatedSession);
        }
      }

      // Update local cache immediately for seamless UX
      await HiveService.renameSessionWeek(planName, oldWeek, newWeek);
      // Update the cached sessions
      for (int i = 0; i < _cachedSessions.length; i++) {
        if (_cachedSessions[i].planName.toLowerCase() ==
                planName.toLowerCase() &&
            _cachedSessions[i].weekNumber == oldWeek) {
          _cachedSessions[i] = _cachedSessions[i].copyWith(weekNumber: newWeek);
        }
      }
      await _cacheService.saveSessions(_cachedSessions);
      return;
    }

    // Update each session
    for (var session in sessionsToUpdate) {
      if (session.id != null) {
        final body = {
          'plan_name': session.planName,
          'date': session.date.toIso8601String(),
          'week_number': newWeek,
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
        final response = await _apiService.put('/sessions/${session.id}', body);
        if (response.statusCode != 200) {
          throw Exception(
              'Failed to update session: ${response.statusCode} ${response.body}');
        }
      }
    }

    // Refresh cache
    await getSessionsAsync();
  }

  Future<void> deleteSessionForPlanAndWeek(
      String planName, int weekNumber) async {
    final isOnline = await _connectivityService.isOnline();

    // Find sessions to delete
    final sessionsToDelete = _cachedSessions
        .where((s) =>
            s.planName.toLowerCase() == planName.toLowerCase() &&
            s.weekNumber == weekNumber)
        .toList();

    if (!isOnline) {
      // Queue the operations for later sync (only if sessions have IDs from server)
      for (var session in sessionsToDelete) {
        if (session.id != null) {
          await _syncQueueService.addSessionDelete(session.id!);
        }
      }

      // Update local cache immediately for seamless UX
      await HiveService.deleteSessionForPlanAndWeek(planName, weekNumber);
      _cachedSessions.removeWhere((s) =>
          s.planName.toLowerCase() == planName.toLowerCase() &&
          s.weekNumber == weekNumber);
      await _cacheService.saveSessions(_cachedSessions);
      return;
    }

    // Delete each session
    for (var session in sessionsToDelete) {
      if (session.id != null) {
        final response = await _apiService.delete('/sessions/${session.id}');
        if (response.statusCode != 204) {
          throw Exception(
              'Failed to delete session: ${response.statusCode} ${response.body}');
        }
      }
    }

    // Refresh cache
    await getSessionsAsync();
  }

  int get totalWorkouts => _cachedSessions.length;

  int get workoutsThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return _cachedSessions.where((s) => s.date.isAfter(startDate)).length;
  }

  Map<int, int> getWorkoutFrequency(int weeksBack) {
    final frequency = <int, int>{};
    final now = DateTime.now();
    for (int i = 0; i < weeksBack; i++) {
      frequency[i] = 0;
    }
    for (var session in _cachedSessions) {
      final daysDiff = now.difference(session.date).inDays;
      final weekIndex = daysDiff ~/ 7;
      if (weekIndex < weeksBack) {
        frequency[weekIndex] = (frequency[weekIndex] ?? 0) + 1;
      }
    }
    return frequency;
  }

  List<String> getAllExerciseNames() {
    final names = <String>{};
    for (var session in _cachedSessions) {
      for (var exercise in session.exercises) {
        names.add(exercise.name);
      }
    }
    return names.toList()..sort();
  }

  Map<String, double> getAllExercisePRs() {
    final names = getAllExerciseNames();
    final prs = <String, double>{};
    for (var name in names) {
      prs[name] = getExercisePR(name);
    }
    return prs;
  }

  double getExercisePR(String exerciseName) {
    double maxWeight = 0;
    for (var session in _cachedSessions) {
      for (var exercise in session.exercises) {
        if (exercise.name.toLowerCase() == exerciseName.toLowerCase()) {
          for (var set in exercise.sets) {
            if (set.weight > maxWeight) {
              maxWeight = set.weight;
            }
          }
        }
      }
    }
    return maxWeight;
  }

  List<Map<String, dynamic>> getExerciseProgression(String exerciseName) {
    final List<Map<String, dynamic>> progression = [];
    for (var session in _cachedSessions) {
      for (var exercise in session.exercises) {
        if (exercise.name.toLowerCase() == exerciseName.toLowerCase() &&
            exercise.sets.isNotEmpty) {
          double maxWeight = 0;
          int totalVolume = 0;
          for (var set in exercise.sets) {
            if (set.weight > maxWeight) maxWeight = set.weight;
            totalVolume += (set.weight * set.reps).round();
          }
          progression.add({
            'date': session.date,
            'maxWeight': maxWeight,
            'totalVolume': totalVolume,
            'week': session.weekNumber,
          });
        }
      }
    }
    progression.sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    return progression;
  }

  WorkoutSession _sessionFromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'] as String?,
      planName: json['plan_name'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      weekNumber: json['week_number'] as int? ?? 1,
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => Exercise(
                    id: e['id'] as String?,
                    name: e['name'] as String,
                    note: e['note'] as String?,
                    orderIndex: e['order_index'] as int? ?? 0,
                    sets: (e['sets'] as List<dynamic>?)
                            ?.map((s) => Set(
                                  id: s['id'] as String?,
                                  reps: s['reps'] as int,
                                  weight: (s['weight'] as num).toDouble(),
                                  rpe: s['rpe'] as int?,
                                  note: s['note'] as String?,
                                ))
                            .toList() ??
                        [],
                  ))
              .toList() ??
          [],
    );
  }
}
