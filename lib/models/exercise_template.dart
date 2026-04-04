import 'package:hive/hive.dart';

part 'exercise_template.g.dart';

@HiveType(typeId: 2)
class ExerciseTemplate extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int sets;

  @HiveField(3)
  final int orderIndex;

  ExerciseTemplate(
      {this.id, required this.name, required this.sets, this.orderIndex = 0});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sets': sets,
        'order_index': orderIndex,
      };

  factory ExerciseTemplate.fromJson(Map<String, dynamic> json) =>
      ExerciseTemplate(
        id: json['id'] as String?,
        name: json['name'] as String,
        sets: json['sets'] as int,
        orderIndex: json['order_index'] as int? ?? 0,
      );
}
