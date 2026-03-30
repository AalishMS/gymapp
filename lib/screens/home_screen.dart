import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/workout_plan_provider.dart';
import '../providers/settings_provider.dart';
import '../models/workout_plan.dart';
import '../models/exercise_template.dart';
import '../theme/app_theme.dart';
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
    final settings = context.watch<SettingsProvider>();
    final accent = settings.accentColor;

    return Scaffold(
      backgroundColor: terminalBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, accent),
            Expanded(
              child: Consumer<WorkoutPlanProvider>(
                builder: (context, provider, child) {
                  if (provider.plans.isEmpty) {
                    return _buildEmptyState(context, provider, accent);
                  }
                  return _buildPlanGrid(context, provider, accent);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(context, accent),
    );
  }

  Widget _buildHeader(BuildContext context, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: terminalBorder, width: 1)),
      ),
      child: Row(
        children: [
          Text(
            '> OPENGYM',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
          const Spacer(),
          _buildIconButton(
            icon: Icons.bar_chart,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const StatsScreen())),
            accent: accent,
          ),
          _buildIconButton(
            icon: Icons.history,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HistoryScreen())),
            accent: accent,
          ),
          _buildIconButton(
            icon: Icons.settings,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
            accent: accent,
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
      {required IconData icon,
      required VoidCallback onTap,
      required Color accent}) {
    return InkWell(
      onTap: onTap,
      splashColor: accent.withValues(alpha: 0.2),
      highlightColor: accent.withValues(alpha: 0.1),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: accent, size: 22),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, WorkoutPlanProvider provider, Color accent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '> NO PLANS FOUND',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 16,
                color: terminalTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first workout plan',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                color: terminalTextSecondary,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () async {
                await SampleDataSeeder.seedSampleData();
                provider.loadPlans();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('> Sample data loaded!',
                          style:
                              GoogleFonts.jetBrainsMono(color: Colors.black)),
                      backgroundColor: accent,
                    ),
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent, width: 1),
              ),
              child: Text('[ LOAD SAMPLE DATA ]',
                  style: GoogleFonts.jetBrainsMono()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanGrid(
      BuildContext context, WorkoutPlanProvider provider, Color accent) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: provider.plans.length,
      itemBuilder: (context, index) {
        final plan = provider.plans[index];
        return _buildPlanCard(context, plan, index, accent);
      },
    );
  }

  Widget _buildPlanCard(
      BuildContext context, WorkoutPlan plan, int index, Color accent) {
    return InkWell(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => WorkoutScreen(plan: plan)));
      },
      onLongPress: () => _showPlanOptions(context, plan, index, accent),
      splashColor: accent.withValues(alpha: 0.15),
      highlightColor: accent.withValues(alpha: 0.08),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: terminalSurface,
          border: Border.all(color: terminalBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: accent, width: 1),
                  ),
                  child: Text(
                    '[${index + 1}]',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              plan.name.toUpperCase(),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: terminalTextPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${plan.exercises.length} EXERCISES',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: terminalTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlanOptions(
      BuildContext context, WorkoutPlan plan, int index, Color accent) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
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
                '> ${plan.name}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select action:',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: terminalTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                label: '[COPY] Duplicate plan',
                onTap: () {
                  Navigator.pop(ctx);
                  final copyPlan = WorkoutPlan(
                    name: '${plan.name} (Copy)',
                    exercises: plan.exercises
                        .map(
                            (e) => ExerciseTemplate(name: e.name, sets: e.sets))
                        .toList(),
                  );
                  context.read<WorkoutPlanProvider>().addPlan(copyPlan);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('> Plan copied!',
                          style:
                              GoogleFonts.jetBrainsMono(color: Colors.black)),
                      backgroundColor: accent,
                    ),
                  );
                },
                accent: accent,
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                label: '[EDIT] Modify plan',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditPlanScreen(plan: plan, planIndex: index),
                    ),
                  );
                },
                accent: accent,
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                label: '[DELETE] Remove plan',
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<WorkoutPlanProvider>().deletePlan(index);
                },
                accent: Colors.red,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('[CANCEL]',
                    style: GoogleFonts.jetBrainsMono(
                        color: terminalTextSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      {required String label,
      required VoidCallback onTap,
      required Color accent}) {
    return InkWell(
      onTap: onTap,
      splashColor: accent.withValues(alpha: 0.2),
      highlightColor: accent.withValues(alpha: 0.1),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: accent, width: 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(fontSize: 12, color: accent),
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context, Color accent) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CreatePlanScreen()));
      },
      backgroundColor: Colors.black,
      foregroundColor: accent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: accent, width: 1),
      ),
      child: Text('[ + ]',
          style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold)),
    );
  }
}
