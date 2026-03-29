import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';
import '../models/exercise.dart';
import '../models/set.dart' as gym;
import '../providers/workout_session_provider.dart';
import '../providers/settings_provider.dart';
import '../services/hive_service.dart';
import '../services/pr_tracking_service.dart';

class WorkoutScreen extends StatefulWidget {
  final WorkoutPlan plan;

  const WorkoutScreen({super.key, required this.plan});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
    _tabController = TabController(
        length: _weeks.length, vsync: this, initialIndex: _currentWeekIndex);
    _tabController.animateTo(_currentWeekIndex);
    _tabController.addListener(_onTabChanged);
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

  Future<void> _onTabChanged() async {
    if (_tabController.indexIsChanging) return;
    await _autoSave();
    setState(() {
      _currentWeekIndex = _tabController.index;
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
    _tabController.dispose();
    _tabController = TabController(
        length: _weeks.length, vsync: this, initialIndex: _currentWeekIndex);
    _tabController.addListener(_onTabChanged);
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber[600]),
            const SizedBox(width: 8),
            const Text('New Personal Record!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: prs.map((pr) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pr.exerciseName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${pr.newPR}kg (Previous: ${pr.previousPR}kg)',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Awesome!'),
          ),
        ],
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

    final weightController = TextEditingController(
      text: lastSet?.weight.toString() ?? '',
    );
    final repsController = TextEditingController(
      text: lastSet?.reps.toString() ?? '8',
    );
    final settings = context.read<SettingsProvider>();
    int? selectedRpe = settings.autoFillLast ? lastSet?.rpe : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Set'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    const Text('RPE (Rate of Perceived Exertion)',
                        style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: List.generate(10, (index) {
                        final rpe = index + 1;
                        return ChoiceChip(
                          label: Text('$rpe'),
                          selected: selectedRpe == rpe,
                          onSelected: (selected) {
                            setDialogState(() {
                              selectedRpe = selected ? rpe : null;
                            });
                          },
                          selectedColor: _getRpeColor(rpe),
                          labelStyle: TextStyle(
                            color: selectedRpe == rpe ? Colors.white : null,
                            fontSize: 12,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getRpeLabel(selectedRpe),
                      style: TextStyle(
                          fontSize: 10, color: _getRpeColor(selectedRpe)),
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
                    final weight = double.tryParse(weightController.text);
                    final reps = int.tryParse(repsController.text);

                    if (weight == null || weight < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Weight must be >= 0')),
                      );
                      return;
                    }

                    if (reps == null || reps <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reps must be > 0')),
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
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getRpeColor(int? rpe) {
    if (rpe == null) return Colors.grey;
    if (rpe <= 3) return Colors.green;
    if (rpe <= 6) return Colors.yellow;
    if (rpe <= 8) return Colors.orange;
    return Colors.red;
  }

  String _getRpeLabel(int? rpe) {
    if (rpe == null) return 'Select RPE (optional)';
    if (rpe <= 3) return 'Easy';
    if (rpe <= 6) return 'Moderate';
    if (rpe <= 8) return 'Hard';
    return 'Max Effort';
  }

  void _editSet(int exerciseIndex, int setIndex) {
    final session = _getOrCreateSession();
    final exercise = session.exercises[exerciseIndex];
    final set = exercise.sets[setIndex];

    final weightController = TextEditingController(text: set.weight.toString());
    final repsController = TextEditingController(text: set.reps.toString());
    final noteController = TextEditingController(text: set.note ?? '');
    int? selectedRpe = set.rpe;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Set'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    const Text('RPE', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: List.generate(10, (index) {
                        final rpe = index + 1;
                        return ChoiceChip(
                          label: Text('$rpe'),
                          selected: selectedRpe == rpe,
                          onSelected: (selected) {
                            setDialogState(() {
                              selectedRpe = selected ? rpe : null;
                            });
                          },
                          selectedColor: _getRpeColor(rpe),
                          labelStyle: TextStyle(
                            color: selectedRpe == rpe ? Colors.white : null,
                            fontSize: 12,
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final updatedSets = List<gym.Set>.from(exercise.sets)
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
                  child:
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final weight = double.tryParse(weightController.text);
                    final reps = int.tryParse(repsController.text);

                    if (weight == null ||
                        weight < 0 ||
                        reps == null ||
                        reps <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid values')),
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

                    final updatedSets = List<gym.Set>.from(exercise.sets);
                    updatedSets[setIndex] = updatedSet;

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
                  child: const Text('Save'),
                ),
              ],
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Note for ${exercise.name}'),
          content: TextField(
            controller: noteController,
            decoration: const InputDecoration(
              labelText: 'Note',
              hintText: 'Add a note...',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedExercises = List<Exercise>.from(session.exercises);
                updatedExercises[exerciseIndex] = Exercise(
                  name: exercise.name,
                  sets: exercise.sets,
                  note: noteController.text.isNotEmpty
                      ? noteController.text
                      : null,
                );
                _updateSession(session.copyWith(exercises: updatedExercises));
                Navigator.pop(context);
                _autoSave();
              },
              child: const Text('Save'),
            ),
          ],
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
    final settings = context.read<SettingsProvider>();
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: settings.accentColor),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _renameWeek(context, index, week);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
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
    final controller = TextEditingController(text: week.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Week'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Week number',
            hintText: 'e.g., 1',
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newWeek = int.tryParse(controller.text);
              if (newWeek != null && newWeek > 0) {
                final otherWeeks = List<int>.from(_weeks)..removeAt(index);
                if (otherWeeks.contains(newWeek)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Week number already exists')),
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
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _deleteWeek(BuildContext context, int index) {
    if (_weeks.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete the last week')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Week'),
        content: const Text('Are you sure you want to delete this week?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
              _tabController.dispose();
              _tabController = TabController(
                length: _weeks.length,
                vsync: this,
                initialIndex: _currentWeekIndex,
              );
              _tabController.addListener(_onTabChanged);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _getOrCreateSession();
    final settings = context.watch<SettingsProvider>();
    final accentColor = settings.accentColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.plan.name} - Week $_currentWeek'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: session.exercises.length + 1,
              onReorder: _reorderExercises,
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final double elevation = Tween<double>(begin: 0, end: 6)
                        .animate(animation)
                        .value;
                    return Material(
                      elevation: elevation,
                      borderRadius: BorderRadius.circular(12),
                      child: child,
                    );
                  },
                  child: child,
                );
              },
              itemBuilder: (context, exerciseIndex) {
                if (exerciseIndex == session.exercises.length) {
                  return Container(
                    key: const ValueKey('add_exercise_button'),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Center(
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: accentColor.withValues(alpha: 0.2),
                        child: IconButton(
                          icon: Icon(Icons.add, color: accentColor),
                          onPressed: _addEmptyExercise,
                          tooltip: 'Add Exercise',
                        ),
                      ),
                    ),
                  );
                }

                final exercise = session.exercises[exerciseIndex];

                return Card(
                  key: ValueKey(exerciseIndex),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ReorderableDragStartListener(
                              index: exerciseIndex,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: const Icon(Icons.drag_handle,
                                    color: Colors.grey),
                              ),
                            ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  '${exerciseIndex + 1}',
                                  style: TextStyle(
                                    color: accentColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exercise.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (exercise.note != null)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 4),
                                    child: Icon(Icons.note,
                                        size: 16, color: Colors.amber),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.note_add, size: 20),
                                  onPressed: () =>
                                      _addExerciseNote(exerciseIndex),
                                  tooltip: 'Add note',
                                ),
                                IconButton(
                                  icon: Icon(Icons.add_circle,
                                      color: accentColor),
                                  onPressed: () => _addSet(exerciseIndex),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (exercise.sets.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'No sets added yet',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          ListView(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            children:
                                exercise.sets.asMap().entries.map((entry) {
                              final setIndex = entry.key;
                              final set = entry.value;
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  radius: 14,
                                  backgroundColor:
                                      accentColor.withValues(alpha: 0.2),
                                  child: Text(
                                    '${setIndex + 1}',
                                    style: TextStyle(
                                        color: accentColor, fontSize: 12),
                                  ),
                                ),
                                title: Flexible(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '${set.weight} kg x ${set.reps}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (set.rpe != null) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getRpeColor(set.rpe!)
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'RPE ${set.rpe}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: _getRpeColor(set.rpe!),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                subtitle: set.note != null
                                    ? Text(set.note!,
                                        style: const TextStyle(fontSize: 11))
                                    : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.add,
                                          size: 18, color: Colors.green),
                                      onPressed: () => _quickAddReps(
                                          exerciseIndex, setIndex),
                                      tooltip: '+1 Rep',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.trending_up,
                                          size: 18),
                                      onPressed: () => _quickAddWeight(
                                          exerciseIndex, setIndex),
                                      tooltip: '+2.5kg',
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.edit,
                                          color: accentColor, size: 20),
                                      onPressed: () =>
                                          _editSet(exerciseIndex, setIndex),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            color: Theme.of(context).cardColor,
            child: SafeArea(
              child: Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _weeks.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _weeks.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Center(
                              child: IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: _addNewWeek,
                                tooltip: 'Add Week ${_weeks.length + 1}',
                              ),
                            ),
                          );
                        }
                        final week = _weeks[index];
                        final isSelected = index == _currentWeekIndex;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Center(
                            child: GestureDetector(
                              onLongPress: () =>
                                  _showWeekOptionsMenu(context, index, week),
                              child: ChoiceChip(
                                label: Text('Week $week'),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _currentWeekIndex = index;
                                    });
                                    _tabController.animateTo(index);
                                  }
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_isSaving)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
