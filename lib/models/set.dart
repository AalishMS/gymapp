import 'package:hive/hive.dart';

part 'set.g.dart';

@HiveType(typeId: 0)
class Set extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final int reps;

  @HiveField(2)
  final double weight;

  @HiveField(3)
  final int? rpe;

  @HiveField(4)
  final String? note;

  Set({this.id, required this.reps, required this.weight, this.rpe, this.note});

  Set copyWith(
      {String? id, int? reps, double? weight, int? rpe, String? note}) {
    return Set(
      id: id ?? this.id,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      rpe: rpe ?? this.rpe,
      note: note ?? this.note,
    );
  }
}
