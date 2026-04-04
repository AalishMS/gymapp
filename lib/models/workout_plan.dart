import 'package:hive/hive.dart';
import 'exercise_template.dart';

part 'workout_plan.g.dart';

@HiveType(typeId: 3)
class WorkoutPlan extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<ExerciseTemplate> exercises;

  WorkoutPlan({this.id, required this.name, required this.exercises});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) => WorkoutPlan(
        id: json['id'] as String?,
        name: json['name'] as String,
        exercises: (json['exercises'] as List<dynamic>?)
                ?.map(
                    (e) => ExerciseTemplate.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
