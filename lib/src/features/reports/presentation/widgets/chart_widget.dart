import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_motion.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/theme/app_surface_tokens.dart';

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
                final sliceColor = item.resolveColor(context);
                return PieChartSectionData(
                  value: item.value,
                  title: showLabel
                      ? '${item.percentage.toStringAsFixed(1)}%'
                      : '',
                  color: sliceColor,
                  radius: sectionRadius,
                  titlePositionPercentageOffset: 0.6,
                  titleStyle: TextStyle(
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.bold,
                    color: pieLabelColor(sliceColor),
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: centerSpaceRadius,
            ),
            swapAnimationDuration: AppMotion.of(
              context,
              PieChart.defaultDuration,
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

    final axisStyle = TextStyle(
      fontSize: 10,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    final maxY = data.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    double measure(double v) {
      final painter = TextPainter(
        text: TextSpan(text: labelFormatter(v), style: axisStyle),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final w = painter.width;
      painter.dispose();
      return w;
    }

    // Widest plausible tick is the max value; add side padding.
    final leftReserved = [measure(0), measure(maxY), measure(maxY / 2)]
            .reduce((a, b) => a > b ? a : b)
            .ceilToDouble() +
        8;

    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barGroups: data.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  color: entry.value.resolveColor(context),
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusXs),
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
                        style: axisStyle,
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
                reservedSize: leftReserved,
                getTitlesWidget: (value, meta) {
                  // Drop the irregular auto-added max endpoint when it is not
                  // on the interval grid; it sits too close to the last tick.
                  final interval = meta.appliedInterval;
                  if (interval > 0 && value == meta.max) {
                    final steps = value / interval;
                    if ((steps - steps.roundToDouble()).abs() > 0.01) {
                      return const SizedBox.shrink();
                    }
                  }
                  return Text(
                    labelFormatter(value),
                    style: axisStyle,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
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
        swapAnimationDuration: AppMotion.of(context, AppMotion.fast),
      ),
    );
  }
}

class ChartData {
  final String label;
  final double value;
  final double percentage;
  /// Explicit slice/bar color. When null the widgets fall back to the theme
  /// primary (see [resolveColor]).
  final Color? color;

  ChartData({
    required this.label,
    required this.value,
    double? percentage,
    this.color,
  }) : percentage = percentage ?? value;

  Color resolveColor(BuildContext context) =>
      color ?? Theme.of(context).colorScheme.primary;
}

/// Pie label color: white/black chosen by slice luminance, then pushed until
/// it reaches 4.5:1 against the slice fill.
Color pieLabelColor(Color slice) {
  final dark = ThemeData.estimateBrightnessForColor(slice) == Brightness.dark;
  return AppSurfaceTokens.ensureContrast(
    dark ? AppColors.textLight : AppColors.textDark,
    slice,
    toward: dark ? Colors.white : Colors.black,
  );
}
