import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/subscription.dart';

/// カレンダーの日付セルに「その日に支払うサービス名」をチップで表示する。
///
/// 色ドットだけでは「何が」支払われるか分からなかったため、名前を直接出す。
/// セル幅は画面幅の1/7しかないので、長い名前は末尾を `…` で省略する
/// （読める範囲だけ出す方が、何も出さないより手掛かりになる）。
class DayPaymentChips extends StatelessWidget {
  const DayPaymentChips({super.key, required this.events});

  /// その日に支払いが発生するサブスク。
  final List<Subscription> events;

  /// セルに収まる最大件数。これを超えた分は「+N」に集約する。
  static const maxShown = 2;

  /// チップ表示に必要な行の高さ（`TableCalendar.rowHeight`）。
  static const rowHeight = 78.0;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    final shown = events.take(maxShown).toList();
    final rest = events.length - shown.length;

    return Padding(
      // 日付の数字の下に重ならないよう、上に余白を取る。
      padding: const EdgeInsets.only(top: 22, left: 1, right: 1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final e in shown) _chip(e),
          if (rest > 0)
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text('+$rest',
                  style: AppType.body(8, color: AppColors.textMuted)),
            ),
        ],
      ),
    );
  }

  /// アイテム固有色から淡い地色と濃い文字色を導く（アバターと同じ導出）。
  Widget _chip(Subscription s) {
    final hsl = HSLColor.fromColor(s.color);
    final soft = hsl
        .withSaturation((hsl.saturation * 0.5).clamp(0.0, 1.0))
        .withLightness((hsl.lightness + 0.32).clamp(0.0, 0.94))
        .toColor();
    final deep =
        hsl.withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0)).toColor();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1.5),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        s.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: AppType.body(8, weight: FontWeight.w700, color: deep),
      ),
    );
  }
}
