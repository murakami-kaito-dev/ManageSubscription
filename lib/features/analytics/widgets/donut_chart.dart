import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/animated_counter.dart';
import '../../../providers/analytics_providers.dart';

/// Donut breakdown with a soft center label showing the grand total.
class DonutChart extends StatefulWidget {
  const DonutChart({
    super.key,
    required this.slices,
    required this.total,
    required this.formatter,
    this.onLongPressSlice,
  });

  final List<AnalyticsSlice> slices;
  final double total;
  final CurrencyFormatter formatter;

  /// Long-pressing a slice drills into its breakdown.
  final ValueChanged<int>? onLongPressSlice;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
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
                  setState(() => _touched = i);
                  if (event is FlLongPressStart &&
                      i >= 0 &&
                      i < widget.slices.length) {
                    widget.onLongPressSlice?.call(i);
                  }
                },
              ),
              sections: [
                for (var i = 0; i < widget.slices.length; i++)
                  _section(widget.slices[i], i == _touched),
              ],
            ),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('合計',
                  style: AppType.body(13, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              AnimatedCounter(
                value: widget.total,
                formatter: (v) => widget.formatter.format(v),
                style: AppType.display(26),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PieChartSectionData _section(AnalyticsSlice s, bool touched) {
    final pct = widget.total <= 0 ? 0 : (s.amount / widget.total * 100);
    return PieChartSectionData(
      value: s.amount <= 0 ? 0.0001 : s.amount,
      color: s.color,
      radius: touched ? 62 : 54,
      title: pct >= 7 ? s.label : '',
      titleStyle: AppType.body(11,
          weight: FontWeight.w700, color: Colors.white.withOpacity(0.95)),
      titlePositionPercentageOffset: 0.62,
    );
  }
}
