import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'premium_crown.dart';

/// Small grouping label above a settings/list section.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.label, {super.key, this.premium = false, this.trailing});
  final String label;
  final bool premium;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xs, AppSpacing.lg, AppSpacing.xs, AppSpacing.sm),
      child: Row(
        children: [
          Text(
            label,
            style: AppType.body(13,
                weight: FontWeight.w700, color: AppColors.textSecondary),
          ),
          if (premium) ...[const Gap(6), const PremiumCrown(size: 15)],
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A soft empty-state block (invitation to act, per the design writing rules).
class SoftEmptyState extends StatelessWidget {
  const SoftEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: AppColors.primaryDeep),
            ),
            const Gap(AppSpacing.lg),
            Text(title,
                style: AppType.display(19), textAlign: TextAlign.center),
            const Gap(AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppType.body(14, color: AppColors.textSecondary, height: 1.5),
            ),
            if (action != null) ...[const Gap(AppSpacing.xl), action!],
          ],
        ),
      ),
    );
  }
}
