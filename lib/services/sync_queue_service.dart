import 'package:hive_flutter/hive_flutter.dart';
import '../models/queued_operation.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';

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

  Future<void> clearQueue() async {
    await _queueBox.clear();
  }

  bool hasItems() {
    return _queueBox.isNotEmpty;
  }

  int get queueLength => _queueBox.length;

  // Convenience methods for common operations
  Future<void> addPlanCreate(WorkoutPlan plan) async {
    await addToQueue('create', 'plan', plan.toJson());
  }

  Future<void> addPlanUpdate(WorkoutPlan plan) async {
    await addToQueue('update', 'plan', plan.toJson());
  }

  Future<void> addPlanDelete(String planId) async {
    await addToQueue('delete', 'plan', {'id': planId});
  }

  Future<void> addSessionCreate(WorkoutSession session) async {
    await addToQueue('create', 'session', session.toJson());
  }

  Future<void> addSessionUpdate(WorkoutSession session) async {
    await addToQueue('update', 'session', session.toJson());
  }

  Future<void> addSessionDelete(String sessionId) async {
    await addToQueue('delete', 'session', {'id': sessionId});
  }
}
