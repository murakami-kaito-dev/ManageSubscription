import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/soft_card.dart';
import '../../../core/widgets/soft_progress_bar.dart';
import '../../../data/models/subscription.dart';

class SubscriptionTile extends StatelessWidget {
  const SubscriptionTile({super.key, required this.sub, this.onTap});

  final Subscription sub;
  final VoidCallback? onTap;

  String _countdownLabel() {
    if (sub.isPaused) return '停止中';
    final d = sub.daysUntilNextPayment;
    if (d <= 0) return '本日';
    if (d == 1) return '明日';
    return '支払いまで $d日';
  }

  @override
  Widget build(BuildContext context) {
    final fmt = CurrencyFormatter(sub.currency);
    final dateStr = DateFormat('M月d日').format(sub.nextPaymentDate);
    final accent = sub.color;

    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: sub.isPaused ? AppColors.surfaceSunken : null,
      child: Opacity(
        opacity: sub.isPaused ? 0.7 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(sub: sub, accent: accent),
                const Gap(AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.display(19, weight: FontWeight.w800),
                      ),
                      const Gap(2),
                      Row(
                        children: [
                          const Icon(Icons.autorenew_rounded,
                              size: 14, color: AppColors.textMuted),
                          const Gap(4),
                          Text(dateStr,
                              style: AppType.body(12.5,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Gap(AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: fmt.format(sub.amount),
                          style: AppType.display(20, weight: FontWeight.w800),
                        ),
                        TextSpan(
                          text: ' /${sub.periodLabel}',
                          style: AppType.body(12,
                              weight: FontWeight.w600,
                              color: AppColors.textMuted),
                        ),
                      ]),
                    ),
                    const Gap(2),
                    Text(
                      _countdownLabel(),
                      style: AppType.body(12.5,
                          weight: FontWeight.w600,
                          color: sub.isPaused
                              ? AppColors.textMuted
                              : (sub.daysUntilNextPayment <= 3
                                  ? AppColors.coral
                                  : AppColors.textSecondary)),
                    ),
                  ],
                ),
              ],
            ),
            const Gap(AppSpacing.md),
            SoftProgressBar(
              value: sub.isPaused ? 0 : sub.periodProgress,
              color: accent,
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.sub, required this.accent});
  final Subscription sub;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final hasImage = sub.imagePath != null && File(sub.imagePath!).existsSync();
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hasImage ? null : accent.withOpacity(0.16),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accent.withOpacity(0.28), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.file(File(sub.imagePath!), fit: BoxFit.cover)
          : (sub.emoji != null && sub.emoji!.isNotEmpty
              ? Text(sub.emoji!, style: const TextStyle(fontSize: 22))
              : Text(
                  sub.name.characters.take(1).toString().toUpperCase(),
                  style: AppType.display(20,
                      weight: FontWeight.w800, color: accent),
                )),
    );
  }
}
