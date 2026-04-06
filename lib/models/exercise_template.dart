import 'package:hive/hive.dart';
import 'set.dart' as gym;

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

  @HiveField(4)
  final List<Map<String, dynamic>> setDefaultsJson;

  List<gym.Set> get setDefaults =>
      setDefaultsJson.map(gym.Set.fromJson).toList(growable: false);

  ExerciseTemplate({
    this.id,
    required this.name,
    int? sets,
    List<gym.Set>? setDefaults,
    List<Map<String, dynamic>>? setDefaultsJson,
    this.orderIndex = 0,
  })  : setDefaultsJson =
            _normalizeSetDefaults(sets, setDefaults, setDefaultsJson),
        sets = _resolveSetCount(sets, setDefaults, setDefaultsJson);

  static int _resolveSetCount(int? sets, List<gym.Set>? setDefaults,
      List<Map<String, dynamic>>? setDefaultsJson) {
    if (setDefaults != null) {
      return setDefaults.length;
    }
    if (setDefaultsJson != null) {
      return setDefaultsJson.length;
    }
    return sets ?? 0;
  }

  static List<Map<String, dynamic>> _normalizeSetDefaults(int? sets,
      List<gym.Set>? setDefaults, List<Map<String, dynamic>>? setDefaultsJson) {
    if (setDefaults != null) {
      return List<Map<String, dynamic>>.unmodifiable(
        setDefaults.map((setData) => setData.toJson()),
      );
    }

    if (setDefaultsJson != null) {
      return List<Map<String, dynamic>>.unmodifiable(
          setDefaultsJson.map((setData) => Map<String, dynamic>.from(setData)));
    }

    final count = sets ?? 0;
    return List<Map<String, dynamic>>.unmodifiable(
      List.generate(count, (_) => gym.Set(reps: 8, weight: 0).toJson()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'exercise_name': name,
        'sets': sets,
        'order_index': orderIndex,
        'set_defaults': setDefaultsJson,
      };

  factory ExerciseTemplate.fromJson(Map<String, dynamic> json) =>
      ExerciseTemplate(
        id: json['id'] as String?,
        name: (json['name'] ?? json['exercise_name']) as String,
        sets: json['sets'] as int? ??
            (json['set_defaults'] as List<dynamic>?)?.length ??
            0,
        orderIndex: json['order_index'] as int? ?? 0,
        setDefaults: (json['set_defaults'] as List<dynamic>?)
            ?.map((s) => gym.Set.fromJson((s as Map).cast<String, dynamic>()))
            .toList(),
      );
}
