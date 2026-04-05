import 'package:hive_flutter/hive_flutter.dart';

part 'queued_operation.g.dart';

@HiveType(typeId: 5)
class QueuedOperation extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String action;

  @HiveField(2)
  final String entity;

  @HiveField(3)
  final Map<String, dynamic> payload;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  int retryCount;

  QueuedOperation({
    required this.id,
    required this.action,
    required this.entity,
    required this.payload,
    required this.timestamp,
    this.retryCount = 0,
  });

  QueuedOperation copyWith({
    String? id,
    String? action,
    String? entity,
    Map<String, dynamic>? payload,
    DateTime? timestamp,
    int? retryCount,
  }) {
    return QueuedOperation(
      id: id ?? this.id,
      action: action ?? this.action,
      entity: entity ?? this.entity,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  String toString() {
    return 'QueuedOperation(id: $id, action: $action, entity: $entity, timestamp: $timestamp, retryCount: $retryCount)';
  }
}
