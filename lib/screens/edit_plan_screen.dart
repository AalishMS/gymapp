import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/workout_plan_provider.dart';
import '../providers/settings_provider.dart';
import '../models/workout_plan.dart';
import '../models/exercise_template.dart';
import '../data/exercise_library.dart';
import '../services/hive_service.dart';
import '../theme/app_theme.dart';

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addExercise() {
    final accent = context.read<SettingsProvider>().accentColor;
    final setsController = TextEditingController(text: '3');
    String? selectedCategory;
    String? selectedExercise;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: surfaceColor(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: borderColor(context), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '> ADD EXERCISE',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'SELECT CATEGORY',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 10, color: textSecondaryColor(context)),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      hint: Text('Choose category',
                          style: GoogleFonts.jetBrainsMono(fontSize: 12)),
                      items: ExerciseLibrary.categoryNames.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category,
                              style: GoogleFonts.jetBrainsMono(fontSize: 12)),
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
                      Text(
                        'SELECT EXERCISE',
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 10, color: textSecondaryColor(context)),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedExercise,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        hint: Text('Choose exercise',
                            style: GoogleFonts.jetBrainsMono(fontSize: 12)),
                        items: ExerciseLibrary
                            .exercisesByCategory[selectedCategory]!
                            .map((exercise) {
                          return DropdownMenuItem(
                            value: exercise,
                            child: Text(exercise,
                                style: GoogleFonts.jetBrainsMono(fontSize: 12)),
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
                    Text(
                      'OR ENTER CUSTOM EXERCISE',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 10, color: textSecondaryColor(context)),
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
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('[CANCEL]',
                              style: GoogleFonts.jetBrainsMono(
                                  color: textSecondaryColor(context))),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final name = selectedExercise;
                            if (name == null || name.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '> Please select or enter an exercise',
                                      style: GoogleFonts.jetBrainsMono()),
                                  backgroundColor: errorColor(context),
                                ),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.black,
                          ),
                          child: Text('[ ADD ]',
                              style: GoogleFonts.jetBrainsMono()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _savePlan() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('> Plan name cannot be empty',
              style: GoogleFonts.jetBrainsMono()),
          backgroundColor: errorColor(context),
        ),
      );
      return;
    }

    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('> Add at least one exercise',
              style: GoogleFonts.jetBrainsMono()),
          backgroundColor: errorColor(context),
        ),
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
    final accent = context.watch<SettingsProvider>().accentColor;

    return Scaffold(
      backgroundColor: backgroundColor(context),
      appBar: AppBar(
        backgroundColor: surfaceColor(context),
        title: Text(
          '> EDIT PLAN',
          style: GoogleFonts.jetBrainsMono(
              fontSize: 16, fontWeight: FontWeight.bold, color: accent),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: accent),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          InkWell(
            onTap: _savePlan,
            splashColor: accent.withValues(alpha: 0.2),
            highlightColor: accent.withValues(alpha: 0.1),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Text('[ SAVE ]',
                  style: GoogleFonts.jetBrainsMono(color: accent)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Plan Name',
                hintText: 'e.g., PUSH DAY',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor(context)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: textSecondaryColor(context)),
                  const SizedBox(width: 8),
                  Text(
                    'Tap [+ ADD EXERCISE] below to add exercises',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 12, color: textSecondaryColor(context)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: borderColor(context)),
            Expanded(
              child: _exercises.isEmpty
                  ? Center(
                      child: Text(
                        '> No exercises added yet',
                        style: GoogleFonts.jetBrainsMono(
                            color: textSecondaryColor(context)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = _exercises[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: surfaceColor(context),
                            border: Border.all(
                                color: borderColor(context), width: 1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: accent),
                                  ),
                                  child: Text(
                                    '[${index + 1}]',
                                    style: GoogleFonts.jetBrainsMono(
                                        fontSize: 12, color: accent),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        exercise.name.toUpperCase(),
                                        style: GoogleFonts.jetBrainsMono(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${exercise.sets} SETS',
                                        style: GoogleFonts.jetBrainsMono(
                                            fontSize: 10,
                                            color: textSecondaryColor(context)),
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _exercises.removeAt(index);
                                    });
                                  },
                                  splashColor: errorColor(context)
                                      .withValues(alpha: 0.2),
                                  highlightColor: errorColor(context)
                                      .withValues(alpha: 0.1),
                                  child: Text('[DEL]',
                                      style: GoogleFonts.jetBrainsMono(
                                          fontSize: 12,
                                          color: errorColor(context))),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _addExercise,
              splashColor: accent.withValues(alpha: 0.2),
              highlightColor: accent.withValues(alpha: 0.1),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: accent, width: 1),
                ),
                child: Center(
                  child: Text(
                    '[ + ADD EXERCISE ]',
                    style: GoogleFonts.jetBrainsMono(color: accent),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savePlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                ),
                child: Text('[ SAVE PLAN ]',
                    style:
                        GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
