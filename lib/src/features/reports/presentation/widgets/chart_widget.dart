import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';

class PieChartWidget extends StatelessWidget {
  final List<ChartData> data;
  final String? title;

  /// Slices thinner than this are left unlabelled: the text would not fit
  /// inside the arc and would spill over the neighbouring slices.
  static const double _minLabelPercentage = 5;

  const PieChartWidget({
    super.key,
    required this.data,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.noData),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // The chart must fit the box it is given; a fixed radius overflows on
        // narrow phones, which is what clipped the old chart.
        final width = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : 280.0;
        final diameter = math.min(width, 260.0);
        final centerSpaceRadius = diameter * 0.18;
        final sectionRadius = diameter / 2 - centerSpaceRadius;
        final labelFontSize = math.max(10.0, sectionRadius * 0.2);

        return SizedBox(
          height: diameter,
          child: PieChart(
            PieChartData(
              sections: data.map((item) {
                final showLabel = item.percentage >= _minLabelPercentage;
                return PieChartSectionData(
                  value: item.value,
                  title: showLabel
                      ? '${item.percentage.toStringAsFixed(1)}%'
                      : '',
                  color: item.color,
                  radius: sectionRadius,
                  titlePositionPercentageOffset: 0.6,
                  titleStyle: TextStyle(
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: centerSpaceRadius,
            ),
          ),
        );
      },
    );
  }
}

class BarChartWidget extends StatelessWidget {
  final List<ChartData> data;
  final String Function(double) labelFormatter;

  const BarChartWidget({
    super.key,
    required this.data,
    required this.labelFormatter,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.noData),
      );
    }

    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: data.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
          barGroups: data.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  color: entry.value.color,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < data.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        data[value.toInt()].label,
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    labelFormatter(value),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

class ChartData {
  final String label;
  final double value;
  final double percentage;
  final Color color;

  ChartData({
    required this.label,
    required this.value,
    double? percentage,
    Color? color,
  })  : percentage = percentage ?? value,
        color = color ?? Colors.blue;
}
