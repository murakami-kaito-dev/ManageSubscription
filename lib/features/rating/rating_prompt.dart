import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/pressable.dart';
import '../../providers/core_providers.dart';
import '../settings/feedback_sheet.dart';

/// Shows the one-time review prompt (native-style: tap a star to rate). Skippable
/// via "今はしない"; comments are a separate action that opens the feedback form.
Future<void> showRatingPrompt(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _RatingDialog(ref: ref),
  );
}

class _RatingDialog extends StatefulWidget {
  const _RatingDialog({required this.ref});
  final WidgetRef ref;

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _hover = 0;

  void _onStar(int stars) {
    setState(() => _hover = stars);
    // Any star opens the store review flow (Apple/Google decide the UI).
    widget.ref.read(ratingServiceProvider).rate();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppAccent.of(context);
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.premiumGradient,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppShadows.soft(),
              ),
              child: const Icon(Icons.savings_rounded,
                  size: 32, color: AppColors.onPrimary),
            ),
            const Gap(AppSpacing.md),
            Text('「サブスク家計簿」はいかがですか？',
                textAlign: TextAlign.center, style: AppType.display(17)),
            const Gap(AppSpacing.xs),
            Text('星をタップして評価してください',
                textAlign: TextAlign.center,
                style: AppType.body(13, color: AppColors.textSecondary)),
            const Gap(AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  Pressable(
                    scale: 0.85,
                    onTap: () => _onStar(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i <= _hover
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 34,
                        color: i <= _hover ? AppColors.gold : accent.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const Gap(AppSpacing.lg),
            const Divider(height: 1),
            _LinkButton(
              label: 'コメントを書く',
              onTap: () {
                Navigator.of(context).pop();
                showFeedbackSheet(context);
              },
            ),
            const Divider(height: 1),
            _LinkButton(
              label: '今はしない',
              muted: true,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton(
      {required this.label, required this.onTap, this.muted = false});
  final String label;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(label,
            style: AppType.body(15,
                weight: muted ? FontWeight.w500 : FontWeight.w700,
                color: muted
                    ? AppColors.textSecondary
                    : AppAccent.of(context).deep)),
      ),
    );
  }
}
