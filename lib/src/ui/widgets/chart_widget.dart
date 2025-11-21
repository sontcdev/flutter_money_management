// path: lib/src/ui/widgets/chart_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/report_service.dart';
import '../../theme/app_colors.dart';

class ChartWidget extends StatelessWidget {
  final List<CategoryBreakdown> breakdown;
  final ChartType type;

  const ChartWidget({
    super.key,
    required this.breakdown,
    this.type = ChartType.donut,
  });

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data')),
      );
    }

    switch (type) {
      case ChartType.donut:
        return _buildDonutChart();
      case ChartType.bar:
        return _buildBarChart();
    }
  }

  Widget _buildDonutChart() {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: breakdown.map((item) {
            final color = _getColorForIndex(breakdown.indexOf(item));
            return PieChartSectionData(
              value: item.percentage,
              title: '${item.percentage.toStringAsFixed(1)}%',
              color: color,
              radius: 50,
            );
          }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < breakdown.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        breakdown[value.toInt()].categoryName,
                        style: const TextStyle(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: breakdown.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: item.percentage,
                  color: _getColorForIndex(index),
                  width: 20,
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.warning,
      AppColors.error,
      AppColors.success,
    ];
    return colors[index % colors.length];
  }
}

enum ChartType {
  donut,
  bar,
}

