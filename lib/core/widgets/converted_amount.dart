import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/currency.dart';
import '../../data/models/subscription.dart';

/// 一覧・タイルで、サブスクの額を**メイン通貨に換算**して表示する共通ウィジェット。
///
/// 合計や分析は既にメイン通貨で計算されているので、個々の額もここで揃える。
/// 元の通貨がメイン通貨と違うときは、元の額（例: `$110.00`）を小さく併記して、
/// 「元が何通貨いくらか」を失わないようにする（換算値は日々の為替でわずかに動くため）。
class ConvertedAmount extends StatelessWidget {
  const ConvertedAmount({
    super.key,
    required this.sub,
    required this.main,
    this.amountSize = 16,
    this.periodSuffix = false,
  });

  final Subscription sub;

  /// 表示に使うメイン通貨。
  final AppCurrency main;

  /// 換算額のフォントサイズ。
  final double amountSize;

  /// 換算額のあとに ` /月` などの周期ラベルを付ける（ホームタイル用）。
  final bool periodSuffix;

  @override
  Widget build(BuildContext context) {
    final converted = CurrencyFormatter(main).format(sub.amountIn(main));
    final isForeign = sub.currency != main;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (periodSuffix)
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: converted,
                style: AppType.display(amountSize, weight: FontWeight.w800),
              ),
              TextSpan(
                text: ' /${sub.periodLabel}',
                style: AppType.body(12,
                    weight: FontWeight.w600, color: AppColors.textMuted),
              ),
            ]),
          )
        else
          Text(converted, style: AppType.display(amountSize)),
        if (isForeign)
          Text(
            CurrencyFormatter(sub.currency).format(sub.amount),
            style: AppType.body(11.5,
                weight: FontWeight.w600, color: AppColors.textMuted),
          ),
      ],
    );
  }
}
