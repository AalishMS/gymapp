import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/hive_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String? _selectedExercise;
  List<String> _exerciseNames = [];
  bool _showOverall = true;

  @override
  void initState() {
    super.initState();
    _loadExerciseNames();
  }

  void _loadExerciseNames() {
    _exerciseNames = HiveService.getAllExerciseNames();
    if (_exerciseNames.isNotEmpty) {
      _selectedExercise = _exerciseNames.first;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final frequency = HiveService.getWorkoutFrequency(8);
    final totalWorkouts = HiveService.getSessions().length;
    final workoutsThisWeek = HiveService.getWorkoutsThisWeek();
    final prs = HiveService.getAllExercisePRs();
    final totalPRs = prs.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCards(totalWorkouts, workoutsThisWeek, totalPRs),
          const SizedBox(height: 24),
          _buildViewToggle(),
          const SizedBox(height: 16),
          if (_showOverall)
            _buildFrequencyChart(frequency)
          else
            _buildProgressionChart(),
          const SizedBox(height: 24),
          if (!_showOverall && _exerciseNames.isNotEmpty)
            _buildExerciseSelector(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(int total, int thisWeek, int prs) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.fitness_center,
            label: 'Total Workouts',
            value: '$total',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            icon: Icons.calendar_today,
            label: 'This Week',
            value: '$thisWeek',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            icon: Icons.emoji_events,
            label: 'PRs Tracked',
            value: '$prs',
            color: Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildViewToggle() {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(
          value: true,
          label: Text('Overall'),
          icon: Icon(Icons.bar_chart),
        ),
        ButtonSegment(
          value: false,
          label: Text('Exercise'),
          icon: Icon(Icons.show_chart),
        ),
      ],
      selected: {_showOverall},
      onSelectionChanged: (selection) {
        setState(() {
          _showOverall = selection.first;
        });
      },
    );
  }

  Widget _buildExerciseSelector() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedExercise,
      decoration: const InputDecoration(
        labelText: 'Select Exercise',
        border: OutlineInputBorder(),
      ),
      items: _exerciseNames.map((name) {
        final pr = HiveService.getExercisePR(name);
        return DropdownMenuItem(
          value: name,
          child: Text('$name (PR: ${pr}kg)'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedExercise = value;
        });
      },
    );
  }

  Widget _buildFrequencyChart(Map<int, int> frequency) {
    final maxY = frequency.values.isEmpty
        ? 5.0
        : (frequency.values.reduce((a, b) => a > b ? a : b) + 2).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workout Frequency (Last 8 Weeks)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                          const TextStyle(color: Colors.white),
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
                              style: const TextStyle(fontSize: 10),
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
                            style: const TextStyle(fontSize: 10),
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
                  ),
                  barGroups: List.generate(8, (index) {
                    final count = frequency[index] ?? 0;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          color: Theme.of(context).colorScheme.primary,
                          width: 24,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
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

  Widget _buildProgressionChart() {
    if (_selectedExercise == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No exercise data available',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final progression = HiveService.getExerciseProgression(_selectedExercise!);

    if (progression.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.show_chart, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No data for $_selectedExercise',
                  style: const TextStyle(color: Colors.grey),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_selectedExercise Progression',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Max Weight Over Time',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                            '${date.day}/${date.month}\n${spot.y}kg',
                            const TextStyle(color: Colors.white),
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
                            return const Text('');
                          }
                          final date =
                              progression[value.toInt()]['date'] as DateTime;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${date.day}/${date.month}',
                              style: const TextStyle(fontSize: 10),
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
                            style: const TextStyle(fontSize: 10),
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
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Theme.of(context).colorScheme.primary,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                      ),
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
                  label: 'Current PR',
                  value: '${progression.last['maxWeight']}kg',
                ),
                _StatItem(
                  label: 'Sessions',
                  value: '${progression.length}',
                ),
                _StatItem(
                  label: 'Progress',
                  value: _calculateProgress(progression),
                  color: _getProgressColor(progression),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _calculateProgress(List<Map<String, dynamic>> progression) {
    if (progression.length < 2) return '-';
    final first = progression.first['maxWeight'] as double;
    final last = progression.last['maxWeight'] as double;
    if (first == 0) return '-';
    final diff = last - first;
    final sign = diff >= 0 ? '+' : '';
    return '$sign${diff.toStringAsFixed(1)}kg';
  }

  Color _getProgressColor(List<Map<String, dynamic>> progression) {
    if (progression.length < 2) return Colors.grey;
    final first = progression.first['maxWeight'] as double;
    final last = progression.last['maxWeight'] as double;
    if (last > first) return Colors.green;
    if (last < first) return Colors.red;
    return Colors.grey;
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color == Colors.white
                ? Theme.of(context).colorScheme.primary
                : color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}
