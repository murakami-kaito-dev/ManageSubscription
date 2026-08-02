import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/analytics_providers.dart';

/// 12-month spend bars. The selected month is highlighted; empty/future months
/// render as soft sunken tracks so the chart reads even with sparse data.
class HistoryBarChart extends StatelessWidget {
  const HistoryBarChart({
    super.key,
    required this.data,
    required this.selectedMonth,
    required this.onSelect,
  });

  final List<MonthlySpend> data;
  final int selectedMonth; // 1..12
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final maxY = data.fold<double>(0, (m, e) => e.amount > m ? e.amount : m);
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
                onSelect(response!.spot!.touchedBarGroupIndex + 1);
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
                  final m = value.toInt() + 1;
                  final sel = m == selectedMonth;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('$m',
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
            for (var i = 0; i < data.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i].amount,
                    width: 14,
                    color: (i + 1) == selectedMonth
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: safeMax,
                      color: AppColors.surfaceSunken,
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
