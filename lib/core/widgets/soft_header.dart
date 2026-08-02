import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'soft_button.dart';

/// The screen header used across Home / Analytics / Calendar / History: a soft
/// round gear on the left, a centered title, and an optional trailing action.
class SoftHeader extends StatelessWidget {
  const SoftHeader({
    super.key,
    required this.title,
    this.onSettings,
    this.trailing,
    this.subtitle,
  });

  final String title;
  final VoidCallback? onSettings;
  final Widget? trailing;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: onSettings == null
                      ? const SizedBox(width: 44)
                      : SoftIconButton(
                          icon: Icons.settings_rounded, onTap: onSettings),
                ),
                Text(title, style: AppType.display(20, weight: FontWeight.w800)),
                Align(
                  alignment: Alignment.centerRight,
                  child: trailing ?? const SizedBox(width: 44),
                ),
              ],
            ),
          ),
          if (subtitle != null) ...[const Gap(AppSpacing.xs), subtitle!],
        ],
      ),
    );
  }
}
