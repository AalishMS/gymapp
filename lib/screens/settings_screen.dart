import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/workout_plan_provider.dart';
import '../providers/workout_session_provider.dart';
import '../services/sample_data_seeder.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              const _SectionHeader(title: 'Appearance'),
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('Theme'),
                subtitle: Text(_getThemeName(settings.themeMode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeDialog(context, settings),
              ),
              ListTile(
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: settings.accentColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                ),
                title: const Text('Accent Color'),
                subtitle: Text(_getAccentColorName(settings)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAccentColorDialog(context, settings),
              ),
              const Divider(),
              const _SectionHeader(title: 'Workout'),
              SwitchListTile(
                secondary: const Icon(Icons.speed),
                title: const Text('High Refresh Rate'),
                subtitle: const Text('Enable 90/120Hz display support'),
                value: settings.highRefreshRate,
                onChanged: (value) => settings.setHighRefreshRate(value),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.bolt),
                title: const Text('Auto-fill last weights'),
                subtitle: const Text(
                    'Automatically fill weight from previous workout'),
                value: settings.autoFillLast,
                onChanged: (value) => settings.setAutoFillLast(value),
              ),
              const Divider(),
              const _SectionHeader(title: 'Units'),
              ListTile(
                leading: const Icon(Icons.fitness_center),
                title: const Text('Weight Unit'),
                subtitle: Text(settings.weightUnit == 'kg'
                    ? 'Kilograms (kg)'
                    : 'Pounds (lbs)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showWeightUnitDialog(context, settings),
              ),
              const Divider(),
              const _SectionHeader(title: 'Data'),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Load Sample Data'),
                subtitle:
                    const Text('Add sample plans and workouts for testing'),
                onTap: () => _loadSampleData(context),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Clear All Data',
                    style: TextStyle(color: Colors.red)),
                subtitle: const Text('Delete all plans and workout history'),
                onTap: () => _confirmClearData(context),
              ),
              const Divider(),
              const _SectionHeader(title: 'About'),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Version'),
                subtitle: Text('1.0.0'),
              ),
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'Made by Aalish',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  String _getAccentColorName(SettingsProvider settings) {
    final index = settings.getAccentColorIndex();
    if (index >= 0 && index < SettingsProvider.accentColors.length) {
      return SettingsProvider.accentColors[index].name;
    }
    return 'Blue';
  }

  void _showAccentColorDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Accent Color'),
          content: Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                List.generate(SettingsProvider.accentColors.length, (index) {
              final option = SettingsProvider.accentColors[index];
              final isSelected = settings.accentColor == option.color;
              return GestureDetector(
                onTap: () {
                  settings.setAccentColor(index);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: option.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: option.color.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }),
          ),
        );
      },
    );
  }

  void _loadSampleData(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Load Sample Data'),
        content: const Text(
            'This will clear all existing data and load fresh sample plans and workouts. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SampleDataSeeder.clearAllData();
              await SampleDataSeeder.seedSampleData();
              if (context.mounted) {
                context.read<WorkoutPlanProvider>().loadPlans();
                context.read<WorkoutSessionProvider>().loadSessions();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sample data refreshed!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Load'),
          ),
        ],
      ),
    );
  }

  void _confirmClearData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will delete all workout plans and history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await SampleDataSeeder.clearAllData();
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (context.mounted) {
                context.read<WorkoutPlanProvider>().loadPlans();
                context.read<WorkoutSessionProvider>().loadSessions();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data cleared'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ThemeMode.values.map((mode) {
              return RadioListTile<ThemeMode>(
                title: Text(_getThemeName(mode)),
                value: mode,
                groupValue: settings.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    settings.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showWeightUnitDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Weight Unit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Kilograms (kg)'),
                value: 'kg',
                groupValue: settings.weightUnit,
                onChanged: (value) {
                  if (value != null) {
                    settings.setWeightUnit(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('Pounds (lbs)'),
                value: 'lbs',
                groupValue: settings.weightUnit,
                onChanged: (value) {
                  if (value != null) {
                    settings.setWeightUnit(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
