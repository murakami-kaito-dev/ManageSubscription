import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// The signature of this design: paired soft shadows that lift a surface off
/// the warm canvas like a pressed clay cushion. A cool white highlight up and
/// to the left, a warm taupe shadow down and to the right.
class AppShadows {
  AppShadows._();

  /// Standard raised card.
  static List<BoxShadow> raised({double intensity = 1}) => [
        BoxShadow(
          color: AppColors.shadowDark.withOpacity(0.7 * intensity),
          offset: const Offset(7, 8),
          blurRadius: 16,
          spreadRadius: -3,
        ),
        BoxShadow(
          color: AppColors.shadowLight.withOpacity(0.95 * intensity),
          offset: const Offset(-7, -7),
          blurRadius: 14,
          spreadRadius: -3,
        ),
      ];

  /// Smaller, tighter lift for chips and compact tiles.
  static List<BoxShadow> soft({double intensity = 1}) => [
        BoxShadow(
          color: AppColors.shadowDark.withOpacity(0.45 * intensity),
          offset: const Offset(4, 5),
          blurRadius: 10,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: AppColors.shadowLight.withOpacity(0.85 * intensity),
          offset: const Offset(-4, -4),
          blurRadius: 8,
          spreadRadius: -2,
        ),
      ];

  /// A tinted glow used behind accent (primary/coral) buttons.
  static List<BoxShadow> accentGlow(Color color, {double intensity = 1}) => [
        BoxShadow(
          color: color.withOpacity(0.38 * intensity),
          offset: const Offset(0, 8),
          blurRadius: 18,
          spreadRadius: -4,
        ),
      ];
}
