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
    this.minVisible = 0,
  });

  /// 0..1
  final double value;
  final double height;
  final Color? color;
  final Color? trackColor;

  /// A floor (0..1) applied only when [value] is strictly greater than 0, so a
  /// just-started cycle still shows a visible nub instead of rendering blank.
  final double minVisible;

  @override
  Widget build(BuildContext context) {
    final fill = color ?? AppAccent.of(context).primary;
    var clamped = value.clamp(0.0, 1.0);
    if (clamped > 0 && clamped < minVisible) clamped = minVisible;
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
                // heightFactor:1 is REQUIRED — without it the childless
                // DecoratedBox gets loose vertical constraints and collapses to
                // height 0, making the fill invisible (correct width, no height).
                heightFactor: 1,
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
