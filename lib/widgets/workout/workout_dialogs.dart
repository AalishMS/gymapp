import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/exercise_library.dart';
import '../../models/set.dart' as gym;
import '../../providers/settings_provider.dart';
import '../../services/pr_tracking_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/weight_utils.dart';

class _ExerciseSetInput {
  final TextEditingController repsController;
  final TextEditingController weightController;
  int? selectedRpe;

  _ExerciseSetInput({int reps = 8, double weight = 0})
      : repsController = TextEditingController(text: reps.toString()),
        weightController = TextEditingController(text: weight.toString());

  void dispose() {
    repsController.dispose();
    weightController.dispose();
  }
}

class WorkoutDialogs {
  static void showPRDialog(BuildContext context, List<PRResult> prs) {
    final settings = context.read<SettingsProvider>();
    final accent = accentColor(context);
    final onAccent = Theme.of(context).colorScheme.onPrimary;
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                '> NEW PR DETECTED!',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
              const SizedBox(height: 16),
              ...prs.map((pr) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pr.exerciseName,
                            style: GoogleFonts.jetBrainsMono(
                                fontWeight: FontWeight.bold)),
                        Text(
                          '${WeightUtils.formatWeight(pr.newPR, settings.weightUnit)} (Previous: ${WeightUtils.formatWeight(pr.previousPR, settings.weightUnit)})',
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 12, color: textSecondaryColor(context)),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: onAccent,
                  ),
                  child: Text('[ ACKNOWLEDGE ]',
                      style: GoogleFonts.jetBrainsMono()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showAddExerciseDialog(
    BuildContext context, {
    required void Function(String name, List<gym.Set> sets) onAdd,
  }) {
    final accent = accentColor(context);
    final onAccent = Theme.of(context).colorScheme.onPrimary;
    final setsController = TextEditingController(text: '3');
    final allSetInputs = <_ExerciseSetInput>[];

    _ExerciseSetInput createSetInput() {
      final input = _ExerciseSetInput();
      allSetInputs.add(input);
      return input;
    }

    String? selectedCategory;
    String? selectedExercise;
    final setInputs = <_ExerciseSetInput>[
      createSetInput(),
      createSetInput(),
      createSetInput(),
    ];

    void syncSetInputs(int count) {
      if (count < 1) return;
      if (count > setInputs.length) {
        for (int i = setInputs.length; i < count; i++) {
          setInputs.add(createSetInput());
        }
      } else if (count < setInputs.length) {
        setInputs.removeRange(count, setInputs.length);
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final maxDialogHeight = MediaQuery.of(context).size.height * 0.85;

            return Dialog(
              backgroundColor: surfaceColor(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: borderColor(context), width: 1),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxDialogHeight),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
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
                            fontSize: 10,
                            color: textSecondaryColor(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: selectedCategory,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          hint: Text(
                            'Choose category',
                            style: GoogleFonts.jetBrainsMono(fontSize: 12),
                          ),
                          items: ExerciseLibrary.categoryNames.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(
                                category,
                                style: GoogleFonts.jetBrainsMono(fontSize: 12),
                              ),
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
                              fontSize: 10,
                              color: textSecondaryColor(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: selectedExercise,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            hint: Text(
                              'Choose exercise',
                              style: GoogleFonts.jetBrainsMono(fontSize: 12),
                            ),
                            items: ExerciseLibrary
                                .exercisesByCategory[selectedCategory]!
                                .map((exercise) {
                              return DropdownMenuItem(
                                value: exercise,
                                child: Text(
                                  exercise,
                                  style:
                                      GoogleFonts.jetBrainsMono(fontSize: 12),
                                ),
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
                            fontSize: 10,
                            color: textSecondaryColor(context),
                          ),
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
                          onChanged: (value) {
                            final count = int.tryParse(value);
                            if (count != null && count > 0 && count <= 20) {
                              setDialogState(() {
                                syncSetInputs(count);
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'SET DETAILS',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            color: textSecondaryColor(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...setInputs.asMap().entries.map((entry) {
                          final setIndex = entry.key;
                          final setInput = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              border: Border.all(color: borderColor(context)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SET ${(setIndex + 1).toString().padLeft(2, '0')}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    color: accent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: setInput.repsController,
                                        decoration: const InputDecoration(
                                          labelText: 'Reps',
                                          isDense: true,
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: setInput.weightController,
                                        decoration: const InputDecoration(
                                          labelText: 'Weight',
                                          isDense: true,
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                          decimal: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'RPE',
                                  style:
                                      GoogleFonts.jetBrainsMono(fontSize: 10),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: List.generate(10, (index) {
                                    final rpe = index + 1;
                                    return InkWell(
                                      onTap: () {
                                        setDialogState(() {
                                          setInput.selectedRpe =
                                              setInput.selectedRpe == rpe
                                                  ? null
                                                  : rpe;
                                        });
                                      },
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: setInput.selectedRpe == rpe
                                              ? accent
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: setInput.selectedRpe == rpe
                                                ? accent
                                                : borderColor(context),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$rpe',
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 11,
                                              color: setInput.selectedRpe == rpe
                                                  ? onAccent
                                                  : textPrimaryColor(context),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          );
                        }),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                '[CANCEL]',
                                style: GoogleFonts.jetBrainsMono(
                                  color: textSecondaryColor(context),
                                ),
                              ),
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
                                        style: GoogleFonts.jetBrainsMono(),
                                      ),
                                      backgroundColor: errorColor(context),
                                    ),
                                  );
                                  return;
                                }

                                final numSets =
                                    int.tryParse(setsController.text);
                                if (numSets == null || numSets <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '> Sets must be > 0',
                                        style: GoogleFonts.jetBrainsMono(),
                                      ),
                                      backgroundColor: errorColor(context),
                                    ),
                                  );
                                  return;
                                }

                                if (numSets != setInputs.length) {
                                  syncSetInputs(numSets);
                                }

                                final sets = <gym.Set>[];
                                for (final setInput in setInputs) {
                                  final reps = int.tryParse(
                                      setInput.repsController.text);
                                  final weight = double.tryParse(
                                    setInput.weightController.text,
                                  );

                                  if (reps == null || reps <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '> Reps must be > 0 for every set',
                                          style: GoogleFonts.jetBrainsMono(),
                                        ),
                                        backgroundColor: errorColor(context),
                                      ),
                                    );
                                    return;
                                  }

                                  if (weight == null || weight < 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '> Weight must be >= 0 for every set',
                                          style: GoogleFonts.jetBrainsMono(),
                                        ),
                                        backgroundColor: errorColor(context),
                                      ),
                                    );
                                    return;
                                  }

                                  sets.add(gym.Set(
                                    reps: reps,
                                    weight: weight,
                                    rpe: setInput.selectedRpe,
                                    note: null,
                                  ));
                                }

                                Navigator.pop(context);
                                onAdd(name.trim(), sets);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: onAccent,
                              ),
                              child: Text(
                                '[ ADD ]',
                                style: GoogleFonts.jetBrainsMono(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setsController.dispose();
        for (final setInput in allSetInputs) {
          setInput.dispose();
        }
      });
    });
  }

  static void showRenameExerciseDialog(
    BuildContext context, {
    required String currentName,
    required void Function(String name) onRename,
  }) {
    final accent = context.read<SettingsProvider>().accentColor;
    final nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                '> RENAME EXERCISE',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                autofocus: true,
                style: GoogleFonts.jetBrainsMono(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Exercise name',
                  labelStyle: GoogleFonts.jetBrainsMono(fontSize: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide:
                        BorderSide(color: borderColor(context), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: accent, width: 1),
                  ),
                ),
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
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('> Enter exercise name',
                                style: GoogleFonts.jetBrainsMono()),
                            backgroundColor: errorColor(context),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      onRename(name);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                    ),
                    child:
                        Text('[ RENAME ]', style: GoogleFonts.jetBrainsMono()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showAddSetDialog(
    BuildContext context, {
    gym.Set? lastSet,
    required void Function(gym.Set newSet) onAdd,
  }) {
    final settings = context.read<SettingsProvider>();
    final accent = settings.accentColor;

    final weightController = TextEditingController(
      text: lastSet?.weight.toString() ?? '',
    );
    final repsController = TextEditingController(
      text: lastSet?.reps.toString() ?? '8',
    );
    int? selectedRpe = lastSet?.rpe;

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
                      '> ADD SET',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: weightController,
                      decoration: InputDecoration(
                        labelText: 'Weight (${settings.weightUnit})',
                        hintText: 'e.g., 50',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: repsController,
                      decoration: const InputDecoration(
                        labelText: 'Reps',
                        hintText: 'e.g., 8',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Text('RPE (Rate of Perceived Exertion)',
                        style: GoogleFonts.jetBrainsMono(fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: List.generate(10, (index) {
                        final rpe = index + 1;
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedRpe = selectedRpe == rpe ? null : rpe;
                            });
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: selectedRpe == rpe
                                  ? accent
                                  : Colors.transparent,
                              border: Border.all(
                                color: selectedRpe == rpe
                                    ? accent
                                    : borderColor(context),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$rpe',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  color: selectedRpe == rpe
                                      ? Colors.black
                                      : textPrimaryColor(context),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
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
                            final weight =
                                double.tryParse(weightController.text);
                            final reps = int.tryParse(repsController.text);

                            if (weight == null || weight < 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('> Weight must be >= 0',
                                      style: GoogleFonts.jetBrainsMono()),
                                  backgroundColor: errorColor(context),
                                ),
                              );
                              return;
                            }

                            if (reps == null || reps <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('> Reps must be > 0',
                                      style: GoogleFonts.jetBrainsMono()),
                                  backgroundColor: errorColor(context),
                                ),
                              );
                              return;
                            }

                            final newSet = gym.Set(
                              reps: reps,
                              weight: weight,
                              rpe: selectedRpe,
                              note: null,
                            );

                            Navigator.pop(context);
                            onAdd(newSet);
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

  static void showEditSetDialog(
    BuildContext context, {
    required gym.Set set,
    required void Function(gym.Set updatedSet) onSave,
    required VoidCallback onDelete,
  }) {
    final settings = context.read<SettingsProvider>();
    final accent = settings.accentColor;

    final weightController = TextEditingController(text: set.weight.toString());
    final repsController = TextEditingController(text: set.reps.toString());
    final noteController = TextEditingController(text: set.note ?? '');
    int? selectedRpe = set.rpe;

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
                      '> EDIT SET',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: weightController,
                      decoration: InputDecoration(
                          labelText: 'Weight (${settings.weightUnit})'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: repsController,
                      decoration: const InputDecoration(labelText: 'Reps'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Text('RPE', style: GoogleFonts.jetBrainsMono(fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: List.generate(10, (index) {
                        final rpe = index + 1;
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedRpe = selectedRpe == rpe ? null : rpe;
                            });
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: selectedRpe == rpe
                                  ? accent
                                  : Colors.transparent,
                              border: Border.all(
                                color: selectedRpe == rpe
                                    ? accent
                                    : borderColor(context),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$rpe',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  color: selectedRpe == rpe
                                      ? Colors.black
                                      : textPrimaryColor(context),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      decoration:
                          const InputDecoration(labelText: 'Note (optional)'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      runSpacing: 8,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onDelete();
                          },
                          child: Text('[DELETE]',
                              style: GoogleFonts.jetBrainsMono(
                                  color: errorColor(context))),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
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
                                final weight =
                                    double.tryParse(weightController.text);
                                final reps = int.tryParse(repsController.text);

                                if (weight == null ||
                                    weight < 0 ||
                                    reps == null ||
                                    reps <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('> Invalid values',
                                          style: GoogleFonts.jetBrainsMono()),
                                      backgroundColor: errorColor(context),
                                    ),
                                  );
                                  return;
                                }

                                final updatedSet = gym.Set(
                                  reps: reps,
                                  weight: weight,
                                  rpe: selectedRpe,
                                  note: noteController.text.isNotEmpty
                                      ? noteController.text
                                      : null,
                                );

                                Navigator.pop(context);
                                onSave(updatedSet);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.black,
                              ),
                              child: Text('[ SAVE ]',
                                  style: GoogleFonts.jetBrainsMono()),
                            ),
                          ],
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

  static void showExerciseNoteDialog(
    BuildContext context, {
    String? currentNote,
    required void Function(String? note) onSave,
  }) {
    final noteController = TextEditingController(text: currentNote ?? '');
    final accent = context.read<SettingsProvider>().accentColor;

    showDialog(
      context: context,
      builder: (context) {
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
                  '> NOTE',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    hintText: 'Add a note...',
                  ),
                  maxLines: 3,
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
                        Navigator.pop(context);
                        onSave(noteController.text.isNotEmpty
                            ? noteController.text
                            : null);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                      ),
                      child:
                          Text('[ SAVE ]', style: GoogleFonts.jetBrainsMono()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void showWeekOptionsMenu(
    BuildContext context, {
    required void Function() onRename,
    required void Function() onDelete,
  }) {
    final accent = context.read<SettingsProvider>().accentColor;
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: accent),
              title: Text('RENAME', style: GoogleFonts.jetBrainsMono()),
              onTap: () {
                Navigator.pop(context);
                onRename();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: errorColor(context)),
              title: Text('DELETE',
                  style: GoogleFonts.jetBrainsMono(color: errorColor(context))),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  static void showRenameWeekDialog(
    BuildContext context, {
    required int currentWeek,
    required void Function(int newWeek) onRename,
  }) {
    final accent = context.read<SettingsProvider>().accentColor;
    final controller = TextEditingController(text: currentWeek.toString());
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                '> RENAME WEEK',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Week number',
                  hintText: 'e.g., 1',
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
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
                      final newWeek = int.tryParse(controller.text);
                      if (newWeek != null && newWeek > 0) {
                        Navigator.pop(context);
                        onRename(newWeek);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                    ),
                    child:
                        Text('[ RENAME ]', style: GoogleFonts.jetBrainsMono()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<bool> showDeleteWeekDialog(
    BuildContext context, {
    required int week,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
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
                '> DELETE WEEK?',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: errorColor(context),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This will permanently delete this week\'s workout data.',
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 12, color: textSecondaryColor(context)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('[CANCEL]',
                        style: GoogleFonts.jetBrainsMono(
                            color: textSecondaryColor(context))),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: errorColor(context),
                      foregroundColor: Colors.white,
                    ),
                    child:
                        Text('[ DELETE ]', style: GoogleFonts.jetBrainsMono()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  static Future<bool> showDeleteExerciseDialog(
    BuildContext context, {
    required String exerciseName,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
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
                '> DELETE EXERCISE?',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: errorColor(context),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This will permanently delete "$exerciseName" and all its sets.',
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 12, color: textSecondaryColor(context)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('[CANCEL]',
                        style: GoogleFonts.jetBrainsMono(
                            color: textSecondaryColor(context))),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: errorColor(context),
                      foregroundColor: Colors.white,
                    ),
                    child:
                        Text('[ DELETE ]', style: GoogleFonts.jetBrainsMono()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }
}
