import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/workout_plan_provider.dart';
import '../providers/settings_provider.dart';
import '../models/workout_plan.dart';
import '../models/exercise_template.dart';
import '../theme/app_theme.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../services/sync_queue_service.dart';
import 'create_plan_screen.dart';
import 'edit_plan_screen.dart';
import 'workout_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import '../services/sample_data_seeder.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ConnectivityService _connectivityService = ConnectivityService();
  final SyncService _syncService = SyncService.instance;
  final SyncQueueService _syncQueueService = SyncQueueService.instance;
  late StreamSubscription<bool> _connectivitySubscription;
  bool _isOnline = true;
  Timer? _syncStatusTimer;

  @override
  void initState() {
    super.initState();
    _connectivityService.startListening();
    _connectivitySubscription =
        _connectivityService.onConnectivityChanged.listen((isOnline) {
      if (mounted) {
        setState(() => _isOnline = isOnline);
      }
    });
    _checkInitialConnectivity();

    // Start periodic sync status updates for UI
    _syncStatusTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {}); // Refresh to update sync indicators
    });
  }

  Future<void> _checkInitialConnectivity() async {
    final online = await _connectivityService.isOnline();
    if (mounted) {
      setState(() => _isOnline = online);
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _syncStatusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final accent = settings.accentColor;
    final bg = backgroundColor(context);
    final border = borderColor(context);
    final error = errorColor(context);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isOnline) _buildOfflineBanner(error, border),
            _buildHeader(context, accent, border),
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

  Widget _buildOfflineBanner(Color error, Color border) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: error.withAlpha(26),
        border: Border(bottom: BorderSide(color: error, width: 1)),
      ),
      child: Text(
        '> OFFLINE MODE',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: error,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color accent, Color border) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border, width: 1)),
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
      splashColor: accent.withAlpha(51),
      highlightColor: accent.withAlpha(26),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: accent, size: 22),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, WorkoutPlanProvider provider, Color accent) {
    final textSecondary = textSecondaryColor(context);

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
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first workout plan',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                color: textSecondary,
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
    final surface = surfaceColor(context);
    final border = borderColor(context);
    final textPrimary = textPrimaryColor(context);
    final textSecondary = textSecondaryColor(context);

    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => WorkoutScreen(plan: plan, planIndex: index)));
      },
      onLongPress: () => _showPlanOptions(context, plan, index, accent),
      splashColor: accent.withAlpha(38),
      highlightColor: accent.withAlpha(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surface,
          border: Border.all(color: border, width: 1),
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
            _buildSyncIndicator(context),
            const SizedBox(width: 8),
            Text(
              plan.name.toUpperCase(),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${plan.exercises.length} EXERCISES',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlanOptions(
      BuildContext context, WorkoutPlan plan, int index, Color accent) {
    final surface = surfaceColor(context);
    final border = borderColor(context);
    final textSecondary = textSecondaryColor(context);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: border, width: 1),
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
                  color: textSecondary,
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
                    style: GoogleFonts.jetBrainsMono(color: textSecondary)),
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
      splashColor: accent.withAlpha(51),
      highlightColor: accent.withAlpha(26),
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
      backgroundColor: accent,
      foregroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: accent, width: 1),
      ),
      child: Text('[ + ]',
          style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSyncIndicator(BuildContext context) {
    final queueLength = _syncQueueService.queueLength;
    final isSyncing = _syncService.isSyncing;

    if (queueLength == 0 && !isSyncing) {
      return const SizedBox.shrink(); // No indicator when nothing to sync
    }

    final settings = Provider.of<SettingsProvider>(context);
    final accent = settings.accentColor;

    if (isSyncing) {
      // Show syncing animation
      return Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'SYNC',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    } else {
      // Show pending count
      return GestureDetector(
        onTap: () {
          // Debug: Print queue status when tapped
          _syncQueueService.printQueueStatus();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: accent, width: 1),
          ),
          child: Text(
            '$queueLength',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }
}
