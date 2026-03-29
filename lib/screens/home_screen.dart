import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_plan_provider.dart';
import '../models/workout_plan.dart';
import '../models/exercise_template.dart';
import 'create_plan_screen.dart';
import 'edit_plan_screen.dart';
import 'workout_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import '../services/sample_data_seeder.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
            },
            tooltip: 'Statistics',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
            tooltip: 'History',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Consumer<WorkoutPlanProvider>(
        builder: (context, provider, child) {
          if (provider.plans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fitness_center,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No workout plans yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + to create your first plan',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await SampleDataSeeder.seedSampleData();
                      provider.loadPlans();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sample data loaded!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Load Sample Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: provider.plans.length,
            itemBuilder: (context, index) {
              final plan = provider.plans[index];
              return _buildPlanTile(context, plan, index);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePlanScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPlanTile(BuildContext context, WorkoutPlan plan, int index) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutScreen(plan: plan),
            ),
          );
        },
        onLongPress: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(plan.name),
              content: const Text('What would you like to do?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    final copyPlan = WorkoutPlan(
                      name: '${plan.name} (Copy)',
                      exercises: plan.exercises
                          .map((e) => ExerciseTemplate(
                                name: e.name,
                                sets: e.sets,
                              ))
                          .toList(),
                    );
                    context.read<WorkoutPlanProvider>().addPlan(copyPlan);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Plan copied!')),
                    );
                  },
                  child: const Text('Copy'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditPlanScreen(
                          plan: plan,
                          planIndex: index,
                        ),
                      ),
                    );
                  },
                  child: const Text('Edit'),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.read<WorkoutPlanProvider>().deletePlan(index);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 32, color: Colors.blue),
              const SizedBox(height: 12),
              Text(
                plan.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '${plan.exercises.length} exercises',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
