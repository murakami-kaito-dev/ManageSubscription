import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/converted_amount.dart';
import '../../../core/widgets/soft_card.dart';
import '../../../core/widgets/soft_progress_bar.dart';
import '../../../core/widgets/subscription_avatar.dart';
import '../../../data/models/subscription.dart';
import '../../../providers/settings_provider.dart';

class SubscriptionTile extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final main = ref.watch(settingsProvider.select((s) => s.mainCurrency));
    final dateStr = JpDate.short(sub.nextPaymentDate);
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
                SubscriptionAvatar(sub: sub, size: 46, radius: 15),
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
                    ConvertedAmount(
                        sub: sub, main: main, amountSize: 20, periodSuffix: true),
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
              // A just-started cycle (a few % elapsed) still shows a small nub
              // rather than rendering as an empty bar.
              minVisible: 0.05,
            ),
          ],
        ),
      ),
    );
  }
}
