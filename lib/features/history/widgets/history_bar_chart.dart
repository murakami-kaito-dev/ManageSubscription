import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// A generic spend bar chart used by both the monthly (12 bars) and yearly
/// views. Bars with no spend render only as a soft light track; bars with
/// spend are filled with the accent, and the selected bar is emphasized.
class HistoryBarChart extends StatelessWidget {
  const HistoryBarChart({
    super.key,
    required this.labels,
    required this.values,
    required this.selectedIndex,
    required this.onSelect,
    this.accent = AppColors.primary,
  });

  final List<String> labels;
  final List<double> values;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final maxY = values.fold<double>(0, (m, v) => v > m ? v : m);
    final safeMax = maxY <= 0 ? 1.0 : maxY * 1.25;

    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          maxY: safeMax,
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.textPrimary,
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                '¥${rod.toY.round()}',
                AppType.body(11, color: AppColors.onPrimary),
              ),
            ),
            touchCallback: (event, response) {
              if (event.isInterestedForInteractions &&
                  response?.spot != null) {
                onSelect(response!.spot!.touchedBarGroupIndex);
              }
            },
          ),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox();
                  final sel = i == selectedIndex;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(labels[i],
                        style: AppType.body(11,
                            weight: sel ? FontWeight.w800 : FontWeight.w500,
                            color: sel
                                ? AppColors.primaryDeep
                                : AppColors.textMuted)),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i],
                    width: 14,
                    color: i == selectedIndex
                        ? accent
                        : accent.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(6),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: safeMax,
                      // A very light track so empty periods stay subtle.
                      color: AppColors.shadowDark.withOpacity(0.18),
                    ),
                  ),
                ],
              ),
          ],
        ),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}
