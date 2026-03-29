import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/workout_plan_provider.dart';
import '../providers/workout_session_provider.dart';
import '../services/sample_data_seeder.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _getAccentColorName(SettingsProvider settings) {
    final index = settings.getAccentColorIndex();
    if (index >= 0 && index < SettingsProvider.accentColors.length) {
      return SettingsProvider.accentColors[index].name;
    }
    return 'MATRIX GREEN';
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;

    return Scaffold(
      backgroundColor: terminalBackground,
      appBar: AppBar(
        backgroundColor: terminalSurface,
        title: Text(
          '> SETTINGS',
          style: GoogleFonts.jetBrainsMono(
              fontSize: 16, fontWeight: FontWeight.bold, color: accent),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: accent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              _SectionHeader(title: 'APPEARANCE', accent: accent),
              _buildAccentColorSection(context, settings, accent),
              const Divider(color: terminalBorder),
              _SectionHeader(title: 'WORKOUT', accent: accent),
              _buildSwitchTile(
                icon: Icons.speed,
                title: 'HIGH REFRESH RATE',
                subtitle: 'Enable 90/120Hz display support',
                value: settings.highRefreshRate,
                onChanged: (value) => settings.setHighRefreshRate(value),
                accent: accent,
              ),
              _buildSwitchTile(
                icon: Icons.bolt,
                title: 'AUTO-FILL LAST WEIGHTS',
                subtitle: 'Automatically fill weight from previous workout',
                value: settings.autoFillLast,
                onChanged: (value) => settings.setAutoFillLast(value),
                accent: accent,
              ),
              const Divider(color: terminalBorder),
              _SectionHeader(title: 'UNITS', accent: accent),
              _buildSettingsTile(
                icon: Icons.fitness_center,
                title: 'WEIGHT UNIT',
                subtitle: settings.weightUnit == 'kg'
                    ? 'KILOGRAMS (KG)'
                    : 'POUNDS (LBS)',
                onTap: () => _showWeightUnitDialog(context, settings),
                accent: accent,
              ),
              const Divider(color: terminalBorder),
              _SectionHeader(title: 'DATA', accent: accent),
              _buildSettingsTile(
                icon: Icons.download,
                title: 'LOAD SAMPLE DATA',
                subtitle: 'Add sample plans and workouts for testing',
                onTap: () => _loadSampleData(context),
                accent: accent,
              ),
              _buildSettingsTile(
                icon: Icons.delete_forever,
                title: 'CLEAR ALL DATA',
                subtitle: 'Delete all plans and workout history',
                onTap: () => _confirmClearData(context),
                isDestructive: true,
                accent: accent,
              ),
              const Divider(color: terminalBorder),
              _SectionHeader(title: 'ABOUT', accent: accent),
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'VERSION',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 10, color: terminalTextSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '1.0.0',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 14, color: terminalTextPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  '> Made by Aalish',
                  style: GoogleFonts.jetBrainsMono(
                    color: terminalTextSecondary,
                    fontSize: 12,
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

  Widget _buildAccentColorSection(
      BuildContext context, SettingsProvider settings, Color accent) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACCENT COLOR',
            style: GoogleFonts.jetBrainsMono(
                fontSize: 12, fontWeight: FontWeight.bold, color: accent),
          ),
          const SizedBox(height: 8),
          Text(
            '> ${_getAccentColorName(settings)}',
            style: GoogleFonts.jetBrainsMono(
                fontSize: 10, color: terminalTextSecondary),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                List.generate(SettingsProvider.accentColors.length, (index) {
              final option = SettingsProvider.accentColors[index];
              final isSelected = settings.accentColor == option.color;
              return _buildColorBox(option, isSelected, settings, accent);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildColorBox(AccentColorOption option, bool isSelected,
      SettingsProvider settings, Color currentAccent) {
    final isLight = option.color.computeLuminance() > 0.5;

    return InkWell(
      onTap: () {
        settings.setAccentColor(SettingsProvider.accentColors.indexOf(option));
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? option.color.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? option.color : terminalBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              option.name,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? option.color : terminalTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: option.color,
                border: Border.all(
                  color: isSelected
                      ? (isLight ? Colors.black : Colors.white)
                      : terminalBorder,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 14,
                      color: isLight ? Colors.black : Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color accent,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: terminalBorder, width: 1)),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: accent, size: 20),
        title: Text(title,
            style: GoogleFonts.jetBrainsMono(
                fontSize: 12, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle,
            style: GoogleFonts.jetBrainsMono(
                fontSize: 10, color: terminalTextSecondary)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color accent,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: accent.withValues(alpha: 0.1),
        highlightColor: accent.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: terminalBorder, width: 1)),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: isDestructive ? terminalError : accent, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color:
                            isDestructive ? terminalError : terminalTextPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 10, color: terminalTextSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: terminalTextSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _loadSampleData(BuildContext context) async {
    final accent = context.read<SettingsProvider>().accentColor;
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
                '> LOAD SAMPLE DATA?',
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 16, fontWeight: FontWeight.bold, color: accent),
              ),
              const SizedBox(height: 16),
              Text(
                'This will clear all existing data and load fresh sample plans and workouts.',
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 12, color: terminalTextSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('[CANCEL]',
                        style: GoogleFonts.jetBrainsMono(
                            color: terminalTextSecondary)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await SampleDataSeeder.clearAllData();
                      await SampleDataSeeder.seedSampleData();
                      if (context.mounted) {
                        context.read<WorkoutPlanProvider>().loadPlans();
                        context.read<WorkoutSessionProvider>().loadSessions();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('> Sample data refreshed!',
                                style: GoogleFonts.jetBrainsMono()),
                            backgroundColor: accent,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                    ),
                    child: Text('[LOAD]', style: GoogleFonts.jetBrainsMono()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClearData(BuildContext context) {
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
                '> CLEAR ALL DATA?',
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: terminalError),
              ),
              const SizedBox(height: 16),
              Text(
                'This will delete all workout plans and history. This action cannot be undone.',
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 12, color: terminalTextSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('[CANCEL]',
                        style: GoogleFonts.jetBrainsMono(
                            color: terminalTextSecondary)),
                  ),
                  const SizedBox(width: 8),
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
                          SnackBar(
                            content: Text('> All data cleared',
                                style: GoogleFonts.jetBrainsMono()),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: terminalError,
                      foregroundColor: Colors.white,
                    ),
                    child:
                        Text('[CLEAR ALL]', style: GoogleFonts.jetBrainsMono()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWeightUnitDialog(BuildContext context, SettingsProvider settings) {
    final accent = settings.accentColor;
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
                '> SELECT WEIGHT UNIT',
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 16, fontWeight: FontWeight.bold, color: accent),
              ),
              const SizedBox(height: 16),
              _buildRadioTile(
                title: 'KILOGRAMS (KG)',
                value: 'kg',
                groupValue: settings.weightUnit,
                onChanged: (value) {
                  settings.setWeightUnit(value!);
                  Navigator.pop(context);
                },
                accent: accent,
              ),
              _buildRadioTile(
                title: 'POUNDS (LBS)',
                value: 'lbs',
                groupValue: settings.weightUnit,
                onChanged: (value) {
                  settings.setWeightUnit(value!);
                  Navigator.pop(context);
                },
                accent: accent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioTile({
    required String title,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
    required Color accent,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? accent : Colors.transparent,
                border: Border.all(color: accent, width: 1),
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 14, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                color: isSelected ? accent : terminalTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color accent;

  const _SectionHeader({required this.title, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: terminalBorder, width: 1)),
      ),
      child: Row(
        children: [
          Text(
            '> $title',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
