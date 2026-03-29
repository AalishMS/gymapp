import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_plan_provider.dart';
import '../models/workout_plan.dart';
import '../models/exercise_template.dart';
import '../data/exercise_library.dart';
import '../services/hive_service.dart';

class EditPlanScreen extends StatefulWidget {
  final WorkoutPlan plan;
  final int planIndex;

  const EditPlanScreen({
    super.key,
    required this.plan,
    required this.planIndex,
  });

  @override
  State<EditPlanScreen> createState() => _EditPlanScreenState();
}

class _EditPlanScreenState extends State<EditPlanScreen> {
  late TextEditingController _nameController;
  late List<ExerciseTemplate> _exercises;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plan.name);

    final plans = HiveService.getPlans();
    final freshPlan =
        plans.length > widget.planIndex ? plans[widget.planIndex] : null;

    _exercises = freshPlan?.exercises
            .map((e) => ExerciseTemplate(name: e.name, sets: e.sets))
            .toList() ??
        [];

    debugPrint('Loaded ${_exercises.length} exercises from plan');
  }

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

                    setState(() {
                      _exercises.add(ExerciseTemplate(
                        name: name.trim(),
                        sets: int.tryParse(setsController.text) ?? 3,
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

    final plan = WorkoutPlan(
      name: _nameController.text.trim(),
      exercises: _exercises,
    );
    context.read<WorkoutPlanProvider>().updatePlan(widget.planIndex, plan);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Workout Plan'),
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
                      itemBuilder: (context, index) {
                        final exercise = _exercises[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('${index + 1}'),
                            ),
                            title: Text(exercise.name),
                            subtitle: Text(
                              '${exercise.sets} sets',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _exercises.removeAt(index);
                                });
                              },
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
