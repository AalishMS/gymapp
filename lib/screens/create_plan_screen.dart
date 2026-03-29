import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_plan_provider.dart';
import '../models/workout_plan.dart';
import '../models/exercise_template.dart';
import '../data/exercise_library.dart';

class _ExerciseSetData {
  final int reps;
  final double weight;

  _ExerciseSetData({required this.reps, required this.weight});

  _ExerciseSetData copyWith({int? reps, double? weight}) {
    return _ExerciseSetData(
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
    );
  }
}

class _ExerciseWithSets {
  final String name;
  final List<_ExerciseSetData> sets;

  _ExerciseWithSets({required this.name, required this.sets});

  _ExerciseWithSets copyWith({String? name, List<_ExerciseSetData>? sets}) {
    return _ExerciseWithSets(
      name: name ?? this.name,
      sets: sets ?? this.sets,
    );
  }
}

class CreatePlanScreen extends StatefulWidget {
  const CreatePlanScreen({super.key});

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final _nameController = TextEditingController();
  final List<_ExerciseWithSets> _exercises = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addExercise() {
    final setsController = TextEditingController(text: '3');
    String? selectedCategory;
    String? selectedExercise;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Exercise'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Category',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      hint: const Text('Choose category'),
                      items: ExerciseLibrary.categoryNames.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCategory = value;
                          selectedExercise = null;
                        });
                      },
                    ),
                    if (selectedCategory != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Select Exercise',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedExercise,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        hint: const Text('Choose exercise'),
                        items: ExerciseLibrary
                            .exercisesByCategory[selectedCategory]!
                            .map((exercise) {
                          return DropdownMenuItem(
                            value: exercise,
                            child: Text(exercise),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedExercise = value;
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'Or enter custom exercise',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Custom Exercise Name',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          setDialogState(() {
                            selectedExercise = value;
                            selectedCategory = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: setsController,
                      decoration: const InputDecoration(
                        labelText: 'Sets',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = selectedExercise;
                    if (name == null || name.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Please select or enter an exercise')),
                      );
                      return;
                    }

                    final numSets = int.tryParse(setsController.text) ?? 3;
                    final sets = List.generate(
                      numSets,
                      (i) => _ExerciseSetData(reps: 8, weight: 0),
                    );

                    setState(() {
                      _exercises.add(_ExerciseWithSets(
                        name: name.trim(),
                        sets: sets,
                      ));
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _duplicateSet(int exerciseIndex, int setIndex) {
    setState(() {
      final exercise = _exercises[exerciseIndex];
      final setToCopy = exercise.sets[setIndex];
      final newSets = List<_ExerciseSetData>.from(exercise.sets);
      newSets.insert(setIndex + 1, setToCopy.copyWith());
      _exercises[exerciseIndex] = exercise.copyWith(sets: newSets);
    });
  }

  void _updateSet(int exerciseIndex, int setIndex, int reps, double weight) {
    setState(() {
      final exercise = _exercises[exerciseIndex];
      final newSets = List<_ExerciseSetData>.from(exercise.sets);
      newSets[setIndex] = _ExerciseSetData(reps: reps, weight: weight);
      _exercises[exerciseIndex] = exercise.copyWith(sets: newSets);
    });
  }

  void _deleteSet(int exerciseIndex, int setIndex) {
    setState(() {
      final exercise = _exercises[exerciseIndex];
      if (exercise.sets.length <= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot delete the last set')),
        );
        return;
      }
      final newSets = List<_ExerciseSetData>.from(exercise.sets);
      newSets.removeAt(setIndex);
      _exercises[exerciseIndex] = exercise.copyWith(sets: newSets);
    });
  }

  void _savePlan() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan name cannot be empty')),
      );
      return;
    }

    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one exercise')),
      );
      return;
    }

    final exercises = _exercises
        .map((e) => ExerciseTemplate(
              name: e.name,
              sets: e.sets.length,
            ))
        .toList();

    final plan = WorkoutPlan(
      name: _nameController.text.trim(),
      exercises: exercises,
    );
    context.read<WorkoutPlanProvider>().addPlan(plan);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Workout Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePlan,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Plan Name',
                hintText: 'e.g., Push Day',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Tap + to add exercises',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _exercises.isEmpty
                  ? const Center(
                      child: Text(
                        'No exercises added yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _exercises.length,
                      itemBuilder: (context, exerciseIndex) {
                        final exercise = _exercises[exerciseIndex];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      child: Text('${exerciseIndex + 1}'),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        exercise.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${exercise.sets.length} sets',
                                      style:
                                          const TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _exercises.removeAt(exerciseIndex);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const Divider(),
                                ...exercise.sets.asMap().entries.map((entry) {
                                  final setIndex = entry.key;
                                  final set = entry.value;
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 60,
                                          child: Text(
                                            'Set ${setIndex + 1}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: TextFormField(
                                                  initialValue:
                                                      set.reps.toString(),
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText: 'Reps',
                                                    isDense: true,
                                                    border:
                                                        OutlineInputBorder(),
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 8,
                                                    ),
                                                  ),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  onChanged: (value) {
                                                    final reps =
                                                        int.tryParse(value) ??
                                                            8;
                                                    _updateSet(
                                                        exerciseIndex,
                                                        setIndex,
                                                        reps,
                                                        set.weight);
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: TextFormField(
                                                  initialValue:
                                                      set.weight.toString(),
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText: 'kg',
                                                    isDense: true,
                                                    border:
                                                        OutlineInputBorder(),
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 8,
                                                    ),
                                                  ),
                                                  keyboardType: TextInputType
                                                      .numberWithOptions(
                                                          decimal: true),
                                                  onChanged: (value) {
                                                    final weight =
                                                        double.tryParse(
                                                                value) ??
                                                            0.0;
                                                    _updateSet(
                                                        exerciseIndex,
                                                        setIndex,
                                                        set.reps,
                                                        weight);
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon:
                                              const Icon(Icons.copy, size: 20),
                                          onPressed: () => _duplicateSet(
                                              exerciseIndex, setIndex),
                                          tooltip: 'Duplicate set',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              size: 20, color: Colors.red),
                                          onPressed: () => _deleteSet(
                                              exerciseIndex, setIndex),
                                          tooltip: 'Delete set',
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExercise,
        child: const Icon(Icons.add),
      ),
    );
  }
}
