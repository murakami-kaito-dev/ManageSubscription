import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A soft embossed progress track with a rounded gradient fill that eases in
/// (easeOutQuart), used on home tiles to show time-until-next-payment.
class SoftProgressBar extends StatelessWidget {
  const SoftProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.color,
    this.trackColor,
  });

  /// 0..1
  final double value;
  final double height;
  final Color? color;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final fill = color ?? AppAccent.of(context).primary;
    final clamped = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Container(color: trackColor ?? AppColors.surfaceSunken),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: clamped),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutQuart,
              builder: (context, t, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: t,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [fill.withOpacity(0.75), fill],
                    ),
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
