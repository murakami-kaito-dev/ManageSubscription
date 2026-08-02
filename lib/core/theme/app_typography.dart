import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Type system.
///
/// Pairing chosen for this brief specifically — not a neutral default:
/// * Display & money figures use **M PLUS Rounded 1c**, a warm rounded gothic
///   with full Japanese coverage that echoes the cushioned clay surfaces, so
///   prices read friendly rather than clinical.
/// * Body & UI use **Zen Kaku Gothic New**, a crisp humanist JP gothic that
///   keeps long labels legible against the rounded display face.
class AppType {
  AppType._();

  static TextStyle display(double size,
          {FontWeight weight = FontWeight.w800, Color? color, double? height}) =>
      GoogleFonts.mPlusRounded1c(
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color ?? AppColors.textPrimary,
        letterSpacing: -0.2,
      );

  static TextStyle body(double size,
          {FontWeight weight = FontWeight.w500, Color? color, double? height}) =>
      GoogleFonts.zenKakuGothicNew(
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color ?? AppColors.textPrimary,
      );

  static TextTheme textTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: display(34, height: 1.1),
      displayMedium: display(28, height: 1.15),
      headlineMedium: display(24),
      headlineSmall: display(20),
      titleLarge: display(18, weight: FontWeight.w700),
      titleMedium: body(16, weight: FontWeight.w700),
      titleSmall: body(14, weight: FontWeight.w700),
      bodyLarge: body(16),
      bodyMedium: body(14),
      bodySmall: body(12, color: AppColors.textSecondary),
      labelLarge: body(14, weight: FontWeight.w700),
      labelMedium: body(12, weight: FontWeight.w600, color: AppColors.textSecondary),
      labelSmall: body(11, weight: FontWeight.w600, color: AppColors.textMuted),
    );
  }
}
