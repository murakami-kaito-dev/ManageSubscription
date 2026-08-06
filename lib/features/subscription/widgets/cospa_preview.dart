import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';

/// "サブスク・コスパチェッカー": shows the auto-computed cost per single use
/// (monthly spend ÷ monthly uses) with a friendly value judgement.
class CospaPreview extends StatelessWidget {
  const CospaPreview({
    super.key,
    required this.monthlyAmount,
    required this.currency,
    required this.usage,
    required this.unit,
  });

  final double monthlyAmount;
  final AppCurrency currency;
  final double usage;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final fmt = CurrencyFormatter(currency);

    if (usage <= 0 || monthlyAmount <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceSunken,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '利用回数を入れると「1回あたりの単価」が表示されます',
          textAlign: TextAlign.center,
          style: AppType.body(12.5, color: AppColors.textMuted),
        ),
      );
    }

    final perUse = monthlyAmount / usage;
    final (badge, badgeColor) = _judge(perUse);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [badgeColor.withOpacity(0.16), badgeColor.withOpacity(0.06)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: badgeColor.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_offer_rounded, color: badgeColor, size: 22),
          ),
          const Gap(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1$unit あたり',
                    style: AppType.body(12, color: AppColors.textSecondary)),
                const Gap(2),
                Text(fmt.format(perUse),
                    style: AppType.display(22, color: AppColors.textPrimary)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(badge,
                style: AppType.body(12,
                    weight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Rough JPY-equivalent thresholds for a light-hearted verdict.
  (String, Color) _judge(double perUse) {
    final jpy = CurrencyRates.convert(perUse, currency.code, 'JPY');
    if (jpy <= 100) return ('お得！', AppColors.primary);
    if (jpy <= 500) return ('ふつう', AppColors.chartPalette[2]);
    return ('割高かも', AppColors.coral);
  }
}
