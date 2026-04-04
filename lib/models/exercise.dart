import 'package:hive/hive.dart';
import 'set.dart';

part 'exercise.g.dart';

@HiveType(typeId: 1)
class Exercise extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<Set> sets;

  @HiveField(3)
  final String? note;

  @HiveField(4)
  final int orderIndex;

  Exercise(
      {this.id,
      required this.name,
      required this.sets,
      this.note,
      this.orderIndex = 0});

  Exercise copyWith(
      {String? id,
      String? name,
      List<Set>? sets,
      String? note,
      int? orderIndex}) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      note: note ?? this.note,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sets': sets.map((s) => s.toJson()).toList(),
        'note': note,
        'order_index': orderIndex,
      };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String?,
        name: json['name'] as String,
        sets: (json['sets'] as List<dynamic>?)
                ?.map((s) => Set.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        note: json['note'] as String?,
        orderIndex: json['order_index'] as int? ?? 0,
      );
}
