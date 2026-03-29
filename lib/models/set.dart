import 'package:hive/hive.dart';

part 'set.g.dart';

@HiveType(typeId: 0)
class Set extends HiveObject {
  @HiveField(0)
  final int reps;

  @HiveField(1)
  final double weight;

  @HiveField(2)
  final int? rpe;

  @HiveField(3)
  final String? note;

  Set({required this.reps, required this.weight, this.rpe, this.note});

  Set copyWith({int? reps, double? weight, int? rpe, String? note}) {
    return Set(
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      rpe: rpe ?? this.rpe,
      note: note ?? this.note,
    );
  }
}
