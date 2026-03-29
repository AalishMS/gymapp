import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_session_provider.dart';
import '../providers/settings_provider.dart';
import '../models/workout_session.dart';
import '../models/exercise.dart';
import '../models/set.dart' as gym;
import '../services/pr_tracking_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout History'),
      ),
      body: Consumer<WorkoutSessionProvider>(
        builder: (context, provider, child) {
          if (provider.sessions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No workout history yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Complete a workout to see it here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.sessions.length,
            itemBuilder: (context, index) {
              final session = provider.sessions[index];
              return _SessionCard(
                session: session,
                index: index,
                onDelete: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Workout'),
                      content: const Text('Are you sure?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            provider.deleteSession(index);
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditSessionScreen(
                        session: session,
                        sessionIndex: index,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatefulWidget {
  final WorkoutSession session;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _SessionCard({
    required this.session,
    required this.index,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final prs = PRTrackingService.checkForNewPRs(session.exercises);
    final hasPR = prs.isNotEmpty;
    final settings = context.watch<SettingsProvider>();
    final accentColor = settings.accentColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  hasPR ? Colors.amber.withValues(alpha: 0.2) : null,
              child: Icon(
                Icons.fitness_center,
                color: hasPR ? Colors.amber[700] : null,
              ),
            ),
            title: Row(
              children: [
                Expanded(child: Text(session.planName)),
                if (hasPR)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events,
                            size: 12, color: Colors.amber[700]),
                        const SizedBox(width: 2),
                        Text(
                          'PR',
                          style:
                              TextStyle(fontSize: 10, color: Colors.amber[700]),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              'Week ${session.weekNumber} • ${session.date.day}/${session.date.month}/${session.date.year} • ${session.exercises.length} exercises',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, size: 20, color: accentColor),
                  onPressed: widget.onEdit,
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: widget.onDelete,
                  tooltip: 'Delete',
                ),
                IconButton(
                  icon:
                      Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),
          ),
          if (_isExpanded) _buildExpandedContent(session),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(WorkoutSession session) {
    int totalSets = 0;
    int totalVolume = 0;

    for (var exercise in session.exercises) {
      totalSets += exercise.sets.length;
      for (var set in exercise.sets) {
        totalVolume += (set.weight * set.reps).round();
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatBadge(label: 'Sets', value: '$totalSets'),
              _StatBadge(label: 'Volume', value: '${totalVolume}kg'),
            ],
          ),
          const Divider(height: 24),
          ...session.exercises
              .map((exercise) => _ExerciseSection(exercise: exercise)),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;

  const _StatBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

class _ExerciseSection extends StatelessWidget {
  final Exercise exercise;

  const _ExerciseSection({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (exercise.note != null)
                const Icon(Icons.note, size: 14, color: Colors.amber),
            ],
          ),
          if (exercise.note != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                exercise.note!,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          const SizedBox(height: 8),
          ...exercise.sets.asMap().entries.map((entry) {
            final setIndex = entry.key;
            final set = entry.value;
            return Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Row(
                children: [
                  Text(
                    'Set ${setIndex + 1}:',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${set.weight}kg x ${set.reps}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (set.rpe != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: _getRpeColor(set.rpe!).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'RPE ${set.rpe}',
                        style: TextStyle(
                            fontSize: 10, color: _getRpeColor(set.rpe!)),
                      ),
                    ),
                  ],
                  if (set.note != null) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.note, size: 12, color: Colors.grey),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getRpeColor(int rpe) {
    if (rpe <= 3) return Colors.green;
    if (rpe <= 6) return Colors.yellow;
    if (rpe <= 8) return Colors.orange;
    return Colors.red;
  }
}

class EditSessionScreen extends StatefulWidget {
  final WorkoutSession session;
  final int sessionIndex;

  const EditSessionScreen({
    super.key,
    required this.session,
    required this.sessionIndex,
  });

  @override
  State<EditSessionScreen> createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends State<EditSessionScreen> {
  late WorkoutSession _session;
  late TextEditingController _planNameController;

  @override
  void initState() {
    super.initState();
    _session = widget.session.copyWith();
    _planNameController = TextEditingController(text: _session.planName);
  }

  @override
  void dispose() {
    _planNameController.dispose();
    super.dispose();
  }

  void _removeExercise(int index) {
    setState(() {
      final exercises = List<Exercise>.from(_session.exercises);
      exercises.removeAt(index);
      _session = _session.copyWith(exercises: exercises);
    });
  }

  void _save() {
    _session = _session.copyWith(planName: _planNameController.text);
    context
        .read<WorkoutSessionProvider>()
        .updateSession(widget.sessionIndex, _session);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Workout updated!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final accentColor = settings.accentColor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Workout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _planNameController,
            decoration: const InputDecoration(
              labelText: 'Plan Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Exercises',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._session.exercises.asMap().entries.map((entry) {
            final index = entry.key;
            final exercise = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            exercise.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red, size: 20),
                          onPressed: () => _removeExercise(index),
                        ),
                      ],
                    ),
                    if (exercise.note != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          exercise.note!,
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    ...exercise.sets.asMap().entries.map((setEntry) {
                      final setIndex = setEntry.key;
                      final set = setEntry.value;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text('${set.weight}kg x ${set.reps} reps'),
                        subtitle: set.note != null
                            ? Text(set.note!,
                                style: const TextStyle(fontSize: 10))
                            : null,
                        trailing: IconButton(
                          icon: Icon(Icons.edit, size: 16, color: accentColor),
                          onPressed: () =>
                              _showEditSetDialog(index, setIndex, set),
                        ),
                      );
                    }),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Set'),
                      onPressed: () => _showAddSetDialog(index, exercise),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showAddSetDialog(int exerciseIndex, Exercise exercise) {
    final weightController = TextEditingController();
    final repsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Set'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: repsController,
              decoration: const InputDecoration(labelText: 'Reps'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final weight = double.tryParse(weightController.text);
              final reps = int.tryParse(repsController.text);
              if (weight != null && reps != null) {
                final newSet = gym.Set(reps: reps, weight: weight);
                final updatedExercises =
                    List<Exercise>.from(_session.exercises);
                updatedExercises[exerciseIndex] = Exercise(
                  name: exercise.name,
                  sets: [...exercise.sets, newSet],
                  note: exercise.note,
                );
                setState(() {
                  _session = _session.copyWith(exercises: updatedExercises);
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditSetDialog(int exerciseIndex, int setIndex, gym.Set set) {
    final weightController = TextEditingController(text: set.weight.toString());
    final repsController = TextEditingController(text: set.reps.toString());
    final noteController = TextEditingController(text: set.note ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Set'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
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
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final exercises = List<Exercise>.from(_session.exercises);
              final exercise = exercises[exerciseIndex];
              final sets = List<gym.Set>.from(exercise.sets)
                ..removeAt(setIndex);
              exercises[exerciseIndex] = Exercise(
                  name: exercise.name, sets: sets, note: exercise.note);
              setState(() {
                _session = _session.copyWith(exercises: exercises);
              });
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final weight = double.tryParse(weightController.text);
              final reps = int.tryParse(repsController.text);
              if (weight != null && reps != null) {
                final exercises = List<Exercise>.from(_session.exercises);
                final exercise = exercises[exerciseIndex];
                final sets = List<gym.Set>.from(exercise.sets);
                sets[setIndex] = gym.Set(
                  reps: reps,
                  weight: weight,
                  rpe: set.rpe,
                  note: noteController.text.isNotEmpty
                      ? noteController.text
                      : null,
                );
                exercises[exerciseIndex] = Exercise(
                    name: exercise.name, sets: sets, note: exercise.note);
                setState(() {
                  _session = _session.copyWith(exercises: exercises);
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
