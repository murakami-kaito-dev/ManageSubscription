import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/animated_counter.dart';
import '../../../providers/analytics_providers.dart';

/// Donut breakdown. Tapping a slice selects it (the center then shows that
/// item's name + share %, and the caller highlights its list row); tapping it
/// again clears the selection. Long-pressing a slice drills in.
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.slices,
    required this.total,
    required this.formatter,
    required this.selectedIndex,
    required this.onTapSlice,
    this.onLongPressSlice,
  });

  final List<AnalyticsSlice> slices;
  final double total;
  final CurrencyFormatter formatter;

  /// Currently selected slice, or -1 for none.
  final int selectedIndex;

  /// Tap toggles selection; the caller decides how to fold it in.
  final ValueChanged<int> onTapSlice;

  /// Long-pressing a slice drills into its breakdown.
  final ValueChanged<int>? onLongPressSlice;

  @override
  Widget build(BuildContext context) {
    final hasSelection =
        selectedIndex >= 0 && selectedIndex < slices.length;
    final selected = hasSelection ? slices[selectedIndex] : null;
    final pct = (selected != null && total > 0 && total.isFinite)
        ? (selected.amount / total * 100)
        : 0.0;

    return AspectRatio(
      aspectRatio: 1.15,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 78,
              startDegreeOffset: -90,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  final i =
                      response?.touchedSection?.touchedSectionIndex ?? -1;
                  if (i < 0 || i >= slices.length) return;
                  if (event is FlTapUpEvent) {
                    onTapSlice(i);
                  } else if (event is FlLongPressStart) {
                    onLongPressSlice?.call(i);
                  }
                },
              ),
              sections: [
                for (var i = 0; i < slices.length; i++)
                  _section(slices[i], i == selectedIndex),
              ],
            ),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(selected.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style:
                          AppType.body(14, weight: FontWeight.w700)),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  width: 140,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(formatter.format(selected.amount),
                        style: AppType.display(24)),
                  ),
                ),
                Text('(${pct.toStringAsFixed(1)}%)',
                    style: AppType.body(13, color: AppColors.textSecondary)),
              ] else ...[
                Text('合計',
                    style: AppType.body(13, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                SizedBox(
                  width: 140,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AnimatedCounter(
                      value: total,
                      formatter: (v) => formatter.format(v),
                      style: AppType.display(26),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  PieChartSectionData _section(AnalyticsSlice s, bool selected) {
    final pct = (total <= 0 || !total.isFinite) ? 0 : (s.amount / total * 100);
    // Guard against non-finite values so the chart always renders.
    final safeValue = (s.amount.isFinite && s.amount > 0) ? s.amount : 0.0001;
    return PieChartSectionData(
      value: safeValue,
      color: s.color,
      radius: selected ? 62 : 54,
      title: pct >= 7 ? s.label : '',
      // Fixed black label for legibility on any slice color.
      titleStyle: AppType.body(11,
          weight: FontWeight.w700, color: Colors.black87),
      titlePositionPercentageOffset: 0.62,
    );
  }
}
