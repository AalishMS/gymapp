import 'package:hive/hive.dart';

part 'exercise_template.g.dart';

@HiveType(typeId: 2)
class ExerciseTemplate extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int sets;

  ExerciseTemplate({
    required this.name,
    required this.sets,
  });
}
