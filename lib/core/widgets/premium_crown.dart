import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The small gold crown that marks a premium-gated control (👑 in the refs).
class PremiumCrown extends StatelessWidget {
  const PremiumCrown({super.key, this.size = 16});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.workspace_premium_rounded,
        size: size, color: AppColors.gold);
  }
}

/// A soft pill label, e.g. "PREMIUM".
class SoftPill extends StatelessWidget {
  const SoftPill({
    super.key,
    required this.label,
    this.color = AppColors.primary,
    this.background,
  });

  final String label;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: color,
        ),
      ),
    );
  }
}
