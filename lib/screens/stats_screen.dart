import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/workout_session.dart';
import '../providers/workout_session_provider.dart';
import '../providers/settings_provider.dart';
import '../services/cache_service.dart';
import '../theme/app_theme.dart';
import '../utils/weight_utils.dart';
import '../widgets/offline_indicator.dart';
import '../services/app_logger.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final CacheService _cacheService = CacheService();
  String? _selectedExercise;
  List<String> _exerciseNames = [];
  bool _showOverall = true;
  bool _isLoading = true;
  List<WorkoutSession> _sessions = [];

  // Cache for stats data
  Map<int, int> _workoutFrequency = {};
  Map<String, double> _exercisePRs = {};
  int _totalWorkouts = 0;
  int _workoutsThisWeek = 0;
  List<Map<String, dynamic>> _selectedExerciseProgression = [];

  @override
  void initState() {
    super.initState();
    _loadStatsData();
  }

  Future<void> _loadStatsData() async {
    try {
      final sessionProvider = context.read<WorkoutSessionProvider>();
      var sessions = List<WorkoutSession>.from(sessionProvider.sessions);

      if (sessions.isEmpty) {
        sessions = await _cacheService.getSessions();
      }

      sessions.sort((a, b) => b.date.compareTo(a.date));

      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startDate =
          DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

      final workoutFrequency = <int, int>{};
      for (int i = 0; i < 8; i++) {
        workoutFrequency[i] = 0;
      }

      final exercisePRs = <String, double>{};

      for (final session in sessions) {
        final daysDiff = now.difference(session.date).inDays;
        final weekIndex = daysDiff ~/ 7;
        if (weekIndex >= 0 && weekIndex < 8) {
          workoutFrequency[weekIndex] = (workoutFrequency[weekIndex] ?? 0) + 1;
        }

        for (final exercise in session.exercises) {
          final currentPR = exercisePRs[exercise.name] ?? 0.0;
          double maxWeightInSession = 0;
          for (final set in exercise.sets) {
            if (set.weight > maxWeightInSession) {
              maxWeightInSession = set.weight;
            }
          }
          if (maxWeightInSession > currentPR) {
            exercisePRs[exercise.name] = maxWeightInSession;
          }
        }
      }

      final exerciseNames = exercisePRs.keys.toList()..sort();
      final workoutsThisWeek =
          sessions.where((s) => s.date.isAfter(startDate)).length;

      String? selectedExercise = _selectedExercise;
      if (exerciseNames.isNotEmpty) {
        if (selectedExercise == null ||
            !exerciseNames.contains(selectedExercise)) {
          selectedExercise = exerciseNames.first;
        }
      } else {
        selectedExercise = null;
      }

      final selectedExerciseProgression =
          _buildExerciseProgression(sessions, selectedExercise);

      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _exerciseNames = exerciseNames;
        _workoutFrequency = workoutFrequency;
        _exercisePRs = exercisePRs;
        _totalWorkouts = sessions.length;
        _workoutsThisWeek = workoutsThisWeek;
        _selectedExercise = selectedExercise;
        _selectedExerciseProgression = selectedExerciseProgression;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('Error loading stats data', error: e);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _buildExerciseProgression(
      List<WorkoutSession> sessions, String? exerciseName) {
    if (exerciseName == null) {
      return [];
    }

    final progression = <Map<String, dynamic>>[];

    for (final session in sessions) {
      for (final exercise in session.exercises) {
        if (exercise.name.toLowerCase() != exerciseName.toLowerCase() ||
            exercise.sets.isEmpty) {
          continue;
        }

        double maxWeight = 0;
        int totalVolume = 0;

        for (final set in exercise.sets) {
          if (set.weight > maxWeight) {
            maxWeight = set.weight;
          }
          totalVolume += (set.weight * set.reps).round();
        }

        progression.add({
          'date': session.date,
          'maxWeight': maxWeight,
          'totalVolume': totalVolume,
          'week': session.weekNumber,
        });
      }
    }

    progression.sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    return progression;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final accent = settings.accentColor;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor(context),
        appBar: AppBar(
          backgroundColor: surfaceColor(context),
          title: Text(
            '> STATISTICS',
            style: GoogleFonts.jetBrainsMono(
                fontSize: 16, fontWeight: FontWeight.bold, color: accent),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: accent),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            const OfflineIndicator(),
          ],
        ),
        body: Center(
          child: CircularProgressIndicator(color: accent),
        ),
      );
    }

    final totalPRs = _exercisePRs.length;

    return Scaffold(
      backgroundColor: backgroundColor(context),
      appBar: AppBar(
        backgroundColor: surfaceColor(context),
        title: Text(
          '> STATISTICS',
          style: GoogleFonts.jetBrainsMono(
              fontSize: 16, fontWeight: FontWeight.bold, color: accent),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: accent),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          const OfflineIndicator(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCards(
              _totalWorkouts, _workoutsThisWeek, totalPRs, accent),
          const SizedBox(height: 24),
          _buildViewToggle(accent),
          const SizedBox(height: 16),
          if (_showOverall)
            _buildFrequencyChart(_workoutFrequency, accent)
          else
            _buildProgressionChart(accent, settings),
          const SizedBox(height: 24),
          if (!_showOverall && _exerciseNames.isNotEmpty)
            _buildExerciseSelector(accent, settings),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(int total, int thisWeek, int prs, Color accent) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'TOTAL WORKOUTS',
            value: '$total',
            accent: accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            label: 'THIS WEEK',
            value: '$thisWeek',
            accent: accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            label: 'PRS TRACKED',
            value: '$prs',
            accent: accent,
          ),
        ),
      ],
    );
  }

  Widget _buildViewToggle(Color accent) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              setState(() {
                _showOverall = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _showOverall ? accent : Colors.transparent,
                border: Border.all(color: accent, width: 1),
              ),
              child: Center(
                child: Text(
                  '[OVERALL]',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: _showOverall ? Colors.black : accent,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: () {
              setState(() {
                _showOverall = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: !_showOverall ? accent : Colors.transparent,
                border: Border.all(color: accent, width: 1),
              ),
              child: Center(
                child: Text(
                  '[EXERCISE]',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: !_showOverall ? Colors.black : accent,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseSelector(Color accent, SettingsProvider settings) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedExercise,
      decoration: const InputDecoration(
        labelText: 'SELECT EXERCISE',
        border: OutlineInputBorder(),
      ),
      items: _exerciseNames.map((name) {
        final pr = _exercisePRs[name] ?? 0.0;
        return DropdownMenuItem(
          value: name,
          child: Text(
              '$name (PR: ${WeightUtils.formatWeight(pr, settings.weightUnit)})',
              style: GoogleFonts.jetBrainsMono(fontSize: 12)),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedExercise = value;
          _selectedExerciseProgression =
              _buildExerciseProgression(_sessions, _selectedExercise);
        });
      },
    );
  }

  Widget _buildFrequencyChart(Map<int, int> frequency, Color accent) {
    final maxY = frequency.values.isEmpty
        ? 5.0
        : (frequency.values.reduce((a, b) => a > b ? a : b) + 2).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor(context),
        border: Border.all(color: borderColor(context), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '> WORKOUT FREQUENCY',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ],
            ),
            Text(
              'Last 8 Weeks',
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 10, color: textSecondaryColor(context)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final week = 8 - group.x.toInt();
                        return BarTooltipItem(
                          'Week $week\n${rod.toY.toInt()} workouts',
                          GoogleFonts.jetBrainsMono(
                              fontSize: 10, color: textPrimaryColor(context)),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final week = 8 - value.toInt();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'W$week',
                              style: GoogleFonts.jetBrainsMono(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: GoogleFonts.jetBrainsMono(fontSize: 11),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: borderColor(context),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  barGroups: List.generate(8, (index) {
                    final count = frequency[index] ?? 0;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          color: accent,
                          width: 20,
                          borderRadius: BorderRadius.zero,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressionChart(Color accent, SettingsProvider settings) {
    if (_selectedExercise == null) {
      return Container(
        decoration: BoxDecoration(
          color: surfaceColor(context),
          border: Border.all(color: borderColor(context), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              '> No exercise data available',
              style:
                  GoogleFonts.jetBrainsMono(color: textSecondaryColor(context)),
            ),
          ),
        ),
      );
    }

    final progression = _selectedExerciseProgression;

    if (progression.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: surfaceColor(context),
          border: Border.all(color: borderColor(context), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Text(
                  '> No data for $_selectedExercise',
                  style: GoogleFonts.jetBrainsMono(
                      color: textSecondaryColor(context)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final maxWeight = progression
        .map((p) => p['maxWeight'] as double)
        .reduce((a, b) => a > b ? a : b);
    final spots = progression.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value['maxWeight'] as double);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor(context),
        border: Border.all(color: borderColor(context), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '> ${_selectedExercise!.toUpperCase()} PROGRESSION',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            Text(
              'Max Weight Over Time',
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 10, color: textSecondaryColor(context)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxWeight + 10,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final data = progression[spot.x.toInt()];
                          final date = data['date'] as DateTime;
                          return LineTooltipItem(
                            '${date.day}/${date.month}\n${WeightUtils.formatWeight(spot.y, settings.weightUnit)}',
                            GoogleFonts.jetBrainsMono(fontSize: 11),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= progression.length) {
                            return Text('');
                          }
                          final date =
                              progression[value.toInt()]['date'] as DateTime;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${date.day}/${date.month}',
                              style: GoogleFonts.jetBrainsMono(fontSize: 11),
                            ),
                          );
                        },
                        interval: (progression.length / 5).ceil().toDouble(),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: GoogleFonts.jetBrainsMono(fontSize: 11),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: borderColor(context),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      color: accent,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: accent,
                            strokeWidth: 2,
                            strokeColor: surfaceColor(context),
                          );
                        },
                      ),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'CURRENT PR',
                  value: WeightUtils.formatWeight(
                      progression.last['maxWeight'], settings.weightUnit),
                  accent: accent,
                ),
                _StatItem(
                  label: 'SESSIONS',
                  value: '${progression.length}',
                  accent: accent,
                ),
                _StatItem(
                  label: 'PROGRESS',
                  value: _calculateProgress(progression, settings),
                  accent: accent,
                  valueColor: _getProgressColor(progression),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _calculateProgress(
      List<Map<String, dynamic>> progression, SettingsProvider settings) {
    if (progression.length < 2) return '-';
    final first = progression.first['maxWeight'] as double;
    final last = progression.last['maxWeight'] as double;
    if (first == 0) return '-';
    final diff = last - first;
    final sign = diff >= 0 ? '+' : '';
    return '$sign${WeightUtils.formatWeight(diff.abs(), settings.weightUnit)}';
  }

  Color _getProgressColor(List<Map<String, dynamic>> progression) {
    if (progression.length < 2) return textSecondaryColor(context);
    final first = progression.first['maxWeight'] as double;
    final last = progression.last['maxWeight'] as double;
    if (last > first) return Colors.green;
    if (last < first) return errorColor(context);
    return textSecondaryColor(context);
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor(context),
        border: Border.all(color: borderColor(context), width: 1),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
                fontSize: 10, color: textSecondaryColor(context)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final Color? valueColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.accent,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor ?? accent,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
              fontSize: 10, color: textSecondaryColor(context)),
        ),
      ],
    );
  }
}
