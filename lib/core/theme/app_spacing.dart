import 'package:flutter/widgets.dart';

/// Spacing, radii and elevation tokens for the soft-UI system.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  // Radii — generous, cushion-like rounding is core to the identity.
  static const double radiusChip = 14;
  static const double radiusButton = 20;
  static const double radiusCard = 26;
  static const double radiusSheet = 34;
  static const double radiusPill = 999;

  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: lg, vertical: sm);
}

/// Convenience gap widgets to keep column/row code readable.
class Gap extends StatelessWidget {
  const Gap(this.size, {super.key});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size);
}
