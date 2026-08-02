import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light({Color? accent}) {
    final Color primary = accent ?? AppColors.primary;
    final base = ThemeData.light(useMaterial3: true);

    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      surface: AppColors.surface,
      onPrimary: AppColors.onPrimary,
      onSurface: AppColors.textPrimary,
    );

    return base.copyWith(
      colorScheme: scheme,
      extensions: <ThemeExtension<dynamic>>[AppAccent.from(primary)],
      scaffoldBackgroundColor: AppColors.canvas,
      canvasColor: AppColors.canvas,
      textTheme: AppType.textTheme(base.textTheme),
      splashFactory: InkRipple.splashFactory,
      splashColor: primary.withOpacity(0.06),
      highlightColor: Colors.transparent,
      dividerTheme: const DividerThemeData(
        color: Color(0x14000000),
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppType.display(19, weight: FontWeight.w800),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusSheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppType.body(14, color: AppColors.onPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.onPrimary
              : const Color(0xFFF4F1EB),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? primary
              : AppColors.surfaceSunken,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    );
  }
}
