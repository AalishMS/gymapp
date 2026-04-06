import 'package:hive/hive.dart';
import 'exercise.dart';

part 'workout_session.g.dart';

@HiveType(typeId: 4)
class WorkoutSession extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String planName;

  @HiveField(3)
  final List<Exercise> exercises;

  @HiveField(4)
  final int weekNumber;

  WorkoutSession({
    this.id,
    required this.date,
    required this.planName,
    required this.exercises,
    this.weekNumber = 1,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'plan_name': planName,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'week_number': weekNumber,
      };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
        id: json['id'] as String?,
        date: DateTime.parse(json['date'] as String),
        planName: json['plan_name'] as String? ?? '',
        exercises: (json['exercises'] as List<dynamic>?)
                ?.map((e) => Exercise.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        weekNumber: json['week_number'] as int? ?? 1,
      );

  WorkoutSession copyWith({
    String? id,
    DateTime? date,
    String? planName,
    List<Exercise>? exercises,
    int? weekNumber,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      date: date ?? this.date,
      planName: planName ?? this.planName,
      exercises: exercises ?? this.exercises,
      weekNumber: weekNumber ?? this.weekNumber,
    );
  }
}
