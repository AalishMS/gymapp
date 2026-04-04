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
}
