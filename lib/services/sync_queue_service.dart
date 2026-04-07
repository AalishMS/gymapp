import 'package:hive_flutter/hive_flutter.dart';
import '../models/queued_operation.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';
import 'app_logger.dart';

class SyncQueueService {
  static const String _queueBoxName = 'sync_queue';

  static SyncQueueService? _instance;
  static SyncQueueService get instance {
    _instance ??= SyncQueueService._internal();
    return _instance!;
  }

  SyncQueueService._internal();

  Box<QueuedOperation>? _box;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_queueBoxName)) {
      _box = await Hive.openBox<QueuedOperation>(_queueBoxName);
    } else {
      _box = Hive.box<QueuedOperation>(_queueBoxName);
    }
  }

  Box<QueuedOperation> get _queueBox {
    if (_box == null || !_box!.isOpen) {
      throw Exception('SyncQueueService not initialized. Call init() first.');
    }
    return _box!;
  }

  // Core queue operations
  Future<void> addToQueue(
      String action, String entity, Map<String, dynamic> payload) async {
    final id = '${DateTime.now().millisecondsSinceEpoch}_${entity}_$action';
    final operation = QueuedOperation(
      id: id,
      action: action,
      entity: entity,
      payload: payload,
      timestamp: DateTime.now(),
    );

    await _queueBox.add(operation);
  }

  List<QueuedOperation> getQueue() {
    final operations = _queueBox.values.toList();
    operations.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return operations;
  }

  Future<void> removeFromQueue(String id) async {
    final operations = _queueBox.values.toList();
    for (int i = 0; i < operations.length; i++) {
      if (operations[i].id == id) {
        await _queueBox.deleteAt(i);
        break;
      }
    }
  }

  Future<void> removeQueuedPlanMutations(WorkoutPlan plan) async {
    final keysToDelete = <dynamic>[];

    for (final entry in _queueBox.toMap().entries) {
      final operation = entry.value;
      if (operation.entity != 'plan') {
        continue;
      }

      if (operation.action == 'delete') {
        continue;
      }

      if (_matchesPlanPayload(operation.payload, plan)) {
        keysToDelete.add(entry.key);
      }
    }

    for (final key in keysToDelete) {
      await _queueBox.delete(key);
    }
  }

  Future<void> removeQueuedSessionMutations(WorkoutSession session) async {
    final keysToDelete = <dynamic>[];

    for (final entry in _queueBox.toMap().entries) {
      final operation = entry.value;
      if (operation.entity != 'session') {
        continue;
      }

      if (operation.action == 'delete') {
        continue;
      }

      if (_matchesSessionPayload(operation.payload, session)) {
        keysToDelete.add(entry.key);
      }
    }

    for (final key in keysToDelete) {
      await _queueBox.delete(key);
    }
  }

  Set<String> getPendingDeleteIds(String entity) {
    final pendingDeletes = <String>{};
    for (final operation in _queueBox.values) {
      if (operation.entity != entity || operation.action != 'delete') {
        continue;
      }

      final id = operation.payload['id'];
      if (id is String && id.isNotEmpty) {
        pendingDeletes.add(id);
      }
    }

    return pendingDeletes;
  }

  Future<void> clearQueue() async {
    await _queueBox.clear();
  }

  bool hasItems() {
    return _queueBox.isNotEmpty;
  }

  int get queueLength => _queueBox.length;

  // Debug methods
  void printQueueStatus() {
    final queue = getQueue();
    AppLogger.d('Sync queue status: ${queue.length} operations');
    if (queue.isEmpty) {
      AppLogger.d('Sync queue is empty');
    } else {
      for (int i = 0; i < queue.length; i++) {
        final op = queue[i];
        final timeAgo = DateTime.now().difference(op.timestamp).inMinutes;
        AppLogger.d(
            '${i + 1}. ${op.entity}_${op.action} (${timeAgo}m ago) - ${op.id}');
      }
    }
  }

  Map<String, dynamic> getQueueSummary() {
    final queue = getQueue();
    final summary = <String, int>{};
    for (final op in queue) {
      final key = '${op.entity}_${op.action}';
      summary[key] = (summary[key] ?? 0) + 1;
    }
    return {
      'total': queue.length,
      'operations': summary,
      'oldestTimestamp':
          queue.isNotEmpty ? queue.first.timestamp.toIso8601String() : null,
    };
  }

  // Convenience methods for common operations
  Future<void> addPlanCreate(WorkoutPlan plan) async {
    await addToQueue('create', 'plan', plan.toJson());
  }

  Future<void> addPlanUpdate(WorkoutPlan plan) async {
    await addToQueue('update', 'plan', plan.toJson());
  }

  Future<void> addPlanDelete(String planId) async {
    if (_hasQueuedDelete('plan', planId)) {
      return;
    }
    await addToQueue('delete', 'plan', {'id': planId});
  }

  Future<void> addSessionCreate(WorkoutSession session) async {
    await addToQueue('create', 'session', session.toJson());
  }

  Future<void> addSessionUpdate(WorkoutSession session) async {
    await addToQueue('update', 'session', session.toJson());
  }

  Future<void> addSessionDelete(String sessionId) async {
    if (_hasQueuedDelete('session', sessionId)) {
      return;
    }
    await addToQueue('delete', 'session', {'id': sessionId});
  }

  Future<void> addDataWipeAll() async {
    if (_hasQueuedDataWipeAll()) {
      return;
    }
    await addToQueue('wipe_all', 'data', const {});
  }

  bool _hasQueuedDelete(String entity, String id) {
    return _queueBox.values.any((operation) =>
        operation.entity == entity &&
        operation.action == 'delete' &&
        operation.payload['id'] == id);
  }

  bool _hasQueuedDataWipeAll() {
    return _queueBox.values.any(
      (operation) =>
          operation.entity == 'data' && operation.action == 'wipe_all',
    );
  }

  bool _matchesPlanPayload(Map<String, dynamic> payload, WorkoutPlan plan) {
    final payloadId = payload['id'];
    if (plan.id != null && payloadId == plan.id) {
      return true;
    }

    final payloadName = payload['name'];
    return plan.id == null && payloadName == plan.name;
  }

  bool _matchesSessionPayload(
      Map<String, dynamic> payload, WorkoutSession session) {
    final payloadId = payload['id'];
    if (session.id != null && payloadId == session.id) {
      return true;
    }

    if (session.id != null) {
      return false;
    }

    final payloadPlanName = payload['planName'] ?? payload['plan_name'];
    final payloadWeekNumber = payload['weekNumber'] ?? payload['week_number'];
    final payloadDate = payload['date'];

    if (payloadPlanName != session.planName ||
        payloadWeekNumber != session.weekNumber ||
        payloadDate is! String) {
      return false;
    }

    final parsedDate = DateTime.tryParse(payloadDate);
    return parsedDate != null && parsedDate.isAtSameMomentAs(session.date);
  }
}
