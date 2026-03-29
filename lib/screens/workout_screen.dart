import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';
import '../models/exercise.dart';
import '../models/set.dart' as gym;
import '../providers/workout_session_provider.dart';
import '../providers/settings_provider.dart';
import '../services/hive_service.dart';
import '../services/pr_tracking_service.dart';
import '../theme/app_theme.dart';

class WorkoutScreen extends StatefulWidget {
  final WorkoutPlan plan;

  const WorkoutScreen({super.key, required this.plan});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  List<int> _weeks = [1];
  int _currentWeekIndex = 0;
  final Map<int, WorkoutSession> _weekSessions = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadWeeks();
  }

  void _loadWeeks() {
    final existingWeeks = HiveService.getWeeksForPlan(widget.plan.name);
    if (existingWeeks.isEmpty) {
      _weeks = [1];
    } else {
      _weeks = existingWeeks;
      int maxWeek = _weeks.reduce((a, b) => a > b ? a : b);
      if (!_weeks.contains(maxWeek + 1)) {
        _weeks.add(maxWeek + 1);
      }
    }
    _currentWeekIndex = _weeks.length - 1;
    _loadSessionForCurrentWeek();
  }

  void _loadSessionForCurrentWeek() {
    final week = _weeks[_currentWeekIndex];
    final existingSession =
        HiveService.getSessionForPlanAndWeek(widget.plan.name, week);
    if (existingSession != null) {
      _weekSessions[week] = existingSession;
    }
  }

  gym.Set? _getLastSetForExerciseInPlan(String exerciseName) {
    final currentWeek = _weeks[_currentWeekIndex];
    if (currentWeek > 1) {
      final prevWeekSession = HiveService.getSessionForPlanAndWeek(
        widget.plan.name,
        currentWeek - 1,
      );
      if (prevWeekSession != null) {
        for (var exercise in prevWeekSession.exercises) {
          if (exercise.name.toLowerCase() == exerciseName.toLowerCase() &&
              exercise.sets.isNotEmpty) {
            return exercise.sets.last;
          }
        }
      }
    }
    return HiveService.getLastSetForExercise(exerciseName);
  }

  Future<void> _onWeekChanged(int newIndex) async {
    await _autoSave();
    setState(() {
      _currentWeekIndex = newIndex;
    });
    _loadSessionForCurrentWeek();
  }

  Future<void> _addNewWeek() async {
    await _autoSave();
    final lastWeek = _weeks.last;
    setState(() {
      _weeks.add(lastWeek + 1);
      _currentWeekIndex = _weeks.length - 1;
    });
  }

  Future<void> _autoSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final session = _getOrCreateSession();
    final hasSets = session.exercises.any((e) => e.sets.isNotEmpty);

    if (hasSets) {
      final prs = PRTrackingService.checkForNewPRs(session.exercises);

      context.read<WorkoutSessionProvider>().startWorkout(
            session.planName,
            session.exercises,
            weekNumber: _currentWeek,
          );
      await context.read<WorkoutSessionProvider>().saveWorkout();

      if (prs.isNotEmpty && mounted) {
        _showPRDialog(prs);
      }
    }

    setState(() => _isSaving = false);
  }

  void _showPRDialog(List<PRResult> prs) {
    final accent = context.read<SettingsProvider>().accentColor;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: terminalSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: terminalBorder, width: 1),
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
                          '${pr.newPR}kg (Previous: ${pr.previousPR}kg)',
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 12, color: terminalTextSecondary),
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
                    foregroundColor: Colors.black,
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

  int get _currentWeek => _weeks[_currentWeekIndex];

  WorkoutSession _getOrCreateSession() {
    if (_weekSessions.containsKey(_currentWeek)) {
      return _weekSessions[_currentWeek]!;
    }

    final prevWeek = _currentWeek - 1;
    if (prevWeek >= 1) {
      final prevSession = HiveService.getSessionForPlanAndWeek(
        widget.plan.name,
        prevWeek,
      );
      if (prevSession != null &&
          prevSession.exercises.any((e) => e.sets.isNotEmpty)) {
        return WorkoutSession(
          date: DateTime.now(),
          planName: widget.plan.name,
          exercises: prevSession.exercises
              .map((prevExercise) => Exercise(
                    name: prevExercise.name,
                    sets: prevExercise.sets
                        .map((s) => gym.Set(
                              reps: s.reps,
                              weight: s.weight,
                              rpe: s.rpe,
                              note: s.note,
                            ))
                        .toList(),
                    note: null,
                  ))
              .toList(),
          weekNumber: _currentWeek,
        );
      }
    }

    return WorkoutSession(
      date: DateTime.now(),
      planName: widget.plan.name,
      exercises: widget.plan.exercises
          .map((template) => Exercise(
                name: template.name,
                sets: List.generate(
                  template.sets,
                  (_) => gym.Set(reps: 0, weight: 0),
                ),
                note: null,
              ))
          .toList(),
      weekNumber: _currentWeek,
    );
  }

  void _updateSession(WorkoutSession session) {
    _weekSessions[_currentWeek] = session;
    setState(() {});
  }

  void _addEmptyExercise() {
    final session = _getOrCreateSession();
    final updatedExercises = List<Exercise>.from(session.exercises);
    updatedExercises.add(Exercise(name: 'New Exercise', sets: [], note: null));
    _updateSession(session.copyWith(exercises: updatedExercises));
    _autoSave();
  }

  void _addSet(int exerciseIndex) {
    final session = _getOrCreateSession();
    final exercise = session.exercises[exerciseIndex];
    final lastSet = _getLastSetForExerciseInPlan(exercise.name);
    final settings = context.read<SettingsProvider>();
    final accent = settings.accentColor;

    final weightController = TextEditingController(
      text: lastSet?.weight.toString() ?? '',
    );
    final repsController = TextEditingController(
      text: lastSet?.reps.toString() ?? '8',
    );
    int? selectedRpe = settings.autoFillLast ? lastSet?.rpe : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: terminalSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: const BorderSide(color: terminalBorder, width: 1),
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
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
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
                                    : terminalBorder,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$rpe',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  color: selectedRpe == rpe
                                      ? Colors.black
                                      : terminalTextPrimary,
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
                                  color: terminalTextSecondary)),
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
                                  backgroundColor: terminalError,
                                ),
                              );
                              return;
                            }

                            if (reps == null || reps <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('> Reps must be > 0',
                                      style: GoogleFonts.jetBrainsMono()),
                                  backgroundColor: terminalError,
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

                            final updatedExercises =
                                List<Exercise>.from(session.exercises);
                            updatedExercises[exerciseIndex] = Exercise(
                              name: exercise.name,
                              sets: [...exercise.sets, newSet],
                              note: exercise.note,
                            );

                            _updateSession(
                                session.copyWith(exercises: updatedExercises));
                            Navigator.pop(context);
                            _autoSave();
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

  void _editSet(int exerciseIndex, int setIndex) {
    final session = _getOrCreateSession();
    final exercise = session.exercises[exerciseIndex];
    final set = exercise.sets[setIndex];
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
              backgroundColor: terminalSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: const BorderSide(color: terminalBorder, width: 1),
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
                      decoration:
                          const InputDecoration(labelText: 'Weight (kg)'),
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
                                    : terminalBorder,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$rpe',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  color: selectedRpe == rpe
                                      ? Colors.black
                                      : terminalTextPrimary,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            final updatedSets =
                                List<gym.Set>.from(exercise.sets)
                                  ..removeAt(setIndex);
                            final updatedExercises =
                                List<Exercise>.from(session.exercises);
                            updatedExercises[exerciseIndex] = Exercise(
                              name: exercise.name,
                              sets: updatedSets,
                              note: exercise.note,
                            );
                            _updateSession(
                                session.copyWith(exercises: updatedExercises));
                            Navigator.pop(context);
                            _autoSave();
                          },
                          child: Text('[DELETE]',
                              style: GoogleFonts.jetBrainsMono(
                                  color: terminalError)),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('[CANCEL]',
                                  style: GoogleFonts.jetBrainsMono(
                                      color: terminalTextSecondary)),
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
                                      backgroundColor: terminalError,
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

                                final updatedSets =
                                    List<gym.Set>.from(exercise.sets);
                                updatedSets[setIndex] = updatedSet;

                                final updatedExercises =
                                    List<Exercise>.from(session.exercises);
                                updatedExercises[exerciseIndex] = Exercise(
                                  name: exercise.name,
                                  sets: updatedSets,
                                  note: exercise.note,
                                );

                                _updateSession(session.copyWith(
                                    exercises: updatedExercises));
                                Navigator.pop(context);
                                _autoSave();
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

  void _addExerciseNote(int exerciseIndex) {
    final session = _getOrCreateSession();
    final exercise = session.exercises[exerciseIndex];
    final noteController = TextEditingController(text: exercise.note ?? '');
    final accent = context.read<SettingsProvider>().accentColor;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: terminalSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: const BorderSide(color: terminalBorder, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '> NOTE FOR ${exercise.name.toUpperCase()}',
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
                              color: terminalTextSecondary)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final updatedExercises =
                            List<Exercise>.from(session.exercises);
                        updatedExercises[exerciseIndex] = Exercise(
                          name: exercise.name,
                          sets: exercise.sets,
                          note: noteController.text.isNotEmpty
                              ? noteController.text
                              : null,
                        );
                        _updateSession(
                            session.copyWith(exercises: updatedExercises));
                        Navigator.pop(context);
                        _autoSave();
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

  void _quickAddReps(int exerciseIndex, int setIndex) {
    final session = _getOrCreateSession();
    final exercise = session.exercises[exerciseIndex];
    final set = exercise.sets[setIndex];

    final updatedSets = List<gym.Set>.from(exercise.sets);
    updatedSets[setIndex] = gym.Set(
      reps: set.reps + 1,
      weight: set.weight,
      rpe: set.rpe,
      note: set.note,
    );

    final updatedExercises = List<Exercise>.from(session.exercises);
    updatedExercises[exerciseIndex] = Exercise(
      name: exercise.name,
      sets: updatedSets,
      note: exercise.note,
    );

    _updateSession(session.copyWith(exercises: updatedExercises));
    _autoSave();
  }

  void _quickAddWeight(int exerciseIndex, int setIndex) {
    final session = _getOrCreateSession();
    final exercise = session.exercises[exerciseIndex];
    final set = exercise.sets[setIndex];

    final updatedSets = List<gym.Set>.from(exercise.sets);
    updatedSets[setIndex] = gym.Set(
      reps: set.reps,
      weight: set.weight + 2.5,
      rpe: set.rpe,
      note: set.note,
    );

    final updatedExercises = List<Exercise>.from(session.exercises);
    updatedExercises[exerciseIndex] = Exercise(
      name: exercise.name,
      sets: updatedSets,
      note: exercise.note,
    );

    _updateSession(session.copyWith(exercises: updatedExercises));
    _autoSave();
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final session = _getOrCreateSession();
    final exercises = List<Exercise>.from(session.exercises);
    final exercise = exercises.removeAt(oldIndex);
    exercises.insert(newIndex, exercise);
    _updateSession(session.copyWith(exercises: exercises));
  }

  void _showWeekOptionsMenu(BuildContext context, int index, int week) {
    final accent = context.read<SettingsProvider>().accentColor;
    showModalBottomSheet(
      context: context,
      backgroundColor: terminalSurface,
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
                _renameWeek(context, index, week);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: terminalError),
              title: Text('DELETE',
                  style: GoogleFonts.jetBrainsMono(color: terminalError)),
              onTap: () {
                Navigator.pop(context);
                _deleteWeek(context, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _renameWeek(BuildContext context, int index, int week) {
    final accent = context.read<SettingsProvider>().accentColor;
    final controller = TextEditingController(text: week.toString());
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: terminalSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: terminalBorder, width: 1),
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
                            color: terminalTextSecondary)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final newWeek = int.tryParse(controller.text);
                      if (newWeek != null && newWeek > 0) {
                        final otherWeeks = List<int>.from(_weeks)
                          ..removeAt(index);
                        if (otherWeeks.contains(newWeek)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('> Week number already exists',
                                  style: GoogleFonts.jetBrainsMono()),
                              backgroundColor: terminalError,
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _weeks[index] = newWeek;
                        });
                        await HiveService.renameSessionWeek(
                            widget.plan.name, week, newWeek);
                        if (mounted) Navigator.pop(context);
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

  void _deleteWeek(BuildContext context, int index) {
    if (_weeks.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('> Cannot delete the last week',
              style: GoogleFonts.jetBrainsMono()),
          backgroundColor: terminalError,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: terminalSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: terminalBorder, width: 1),
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
                  color: terminalError,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This will permanently delete this week\'s workout data.',
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 12, color: terminalTextSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('[CANCEL]',
                        style: GoogleFonts.jetBrainsMono(
                            color: terminalTextSecondary)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final deletedWeek = _weeks[index];
                      final deletedIndex = index;
                      await HiveService.deleteSessionForPlanAndWeek(
                          widget.plan.name, deletedWeek);
                      setState(() {
                        _weeks.removeAt(index);
                        if (_currentWeekIndex >= _weeks.length) {
                          _currentWeekIndex = _weeks.length - 1;
                        } else if (_currentWeekIndex > deletedIndex) {
                          _currentWeekIndex -= 1;
                        }
                      });
                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: terminalError,
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
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _getOrCreateSession();
    final settings = context.watch<SettingsProvider>();
    final accent = settings.accentColor;

    return Scaffold(
      backgroundColor: terminalBackground,
      appBar: AppBar(
        backgroundColor: terminalSurface,
        toolbarHeight: 100,
        title: Text(
          '> ${widget.plan.name.toUpperCase()}',
          style: GoogleFonts.jetBrainsMono(
              fontSize: 14, fontWeight: FontWeight.bold, color: accent),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: accent),
          onPressed: () {
            _autoSave();
            Navigator.pop(context);
          },
        ),
        bottom: _weeks.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(40),
                child: Container(
                  height: 40,
                  color: terminalSurface,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _weeks.length,
                    itemBuilder: (context, index) {
                      final week = _weeks[index];
                      final isSelected = index == _currentWeekIndex;
                      return InkWell(
                        onTap: () {
                          _onWeekChanged(index);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? accent : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: isSelected ? accent : terminalBorder,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            'WEEK $week',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              color: isSelected
                                  ? Colors.black
                                  : terminalTextPrimary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: session.exercises.length + 1,
              onReorder: _reorderExercises,
              proxyDecorator: (child, index, animation) {
                return Material(
                  color: terminalSurface,
                  borderRadius: BorderRadius.zero,
                  child: child,
                );
              },
              itemBuilder: (context, exerciseIndex) {
                if (exerciseIndex == session.exercises.length) {
                  return Container(
                    key: const ValueKey('add_exercise_button'),
                    margin: const EdgeInsets.all(8),
                    child: InkWell(
                      onTap: _addEmptyExercise,
                      child: Container(
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
                  );
                }

                final exercise = session.exercises[exerciseIndex];

                return Container(
                  key: ValueKey(exerciseIndex),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: terminalSurface,
                    border: Border.all(color: terminalBorder, width: 1),
                  ),
                  child: _buildExerciseCard(exercise, exerciseIndex, accent),
                );
              },
            ),
          ),
          _buildWeekNavBar(accent),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(
      Exercise exercise, int exerciseIndex, Color accent) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onLongPress: () => _showWeekOptionsMenu(
                    context, _currentWeekIndex, _currentWeek),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: accent, width: 1),
                  ),
                  child: Text(
                    '${exerciseIndex + 1}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  exercise.name.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (exercise.note != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(Icons.note, size: 16, color: accent),
                ),
              InkWell(
                onTap: () => _addExerciseNote(exerciseIndex),
                child: Icon(Icons.note_add,
                    size: 20, color: terminalTextSecondary),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _addSet(exerciseIndex),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: accent, width: 1),
                  ),
                  child: Text('[+]',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 12, color: accent)),
                ),
              ),
            ],
          ),
          if (exercise.sets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '> No sets added yet',
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 12, color: terminalTextSecondary),
              ),
            )
          else
            ...exercise.sets.asMap().entries.map((entry) {
              final setIndex = entry.key;
              final set = entry.value;
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: terminalBorder),
                      ),
                      child: Text(
                        'SET ${(setIndex + 1).toString().padLeft(2, '0')}',
                        style: GoogleFonts.jetBrainsMono(fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${set.weight} KG  x  ${set.reps} REPS${set.rpe != null ? ' @ RPE ${set.rpe}' : ''}',
                        style: GoogleFonts.jetBrainsMono(fontSize: 12),
                      ),
                    ),
                    if (set.note != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(Icons.note,
                            size: 12, color: terminalTextSecondary),
                      ),
                    InkWell(
                      onTap: () => _quickAddReps(exerciseIndex, setIndex),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: Text('[+1]',
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 11, color: Colors.green)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _quickAddWeight(exerciseIndex, setIndex),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: Text('[+2.5]',
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 11, color: Colors.green)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _editSet(exerciseIndex, setIndex),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: Text('[EDIT]',
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 11, color: accent)),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildWeekNavBar(Color accent) {
    return Container(
      decoration: const BoxDecoration(
        color: terminalSurface,
        border: Border(top: BorderSide(color: terminalBorder, width: 1)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _weeks.length + 1,
                itemBuilder: (context, index) {
                  if (index == _weeks.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Center(
                        child: InkWell(
                          onTap: _addNewWeek,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: accent),
                            ),
                            child: Text('[+ WEEK ${_weeks.length + 1}]',
                                style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10, color: accent)),
                          ),
                        ),
                      ),
                    );
                  }
                  final week = _weeks[index];
                  final isSelected = index == _currentWeekIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Center(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _currentWeekIndex = index;
                          });
                        },
                        onLongPress: () =>
                            _showWeekOptionsMenu(context, index, week),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? accent : Colors.transparent,
                            border: Border.all(
                                color: isSelected ? accent : terminalBorder),
                          ),
                          child: Text(
                            'WEEK $week',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              color: isSelected
                                  ? Colors.black
                                  : terminalTextPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isSaving)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: accent),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '> Auto-saving...',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 10, color: terminalTextSecondary),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
