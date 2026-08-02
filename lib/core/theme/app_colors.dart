import 'package:flutter/material.dart';

/// The live accent trio (primary / deep / soft) derived from the user's chosen
/// theme color. Widgets read `AppAccent.of(context)` instead of the fixed
/// [AppColors.primary] so the whole app re-themes when the color changes.
@immutable
class AppAccent extends ThemeExtension<AppAccent> {
  const AppAccent(
      {required this.primary, required this.deep, required this.soft});

  final Color primary;
  final Color deep;
  final Color soft;

  static AppAccent from(Color c) {
    final h = HSLColor.fromColor(c);
    return AppAccent(
      primary: c,
      deep: h
          .withLightness((h.lightness - 0.13).clamp(0.0, 1.0))
          .toColor(),
      soft: h
          .withSaturation((h.saturation * 0.55).clamp(0.0, 1.0))
          .withLightness((h.lightness + 0.30).clamp(0.0, 0.92))
          .toColor(),
    );
  }

  /// Falls back to the default sage accent if no theme extension is present.
  static AppAccent of(BuildContext context) =>
      Theme.of(context).extension<AppAccent>() ??
      AppAccent.from(AppColors.primary);

  @override
  AppAccent copyWith({Color? primary, Color? deep, Color? soft}) => AppAccent(
        primary: primary ?? this.primary,
        deep: deep ?? this.deep,
        soft: soft ?? this.soft,
      );

  @override
  AppAccent lerp(ThemeExtension<AppAccent>? other, double t) {
    if (other is! AppAccent) return this;
    return AppAccent(
      primary: Color.lerp(primary, other.primary, t)!,
      deep: Color.lerp(deep, other.deep, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
    );
  }
}

/// Design language: "Elegant Soft UI / Claymorphism".
///
/// A warm, tactile canvas — the opposite of the flat blue-on-white reference.
/// The base canvas is a warm pale sand-grey chosen so that a *pair* of soft
/// shadows (a light one top-left, a warm dark one bottom-right) both read,
/// giving every surface a cushioned, pressable feel.
class AppColors {
  AppColors._();

  // ── Canvas & surfaces ────────────────────────────────────────────────
  /// App background — warm pale sand-grey.
  static const Color canvas = Color(0xFFECE9E2);

  /// Raised card surface — slightly lighter than the canvas.
  static const Color surface = Color(0xFFF4F1EB);

  /// Recessed / inset surface (progress tracks, pressed states).
  static const Color surfaceSunken = Color(0xFFE4E0D7);

  // ── Neumorphic shadow pair ───────────────────────────────────────────
  static const Color shadowLight = Color(0xFFFFFFFF);
  static const Color shadowDark = Color(0xFFCBC3B5);

  // ── Brand accents ────────────────────────────────────────────────────
  /// Primary — a calm, grounded sage green.
  static const Color primary = Color(0xFF6E9080);
  static const Color primaryDeep = Color(0xFF546C60);
  static const Color primarySoft = Color(0xFFDCE6DE);

  /// Secondary — a warm muted coral used sparingly for emphasis.
  static const Color coral = Color(0xFFE1836B);
  static const Color coralSoft = Color(0xFFF6DED5);

  /// Premium — a refined muted gold (the crown).
  static const Color gold = Color(0xFFD9A34C);
  static const Color goldSoft = Color(0xFFF3E4C4);

  // ── Text ─────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF3B3A36);
  static const Color textSecondary = Color(0xFF857F73);
  static const Color textMuted = Color(0xFFB1AB9F);
  static const Color onPrimary = Color(0xFFF8F6F0);

  // ── Status ───────────────────────────────────────────────────────────
  static const Color danger = Color(0xFFCF6A5B);
  static const Color success = Color(0xFF6E9080);
  static const Color paused = Color(0xFFB1AB9F);

  // ── Premium hero gradient (paywall banner) ───────────────────────────
  static const List<Color> premiumGradient = [
    Color(0xFF7BA890),
    Color(0xFF5E8AA6),
  ];

  /// Harmonious, muted categorical palette for charts. Deliberately soft so
  /// slices sit calmly on the warm canvas instead of shouting like the
  /// reference's saturated primaries.
  static const List<Color> chartPalette = [
    Color(0xFF7FA38C), // sage
    Color(0xFFE5977E), // coral
    Color(0xFFE3C27E), // dusty gold
    Color(0xFF86A9C4), // dusty blue
    Color(0xFFC39BB4), // mauve
    Color(0xFFA9B583), // olive
    Color(0xFFCE8B6A), // terracotta
    Color(0xFF7FB3AD), // teal
    Color(0xFFB6A2CB), // lavender
    Color(0xFFD9B48A), // sand
  ];

  static Color chartColor(int index) =>
      chartPalette[index % chartPalette.length];
}
