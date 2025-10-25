import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PercentileBarChart extends StatelessWidget {
  final List<double> allScores;
  final double userScore;
  final double totalMarks;

  const PercentileBarChart({
    super.key,
    required this.allScores,
    required this.userScore,
    required this.totalMarks,
  });

  @override
  Widget build(BuildContext context) {
    if (allScores.isEmpty || totalMarks == 0) {
      return const SizedBox.shrink();
    }

    // Calculate percentages
    final percentageScores = allScores.map((s) => (s / totalMarks) * 100).toList();
    percentageScores.sort();
    final userPercentage = (userScore / totalMarks) * 100;

    // Calculate percentile
    final numPeopleBelow = percentageScores.where((score) => score < userPercentage).length;
    final percentile = allScores.length > 0 ? (numPeopleBelow / allScores.length) * 100 : 0.0;

    // Find user's position in sorted scores
    final userIndex = percentageScores.indexWhere((s) => s >= userPercentage);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You stand here:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            if (percentile > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Better than ${percentile.toStringAsFixed(1)}% of test takers',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  minY: 0,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        if (groupIndex == userIndex) {
                          return BarTooltipItem(
                            'Your score\n${userPercentage.toStringAsFixed(1)}%\n(Better than ${percentile.toStringAsFixed(1)}%)',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                        return BarTooltipItem(
                          '${percentageScores[groupIndex].toStringAsFixed(1)}%',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text(
                        'Students (sorted by score)',
                        style: TextStyle(fontSize: 12),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          // Show only a few labels to avoid crowding
                          if (value.toInt() % (percentageScores.length ~/ 5 + 1) == 0) {
                            return Text(
                              (value.toInt() + 1).toString(),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text(
                        'Score (%)',
                        style: TextStyle(fontSize: 12),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() % 20 == 0) {
                            return Text(
                              '${value.toInt()}',
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withValues(alpha: 0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    percentageScores.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: percentageScores[index],
                          color: index == userIndex
                              ? Colors.orange
                              : Colors.blue.withValues(alpha: 0.6),
                          width: percentageScores.length > 20 ? 4 : 8,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  color: Colors.blue.withValues(alpha: 0.6),
                  label: 'Other Scores',
                ),
                const SizedBox(width: 16),
                _buildLegendItem(
                  color: Colors.orange,
                  label: 'Your Score',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
