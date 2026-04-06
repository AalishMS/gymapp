import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';
import '../models/exercise_template.dart';
import '../models/exercise.dart';
import '../models/set.dart';
import '../models/queued_operation.dart';
import 'app_logger.dart';

class HiveInitResult {
  final bool requiresRecovery;
  final List<String> failedBoxes;
  final bool backupAvailable;
  final String message;

  const HiveInitResult._({
    required this.requiresRecovery,
    required this.failedBoxes,
    required this.backupAvailable,
    required this.message,
  });

  const HiveInitResult.success()
      : this._(
          requiresRecovery: false,
          failedBoxes: const [],
          backupAvailable: false,
          message: 'Local storage initialized',
        );

  const HiveInitResult.recoveryRequired({
    required List<String> failedBoxes,
    required bool backupAvailable,
    required String message,
  }) : this._(
          requiresRecovery: true,
          failedBoxes: failedBoxes,
          backupAvailable: backupAvailable,
          message: message,
        );
}

class _HiveBackupSnapshot {
  final List<String> plansJson;
  final List<String> sessionsJson;
  final List<String>? plansCacheJson;
  final List<String>? sessionsCacheJson;
  final List<String> queueJson;

  const _HiveBackupSnapshot({
    required this.plansJson,
    required this.sessionsJson,
    required this.plansCacheJson,
    required this.sessionsCacheJson,
    required this.queueJson,
  });

  bool get hasAnyData {
    return plansJson.isNotEmpty ||
        sessionsJson.isNotEmpty ||
        (plansCacheJson?.isNotEmpty ?? false) ||
        (sessionsCacheJson?.isNotEmpty ?? false) ||
        queueJson.isNotEmpty;
  }
}

class HiveService {
  static const String plansBox = 'workout_plans';
  static const String sessionsBox = 'workout_sessions';
  static const String plansCacheBox = 'plans_cache';
  static const String sessionsCacheBox = 'sessions_cache';
  static const String syncQueueBox = 'sync_queue';

  static const List<String> _managedBoxes = [
    plansBox,
    sessionsBox,
    plansCacheBox,
    sessionsCacheBox,
    syncQueueBox,
  ];

  static _HiveBackupSnapshot? _lastBackupSnapshot;
  static List<String> _failedBoxes = <String>[];

  static List<String> get failedBoxes => List.unmodifiable(_failedBoxes);

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SetAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ExerciseAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ExerciseTemplateAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(WorkoutPlanAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(WorkoutSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(QueuedOperationAdapter());
    }
  }

  static Future<HiveInitResult> init() async {
    try {
      await Hive.initFlutter();

      _registerAdapters();

      final failed = await _openAllManagedBoxes();
      if (failed.isEmpty) {
        _failedBoxes = <String>[];
        return const HiveInitResult.success();
      }

      _failedBoxes = failed;
      _lastBackupSnapshot = _createBackupSnapshot();

      AppLogger.e('Hive corruption detected in boxes: ${failed.join(', ')}');

      return HiveInitResult.recoveryRequired(
        failedBoxes: failed,
        backupAvailable: _lastBackupSnapshot?.hasAnyData ?? false,
        message:
            'Some local storage files are corrupted. You can recover affected data or reset local storage after confirmation.',
      );
    } catch (e) {
      AppLogger.e('Critical error initializing Hive', error: e);
      rethrow;
    }
  }

  static Future<void> recoverCorruptedBoxes() async {
    if (_failedBoxes.isEmpty) {
      return;
    }

    await _recover(
      targetBoxes: _failedBoxes,
      restoreBackup: false,
    );

    _failedBoxes = <String>[];
  }

  static Future<void> resetDatabase({bool restoreFromBackup = false}) async {
    await _recover(
      targetBoxes: _managedBoxes,
      restoreBackup: restoreFromBackup,
    );

    _failedBoxes = <String>[];
  }

  static Future<void> _recover({
    required List<String> targetBoxes,
    required bool restoreBackup,
  }) async {
    try {
      await Hive.close();
    } catch (e) {
      AppLogger.w('Error closing boxes before recovery', error: e);
    }

    for (final boxName in targetBoxes) {
      try {
        await Hive.deleteBoxFromDisk(boxName);
        AppLogger.i('Deleted Hive box: $boxName');
      } catch (e) {
        AppLogger.w('Could not delete Hive box $boxName', error: e);
      }
    }

    await init();

    if (restoreBackup && _lastBackupSnapshot != null) {
      await _restoreFromBackup(_lastBackupSnapshot!);
    }

    final remainingFailures = await _openAllManagedBoxes();
    if (remainingFailures.isNotEmpty) {
      _failedBoxes = remainingFailures;
      throw Exception(
        'Recovery incomplete. Failed boxes: ${remainingFailures.join(', ')}',
      );
    }
  }

  static Future<List<String>> _openAllManagedBoxes() async {
    final failedBoxes = <String>[];

    for (final boxName in _managedBoxes) {
      try {
        if (Hive.isBoxOpen(boxName)) {
          continue;
        }

        switch (boxName) {
          case plansBox:
            await Hive.openBox<WorkoutPlan>(plansBox);
            break;
          case sessionsBox:
            await Hive.openBox<WorkoutSession>(sessionsBox);
            break;
          case syncQueueBox:
            await Hive.openBox<QueuedOperation>(syncQueueBox);
            break;
          case plansCacheBox:
          case sessionsCacheBox:
            await Hive.openBox(boxName);
            break;
        }
      } catch (e) {
        AppLogger.e('Failed to open Hive box: $boxName', error: e);
        failedBoxes.add(boxName);
      }
    }

    return failedBoxes;
  }

  static _HiveBackupSnapshot _createBackupSnapshot() {
    final plans = Hive.isBoxOpen(plansBox)
        ? Hive.box<WorkoutPlan>(plansBox)
            .values
            .map((plan) => jsonEncode(plan.toJson()))
            .toList()
        : <String>[];

    final sessions = Hive.isBoxOpen(sessionsBox)
        ? Hive.box<WorkoutSession>(sessionsBox)
            .values
            .map((session) => jsonEncode(session.toJson()))
            .toList()
        : <String>[];

    List<String>? plansCache;
    if (Hive.isBoxOpen(plansCacheBox)) {
      final box = Hive.box(plansCacheBox);
      final raw = box.get('plans');
      if (raw is List) {
        plansCache = raw.map((entry) => entry.toString()).toList();
      }
    }

    List<String>? sessionsCache;
    if (Hive.isBoxOpen(sessionsCacheBox)) {
      final box = Hive.box(sessionsCacheBox);
      final raw = box.get('sessions');
      if (raw is List) {
        sessionsCache = raw.map((entry) => entry.toString()).toList();
      }
    }

    final queue = Hive.isBoxOpen(syncQueueBox)
        ? Hive.box<QueuedOperation>(syncQueueBox)
            .values
            .map(
              (operation) => jsonEncode({
                'id': operation.id,
                'action': operation.action,
                'entity': operation.entity,
                'payload': operation.payload,
                'timestamp': operation.timestamp.toIso8601String(),
                'retryCount': operation.retryCount,
              }),
            )
            .toList()
        : <String>[];

    return _HiveBackupSnapshot(
      plansJson: plans,
      sessionsJson: sessions,
      plansCacheJson: plansCache,
      sessionsCacheJson: sessionsCache,
      queueJson: queue,
    );
  }

  static Future<void> _restoreFromBackup(_HiveBackupSnapshot backup) async {
    if (!backup.hasAnyData) {
      return;
    }

    if (Hive.isBoxOpen(plansBox) && backup.plansJson.isNotEmpty) {
      final box = Hive.box<WorkoutPlan>(plansBox);
      await box.clear();
      for (final planJson in backup.plansJson) {
        await box.add(
            WorkoutPlan.fromJson(jsonDecode(planJson) as Map<String, dynamic>));
      }
    }

    if (Hive.isBoxOpen(sessionsBox) && backup.sessionsJson.isNotEmpty) {
      final box = Hive.box<WorkoutSession>(sessionsBox);
      await box.clear();
      for (final sessionJson in backup.sessionsJson) {
        await box.add(WorkoutSession.fromJson(
            jsonDecode(sessionJson) as Map<String, dynamic>));
      }
    }

    if (Hive.isBoxOpen(plansCacheBox) && backup.plansCacheJson != null) {
      await Hive.box(plansCacheBox).put('plans', backup.plansCacheJson);
    }

    if (Hive.isBoxOpen(sessionsCacheBox) && backup.sessionsCacheJson != null) {
      await Hive.box(sessionsCacheBox)
          .put('sessions', backup.sessionsCacheJson);
    }

    if (Hive.isBoxOpen(syncQueueBox) && backup.queueJson.isNotEmpty) {
      final queueBox = Hive.box<QueuedOperation>(syncQueueBox);
      await queueBox.clear();
      for (final opJson in backup.queueJson) {
        final map = jsonDecode(opJson) as Map<String, dynamic>;
        await queueBox.add(
          QueuedOperation(
            id: map['id'] as String,
            action: map['action'] as String,
            entity: map['entity'] as String,
            payload: (map['payload'] as Map).cast<String, dynamic>(),
            timestamp: DateTime.parse(map['timestamp'] as String),
            retryCount: map['retryCount'] as int? ?? 0,
          ),
        );
      }
    }
  }

  // Workout Plan operations
  static Box<WorkoutPlan> get _plansBox => Hive.box<WorkoutPlan>(plansBox);

  static List<WorkoutPlan> getPlans() {
    return _plansBox.values.toList();
  }

  static Future<void> addPlan(WorkoutPlan plan) async {
    await _plansBox.add(plan);
  }

  static Future<void> updatePlan(int index, WorkoutPlan plan) async {
    await _plansBox.putAt(index, plan);
  }

  static Future<void> deletePlan(int index) async {
    await _plansBox.deleteAt(index);
  }

  static Future<void> deletePlanByReference(WorkoutPlan plan,
      {int? fallbackIndex}) async {
    final planIndex = _plansBox.values.toList().indexWhere((storedPlan) {
      if (plan.id != null && storedPlan.id != null) {
        return storedPlan.id == plan.id;
      }

      if (storedPlan.name != plan.name ||
          storedPlan.exercises.length != plan.exercises.length) {
        return false;
      }

      for (int i = 0; i < storedPlan.exercises.length; i++) {
        final storedExercise = storedPlan.exercises[i];
        final targetExercise = plan.exercises[i];
        if (storedExercise.name != targetExercise.name ||
            storedExercise.sets != targetExercise.sets ||
            storedExercise.orderIndex != targetExercise.orderIndex) {
          return false;
        }
      }

      return true;
    });

    if (planIndex != -1) {
      await _plansBox.deleteAt(planIndex);
      return;
    }

    if (fallbackIndex != null &&
        fallbackIndex >= 0 &&
        fallbackIndex < _plansBox.length) {
      await _plansBox.deleteAt(fallbackIndex);
    }
  }

  // Workout Session operations
  static Box<WorkoutSession> get _sessionsBox =>
      Hive.box<WorkoutSession>(sessionsBox);

  static List<WorkoutSession> getSessions() {
    return _sessionsBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> addSession(WorkoutSession session) async {
    await _sessionsBox.add(session);
  }

  static Future<void> deleteSession(int index) async {
    await _sessionsBox.deleteAt(index);
  }

  static Future<void> deleteSessionByReference(WorkoutSession session,
      {int? fallbackIndex}) async {
    final sessionIndex = _sessionsBox.values.toList().indexWhere((stored) {
      if (session.id != null && stored.id != null) {
        return stored.id == session.id;
      }

      return stored.planName.toLowerCase() == session.planName.toLowerCase() &&
          stored.weekNumber == session.weekNumber &&
          stored.date.isAtSameMomentAs(session.date);
    });

    if (sessionIndex != -1) {
      await _sessionsBox.deleteAt(sessionIndex);
      return;
    }

    if (fallbackIndex != null &&
        fallbackIndex >= 0 &&
        fallbackIndex < _sessionsBox.length) {
      await _sessionsBox.deleteAt(fallbackIndex);
    }
  }

  static WorkoutSession? getLastSessionForExercise(String exerciseName) {
    final sessions = getSessions();
    for (var session in sessions) {
      for (var exercise in session.exercises) {
        if (exercise.name.toLowerCase() == exerciseName.toLowerCase()) {
          return session;
        }
      }
    }
    return null;
  }

  static Exercise? getLastExerciseData(String exerciseName) {
    final session = getLastSessionForExercise(exerciseName);
    if (session == null) return null;
    for (var exercise in session.exercises) {
      if (exercise.name.toLowerCase() == exerciseName.toLowerCase()) {
        return exercise;
      }
    }
    return null;
  }

  static List<WorkoutSession> getSessionsForPlan(String planName) {
    return getSessions()
        .where((s) => s.planName.toLowerCase() == planName.toLowerCase())
        .toList();
  }

  static List<int> getWeeksForPlan(String planName) {
    final sessions = getSessionsForPlan(planName);
    final weeks = sessions.map((s) => s.weekNumber).toSet().toList();
    weeks.sort();
    return weeks;
  }

  static WorkoutSession? getSessionForPlanAndWeek(
      String planName, int weekNumber) {
    final sessions = getSessionsForPlan(planName);
    for (var session in sessions) {
      if (session.weekNumber == weekNumber) {
        return session;
      }
    }
    return null;
  }

  static Set? getLastSetForExercise(String exerciseName) {
    final exercise = getLastExerciseData(exerciseName);
    if (exercise == null || exercise.sets.isEmpty) return null;
    return exercise.sets.last;
  }

  static double getExercisePR(String exerciseName) {
    final sessions = getSessions();
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

  static List<String> getAllExerciseNames() {
    final sessions = getSessions();
    final names = <String>{};
    for (var session in sessions) {
      for (var exercise in session.exercises) {
        names.add(exercise.name);
      }
    }
    return names.toList()..sort();
  }

  static Map<String, double> getAllExercisePRs() {
    final names = getAllExerciseNames();
    final prs = <String, double>{};
    for (var name in names) {
      prs[name] = getExercisePR(name);
    }
    return prs;
  }

  static List<Map<String, dynamic>> getExerciseProgression(
      String exerciseName) {
    final sessions = getSessions();
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

  static int getWorkoutsThisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    return getSessions().where((s) => s.date.isAfter(startDate)).length;
  }

  static Map<int, int> getWorkoutFrequency(int weeksBack) {
    final frequency = <int, int>{};
    final now = DateTime.now();

    for (int i = 0; i < weeksBack; i++) {
      frequency[i] = 0;
    }

    for (var session in getSessions()) {
      final daysDiff = now.difference(session.date).inDays;
      final weekIndex = daysDiff ~/ 7;
      if (weekIndex < weeksBack) {
        frequency[weekIndex] = (frequency[weekIndex] ?? 0) + 1;
      }
    }

    return frequency;
  }

  static Future<void> updateSession(int index, WorkoutSession session) async {
    await _sessionsBox.putAt(index, session);
  }

  static Future<void> clearAllPlans() async {
    await _plansBox.clear();
  }

  static Future<void> clearAllSessions() async {
    await _sessionsBox.clear();
  }

  static Future<void> renameSessionWeek(
      String planName, int oldWeek, int newWeek) async {
    final sessions = getSessionsForPlan(planName);
    for (var session in sessions) {
      if (session.weekNumber == oldWeek) {
        final index = _sessionsBox.values.toList().indexOf(session);
        await _sessionsBox.putAt(index, session.copyWith(weekNumber: newWeek));
      }
    }
  }

  static Future<void> deleteSessionForPlanAndWeek(
      String planName, int weekNumber) async {
    final sessions = _sessionsBox.values
        .where((s) =>
            s.planName.toLowerCase() == planName.toLowerCase() &&
            s.weekNumber == weekNumber)
        .toList();
    for (var session in sessions) {
      await session.delete();
    }
  }
}
