import 'package:hive/hive.dart';
import 'exercise.dart';

part 'workout_session.g.dart';

@HiveType(typeId: 4)
class WorkoutSession extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final String planName;

  @HiveField(2)
  final List<Exercise> exercises;

  @HiveField(3)
  final int weekNumber;

  WorkoutSession({
    required this.date,
    required this.planName,
    required this.exercises,
    this.weekNumber = 1,
  });

  WorkoutSession copyWith({
    DateTime? date,
    String? planName,
    List<Exercise>? exercises,
    int? weekNumber,
  }) {
    return WorkoutSession(
      date: date ?? this.date,
      planName: planName ?? this.planName,
      exercises: exercises ?? this.exercises,
      weekNumber: weekNumber ?? this.weekNumber,
    );
  }
}
