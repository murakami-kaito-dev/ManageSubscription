import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'pressable.dart';

enum SoftButtonKind { primary, coral, neutral, ghost, danger }

/// Primary call-to-action button with the shared press-squish, a tinted glow
/// for accent kinds, and an optional leading icon.
class SoftButton extends StatelessWidget {
  const SoftButton({
    super.key,
    required this.label,
    this.onPressed,
    this.kind = SoftButtonKind.primary,
    this.icon,
    this.expand = true,
    this.height = 56,
    this.accent,
  });

  final String label;
  final VoidCallback? onPressed;
  final SoftButtonKind kind;
  final IconData? icon;
  final bool expand;
  final double height;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final primary = accent ?? AppColors.primary;

    late final Color bg;
    late final Color fg;
    List<BoxShadow> shadow;
    switch (kind) {
      case SoftButtonKind.primary:
        bg = primary;
        fg = AppColors.onPrimary;
        shadow = AppShadows.accentGlow(primary);
        break;
      case SoftButtonKind.coral:
        bg = AppColors.coral;
        fg = AppColors.onPrimary;
        shadow = AppShadows.accentGlow(AppColors.coral);
        break;
      case SoftButtonKind.neutral:
        bg = AppColors.surface;
        fg = AppColors.textPrimary;
        shadow = AppShadows.soft();
        break;
      case SoftButtonKind.ghost:
        bg = Colors.transparent;
        fg = primary;
        shadow = const [];
        break;
      case SoftButtonKind.danger:
        bg = AppColors.danger.withOpacity(0.12);
        fg = AppColors.danger;
        shadow = const [];
        break;
    }

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: fg, size: 20),
          const Gap(AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppType.body(16, weight: FontWeight.w700, color: fg),
          ),
        ),
      ],
    );

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Pressable(
        enabled: enabled,
        onTap: onPressed,
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(
              horizontal: expand ? AppSpacing.lg : AppSpacing.xl),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
            boxShadow: enabled ? shadow : const [],
          ),
          child: content,
        ),
      ),
    );
  }
}

/// A round, softly-raised icon button used for the header gear / overflow.
class SoftIconButton extends StatelessWidget {
  const SoftIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 44,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: AppShadows.soft(),
        ),
        child: Icon(icon, size: size * 0.46, color: iconColor ?? AppColors.textPrimary),
      ),
    );
  }
}
