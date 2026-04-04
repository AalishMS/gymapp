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
}
