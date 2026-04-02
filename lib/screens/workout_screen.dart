import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';
import '../models/exercise.dart';
import '../models/set.dart' as gym;
import '../providers/workout_plan_provider.dart';
import '../providers/workout_session_provider.dart';
import '../providers/settings_provider.dart';
import '../services/hive_service.dart';
import '../services/pr_tracking_service.dart';
import '../theme/app_theme.dart';
import '../utils/fade_page_route.dart';
import '../widgets/workout/exercise_card.dart';
import '../widgets/workout/workout_dialogs.dart';

class WorkoutScreen extends StatefulWidget {
  final WorkoutPlan plan;
  final int planIndex;

  const WorkoutScreen({super.key, required this.plan, required this.planIndex});

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
    WorkoutDialogs.showPRDialog(context, prs);
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
                    note: prevExercise.note,
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
    WorkoutDialogs.showAddExerciseDialog(
      context,
      onAdd: (name) {
        final session = _getOrCreateSession();
        final updatedExercises = List<Exercise>.from(session.exercises);
        updatedExercises.add(Exercise(name: name, sets: [], note: null));
        _updateSession(session.copyWith(exercises: updatedExercises));
        _autoSave();
      },
    );
  }

  void _showExerciseRenameDialog(int exerciseIndex) {
    final session = _getOrCreateSession();
    final exercise = session.exercises[exerciseIndex];
    WorkoutDialogs.showRenameExerciseDialog(
      context,
      currentName: exercise.name,
      onRename: (name) {
        final updatedExercises = List<Exercise>.from(session.exercises);
        updatedExercises[exerciseIndex] = Exercise(
          name: name,
          sets: exercise.sets,
          note: exercise.note,
        );
        _updateSession(session.copyWith(exercises: updatedExercises));
        _autoSave();
      },
    );
  }

  void _addSet(int exerciseIndex) {
    final session = _getOrCreateSession();
    final exercise = session.exercises[exerciseIndex];
    final lastSet = _getLastSetForExerciseInPlan(exercise.name);

    WorkoutDialogs.showAddSetDialog(
      context,
      lastSet: lastSet,
      onAdd: (newSet) {
        final updatedExercises = List<Exercise>.from(session.exercises);
        updatedExercises[exerciseIndex] = Exercise(
          name: exercise.name,
          sets: [...exercise.sets, newSet],
          note: exercise.note,
        );
        _updateSession(session.copyWith(exercises: updatedExercises));
        _autoSave();
      },
    );
  }

  void _editSet(int exerciseIndex, int setIndex) {
    final session = _getOrCreateSession();
    final exercise = session.exercises[exerciseIndex];
    final set = exercise.sets[setIndex];

    WorkoutDialogs.showEditSetDialog(
      context,
      set: set,
      onSave: (updatedSet) {
        final updatedSets = List<gym.Set>.from(exercise.sets);
        updatedSets[setIndex] = updatedSet;
        final updatedExercises = List<Exercise>.from(session.exercises);
        updatedExercises[exerciseIndex] = Exercise(
          name: exercise.name,
          sets: updatedSets,
          note: exercise.note,
        );
        _updateSession(session.copyWith(exercises: updatedExercises));
        _autoSave();
      },
      onDelete: () {
        final updatedSets = List<gym.Set>.from(exercise.sets)
          ..removeAt(setIndex);
        final updatedExercises = List<Exercise>.from(session.exercises);
        updatedExercises[exerciseIndex] = Exercise(
          name: exercise.name,
          sets: updatedSets,
          note: exercise.note,
        );
        _updateSession(session.copyWith(exercises: updatedExercises));
        _autoSave();
      },
    );
  }

  void _addExerciseNote(int exerciseIndex) {
    final session = _getOrCreateSession();
    final exercise = session.exercises[exerciseIndex];

    WorkoutDialogs.showExerciseNoteDialog(
      context,
      currentNote: exercise.note,
      onSave: (note) {
        final updatedExercises = List<Exercise>.from(session.exercises);
        updatedExercises[exerciseIndex] = Exercise(
          name: exercise.name,
          sets: exercise.sets,
          note: note,
        );
        _updateSession(session.copyWith(exercises: updatedExercises));
        _autoSave();
      },
    );
  }

  void _incrementReps(int exerciseIndex, int setIndex) {
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

  void _decrementReps(int exerciseIndex, int setIndex) {
    final session = _getOrCreateSession();
    final exercise = session.exercises[exerciseIndex];
    final set = exercise.sets[setIndex];

    if (set.reps <= 0) return;

    final updatedSets = List<gym.Set>.from(exercise.sets);
    updatedSets[setIndex] = gym.Set(
      reps: set.reps - 1,
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

  void _incrementWeight(int exerciseIndex, int setIndex) {
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

  void _decrementWeight(int exerciseIndex, int setIndex) {
    final session = _getOrCreateSession();
    final exercise = session.exercises[exerciseIndex];
    final set = exercise.sets[setIndex];

    if (set.weight <= 0) return;

    final updatedSets = List<gym.Set>.from(exercise.sets);
    updatedSets[setIndex] = gym.Set(
      reps: set.reps,
      weight: set.weight - 2.5,
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
    WorkoutDialogs.showWeekOptionsMenu(
      context,
      onRename: () => _renameWeek(index, week),
      onDelete: () => _deleteWeek(index),
    );
  }

  void _renameWeek(int index, int week) {
    WorkoutDialogs.showRenameWeekDialog(
      context,
      currentWeek: week,
      onRename: (newWeek) async {
        final otherWeeks = List<int>.from(_weeks)..removeAt(index);
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
        await HiveService.renameSessionWeek(widget.plan.name, week, newWeek);
      },
    );
  }

  void _deleteWeek(int index) async {
    final week = _weeks[index];
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

    final confirmed = await WorkoutDialogs.showDeleteWeekDialog(
      context,
      week: week,
    );

    if (confirmed) {
      await HiveService.deleteSessionForPlanAndWeek(widget.plan.name, week);
      setState(() {
        _weeks.removeAt(index);
        if (_currentWeekIndex >= _weeks.length) {
          _currentWeekIndex = _weeks.length - 1;
        } else if (_currentWeekIndex > index) {
          _currentWeekIndex -= 1;
        }
      });
    }
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
        toolbarHeight: 60,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: accent),
          onPressed: () {
            _autoSave();
            Navigator.pop(context);
          },
        ),
        bottom: _buildPlanTabBar(accent),
      ),
      body: Column(
        children: [
          _PlanHeader(
            planName: widget.plan.name,
            planIndex: widget.planIndex,
            accent: accent,
          ),
          Expanded(
            child: _GestureClaimingContainer(
              onSwipeLeft: _currentWeekIndex < _weeks.length - 1
                  ? () => _onWeekChanged(_currentWeekIndex + 1)
                  : null,
              onSwipeRight: _currentWeekIndex > 0
                  ? () => _onWeekChanged(_currentWeekIndex - 1)
                  : null,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverReorderableList(
                    itemCount: session.exercises.length + 1,
                    onReorder: _reorderExercises,
                    proxyDecorator: (child, index, animation) {
                      return Material(
                        color: terminalSurface,
                        borderRadius: BorderRadius.zero,
                        child: child,
                      );
                    },
                    itemBuilder: (context, index) {
                      if (index == session.exercises.length) {
                        return ReorderableDelayedDragStartListener(
                          key: const ValueKey('add_exercise_button'),
                          index: index,
                          child: InkWell(
                            onTap: _addEmptyExercise,
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: accent, width: 1),
                              ),
                              child: Center(
                                child: Text(
                                  '[ + ADD EXERCISE ]',
                                  style:
                                      GoogleFonts.jetBrainsMono(color: accent),
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      final exercise = session.exercises[index];

                      return ReorderableDelayedDragStartListener(
                        key: ValueKey(index),
                        index: index,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: terminalSurface,
                            border: Border.all(color: terminalBorder, width: 1),
                          ),
                          child: ExerciseCard(
                            exercise: exercise,
                            exerciseIndex: index,
                            accent: accent,
                            onIncrementReps: _incrementReps,
                            onDecrementReps: _decrementReps,
                            onIncrementWeight: _incrementWeight,
                            onDecrementWeight: _decrementWeight,
                            onAddSet: (i) => _addSet(i),
                            onEditSet: (i, setIndex) => _editSet(i, setIndex),
                            onAddNote: _addExerciseNote,
                            onRename: _showExerciseRenameDialog,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          _buildWeekNavBar(accent),
        ],
      ),
    );
  }

  PreferredSizeWidget? _buildPlanTabBar(Color accent) {
    final planProvider = context.watch<WorkoutPlanProvider>();
    final plans = planProvider.plans;

    if (plans.isEmpty) {
      return null;
    }

    return PreferredSize(
      preferredSize: const Size.fromHeight(40),
      child: Container(
        height: 40,
        color: terminalSurface,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: plans.length,
          itemBuilder: (context, index) {
            final plan = plans[index];
            final isSelected = index == widget.planIndex;
            return InkWell(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  FadePageRoute(
                    page: WorkoutScreen(
                      plan: plan,
                      planIndex: index,
                    ),
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  plan.name.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: isSelected ? Colors.black : terminalTextPrimary,
                  ),
                ),
              ),
            );
          },
        ),
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

class _GestureClaimingContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const _GestureClaimingContainer({
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  State<_GestureClaimingContainer> createState() =>
      _GestureClaimingContainerState();
}

class _GestureClaimingContainerState extends State<_GestureClaimingContainer> {
  double _dragAccumulator = 0;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        HorizontalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<
            HorizontalDragGestureRecognizer>(
          () => HorizontalDragGestureRecognizer(),
          (HorizontalDragGestureRecognizer instance) {
            instance
              ..dragStartBehavior = DragStartBehavior.down
              ..supportedDevices = {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse
              };
            instance.onStart = (details) {
              _dragAccumulator = 0;
            };
            instance.onUpdate = (details) {
              _dragAccumulator += details.delta.dx;
            };
            instance.onEnd = (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (_dragAccumulator.abs() > 60 && velocity.abs() > 250) {
                if (_dragAccumulator < 0 && widget.onSwipeLeft != null) {
                  widget.onSwipeLeft!();
                } else if (_dragAccumulator > 0 &&
                    widget.onSwipeRight != null) {
                  widget.onSwipeRight!();
                }
              }
              _dragAccumulator = 0;
            };
          },
        ),
      },
      child: widget.child,
    );
  }
}

class _PlanHeader extends StatelessWidget {
  final String planName;
  final int planIndex;
  final Color accent;

  const _PlanHeader({
    required this.planName,
    required this.planIndex,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final provider = context.read<WorkoutPlanProvider>();
        final plans = provider.plans;
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity!.abs() > 250) {
            if (details.primaryVelocity! < 0) {
              if (planIndex < plans.length - 1) {
                Navigator.pushReplacement(
                  context,
                  FadePageRoute(
                    page: WorkoutScreen(
                      plan: plans[planIndex + 1],
                      planIndex: planIndex + 1,
                    ),
                  ),
                );
              }
            } else {
              if (planIndex > 0) {
                Navigator.pushReplacement(
                  context,
                  FadePageRoute(
                    page: WorkoutScreen(
                      plan: plans[planIndex - 1],
                      planIndex: planIndex - 1,
                    ),
                  ),
                );
              }
            }
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: terminalSurface,
        child: Text(
          '> ${planName.toUpperCase()}',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: accent,
          ),
        ),
      ),
    );
  }
}
