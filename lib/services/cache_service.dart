import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';

class CacheService {
  static const String _plansCacheBox = 'plans_cache';
  static const String _sessionsCacheBox = 'sessions_cache';

  // WorkoutPlan cache operations
  Future<void> savePlans(List<WorkoutPlan> plans) async {
    if (!Hive.isBoxOpen(_plansCacheBox)) {
      await Hive.openBox(_plansCacheBox);
    }
    final box = Hive.box(_plansCacheBox);
    final jsonList = plans.map((plan) => jsonEncode(plan.toJson())).toList();
    await box.put('plans', jsonList);
  }

  Future<List<WorkoutPlan>> getPlans() async {
    if (!Hive.isBoxOpen(_plansCacheBox)) {
      await Hive.openBox(_plansCacheBox);
    }
    final box = Hive.box(_plansCacheBox);
    final jsonList =
        box.get('plans', defaultValue: <dynamic>[]) as List<dynamic>;
    return jsonList
        .map((jsonStr) => WorkoutPlan.fromJson(
            jsonDecode(jsonStr as String) as Map<String, dynamic>))
        .toList();
  }

  // WorkoutSession cache operations
  Future<void> saveSessions(List<WorkoutSession> sessions) async {
    if (!Hive.isBoxOpen(_sessionsCacheBox)) {
      await Hive.openBox(_sessionsCacheBox);
    }
    final box = Hive.box(_sessionsCacheBox);
    final jsonList =
        sessions.map((session) => jsonEncode(session.toJson())).toList();
    await box.put('sessions', jsonList);
  }

  Future<List<WorkoutSession>> getSessions() async {
    if (!Hive.isBoxOpen(_sessionsCacheBox)) {
      await Hive.openBox(_sessionsCacheBox);
    }
    final box = Hive.box(_sessionsCacheBox);
    final jsonList =
        box.get('sessions', defaultValue: <dynamic>[]) as List<dynamic>;
    return jsonList
        .map((jsonStr) => WorkoutSession.fromJson(
            jsonDecode(jsonStr as String) as Map<String, dynamic>))
        .toList();
  }

  // Clear all cache
  Future<void> clearAll() async {
    if (!Hive.isBoxOpen(_plansCacheBox)) {
      await Hive.openBox(_plansCacheBox);
    }
    if (!Hive.isBoxOpen(_sessionsCacheBox)) {
      await Hive.openBox(_sessionsCacheBox);
    }
    final plansBox = Hive.box(_plansCacheBox);
    final sessionsBox = Hive.box(_sessionsCacheBox);
    await plansBox.clear();
    await sessionsBox.clear();
  }

  // Stats methods - moved from HiveService for unified data access
  Future<double> getExercisePR(String exerciseName) async {
    final sessions = await getSessions();
    double maxWeight = 0;
    for (var session in sessions) {
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

  Future<List<String>> getAllExerciseNames() async {
    final sessions = await getSessions();
    final names = <String>{};
    for (var session in sessions) {
      for (var exercise in session.exercises) {
        names.add(exercise.name);
      }
    }
    return names.toList()..sort();
  }

  Future<Map<String, double>> getAllExercisePRs() async {
    final names = await getAllExerciseNames();
    final prs = <String, double>{};
    for (var name in names) {
      prs[name] = await getExercisePR(name);
    }
    return prs;
  }

  Future<List<Map<String, dynamic>>> getExerciseProgression(
      String exerciseName) async {
    final sessions = await getSessions();
    final progression = <Map<String, dynamic>>[];

    for (var session in sessions) {
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

  Future<int> getWorkoutsThisWeek() async {
    final sessions = await getSessions();
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    return sessions.where((s) => s.date.isAfter(startDate)).length;
  }

  Future<Map<int, int>> getWorkoutFrequency(int weeksBack) async {
    final sessions = await getSessions();
    final frequency = <int, int>{};
    final now = DateTime.now();

    for (int i = 0; i < weeksBack; i++) {
      frequency[i] = 0;
    }

    for (var session in sessions) {
      final daysDiff = now.difference(session.date).inDays;
      final weekIndex = daysDiff ~/ 7;
      if (weekIndex < weeksBack) {
        frequency[weekIndex] = (frequency[weekIndex] ?? 0) + 1;
      }
    }

    return frequency;
  }

  Future<List<WorkoutSession>> getSessionsForPlan(String planName) async {
    final sessions = await getSessions();
    return sessions
        .where((s) => s.planName.toLowerCase() == planName.toLowerCase())
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}
