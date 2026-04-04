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
}
