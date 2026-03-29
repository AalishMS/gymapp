import 'package:hive/hive.dart';
import 'exercise_template.dart';

part 'workout_plan.g.dart';

@HiveType(typeId: 3)
class WorkoutPlan extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final List<ExerciseTemplate> exercises;

  WorkoutPlan({required this.name, required this.exercises});
}
