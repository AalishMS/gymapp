import 'dart:convert';
import '../models/workout_session.dart';
import '../models/exercise.dart';
import '../models/set.dart';
import '../services/api_service.dart';

class WorkoutSessionRepository {
  final ApiService _apiService = ApiService();
  List<WorkoutSession> _cachedSessions = [];

  List<WorkoutSession> get cachedSessions => _cachedSessions;

  List<WorkoutSession> getSessions() {
    return _cachedSessions;
  }

  Future<List<WorkoutSession>> getSessionsAsync() async {
    final response = await _apiService.get('/sessions');
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load sessions: ${response.statusCode} ${response.body}');
    }
    final List<dynamic> data = jsonDecode(response.body);
    _cachedSessions = data.map((json) => _sessionFromJson(json)).toList();
    _cachedSessions.sort((a, b) => b.date.compareTo(a.date));
    return _cachedSessions;
  }

  Future<void> addSession(WorkoutSession session) async {
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
  }

  Future<void> deleteSession(int index) async {
    if (index < 0 || index >= _cachedSessions.length) {
      throw Exception('Invalid index');
    }
    final session = _cachedSessions[index];
    if (session.id == null) {
      throw Exception('Session ID is required for delete');
    }
    final response = await _apiService.delete('/sessions/${session.id}');
    if (response.statusCode != 204) {
      throw Exception(
          'Failed to delete session: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> updateSession(int index, WorkoutSession session) async {
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
