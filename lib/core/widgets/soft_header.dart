import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'soft_button.dart';

/// The screen header used across Home / Analytics / Calendar / History: a
/// centered title, an optional left action ([leading]), and the settings gear
/// on the RIGHT ([onSettings]). When [onSettings] is null the right slot shows
/// [trailing] instead (e.g. a close button).
class SoftHeader extends StatelessWidget {
  const SoftHeader({
    super.key,
    required this.title,
    this.onSettings,
    this.leading,
    this.trailing,
    this.subtitle,
  });

  final String title;

  /// Renders the settings gear in the RIGHT slot.
  final VoidCallback? onSettings;

  /// Custom left-slot widget (e.g. a back button or a menu action).
  final Widget? leading;

  /// Custom right-slot widget. Ignored when [onSettings] is provided.
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
                  child: leading ?? const SizedBox(width: 44),
                ),
                Text(title, style: AppType.display(20, weight: FontWeight.w800)),
                Align(
                  alignment: Alignment.centerRight,
                  child: onSettings != null
                      ? SoftIconButton(
                          icon: Icons.settings_rounded, onTap: onSettings)
                      : (trailing ?? const SizedBox(width: 44)),
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
