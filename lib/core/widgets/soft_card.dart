import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// The workhorse surface: a cushioned, raised clay card. Optionally pressable
/// (adds the squish micro-interaction and haptic).
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.radius = AppSpacing.radiusCard,
    this.color,
    this.onTap,
    this.onLongPress,
    this.intensity = 1,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadows.raised(intensity: intensity),
      ),
      child: child,
    );

    final wrapped = margin == null ? card : Padding(padding: margin!, child: card);

    if (onTap == null && onLongPress == null) return wrapped;
    return Pressable(
      onTap: onTap,
      onLongPress: onLongPress,
      child: wrapped,
    );
  }
}

/// A recessed / inset panel — looks pressed *into* the canvas. Used for
/// progress tracks, sunken toggles and segmented backgrounds. Approximates the
/// inner-shadow look Flutter can't do natively by layering an inner gradient
/// and a subtle top highlight.
class SunkenPanel extends StatelessWidget {
  const SunkenPanel({
    super.key,
    required this.child,
    this.radius = AppSpacing.radiusPill,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.shadowDark.withOpacity(0.55),
            AppColors.surfaceSunken,
            AppColors.shadowLight.withOpacity(0.35),
          ],
          stops: const [0, 0.5, 1],
        ),
      ),
      child: child,
    );
  }
}
