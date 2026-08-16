import 'dart:convert';
import 'dart:ui' show Color;

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency.dart';
import '../../data/models/subscription.dart';

/// ホーム画面ウィジェットに渡すデータ（JSON文字列）を組み立てる。
///
/// 表示ルールはアプリ本体と揃える:
/// - 「今月の合計」= 停止中を除く全件の `monthlyAmountIn(メイン通貨)` の総和
///   （ホームの `_SummaryCard` と同一）
/// - 各アイテムの額はメイン通貨に換算した値（2.0.1 の一覧表示ルールと同一）
///
/// 日付・残日数のラベルはここでは作らない。ウィジェット側（Swift）が
/// タイムラインの日ごとに epoch から再計算する（アプリを開かない日でも
/// 「あと◯日」が正しく進むように）。
String buildWidgetPayload(
  List<Subscription> all,
  AppCurrency main, {
  DateTime? now,
  int maxItems = 4, // medium ウィジェットの表示行数
  int accentArgb = 0xFF6E9080, // 設定のテーマ色（既定はアプリと同じセージ）
}) {
  final fmt = CurrencyFormatter(main);
  final active = [for (final s in all) if (!s.isPaused) s];

  final total =
      active.fold<double>(0, (sum, s) => sum + s.monthlyAmountIn(main));

  final upcoming = [...active]
    ..sort((a, b) => a.daysUntilNextPayment.compareTo(b.daysUntilNextPayment));

  // テーマ色: primary/deep の導出はアプリ本体（AppAccent.from）と同一ロジック。
  final accent = AppAccent.from(Color(accentArgb));
  String hex(Color c) =>
      '#${(c.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  final month = (now ?? DateTime.now()).month;
  return jsonEncode({
    'monthLabel': '$month月',
    'totalLabel': fmt.format(total),
    'count': active.length,
    'accent': hex(accent.primary),
    'accentDeep': hex(accent.deep),
    'items': [
      for (final s in upcoming.take(maxItems))
        {
          'name': s.name,
          'amount': fmt.format(s.amountIn(main)),
          'epoch': s.nextPaymentDate.millisecondsSinceEpoch,
        },
    ],
  });
}
