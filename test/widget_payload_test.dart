import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:manage_subscription/core/utils/billing.dart';
import 'package:manage_subscription/core/utils/currency.dart';
import 'package:manage_subscription/data/models/subscription.dart';
import 'package:manage_subscription/services/widget/widget_payload.dart';

/// ホーム画面ウィジェットに渡すペイロードの表示ルールを守る:
/// - 合計はホームと同じ「停止中を除く monthlyAmountIn(メイン通貨) の総和」
/// - items は支払い日が近い順に最大3件・額はメイン通貨換算
/// （為替は RatesService 未ロード時のフォールバック USD=155 を使う）
void main() {
  var seq = 0;
  Subscription sub({
    String? name,
    double amount = 1000,
    String currency = 'JPY',
    BillingCycle cycle = BillingCycle.monthly,
    int firstDay = 1,
    bool paused = false,
  }) {
    seq++;
    return Subscription(
      id: 't$seq',
      name: name ?? 'Sub$seq',
      amount: amount,
      currencyCode: currency,
      cycle: cycle,
      // 過去日ベース: nextPaymentDate はサイクルで前進する
      firstPaymentDate: DateTime(2026, 1, firstDay),
      colorValue: 0xFF000000,
      usageCount: 0,
      isPaused: paused,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  test('合計 = 停止中を除く monthlyAmountIn の総和（メイン通貨表記）', () {
    final subs = [
      sub(amount: 1000),
      sub(amount: 500),
      sub(amount: 9999, paused: true), // 停止中は合計に入らない
    ];
    final map =
        jsonDecode(buildWidgetPayload(subs, AppCurrency.jpy)) as Map<String, dynamic>;
    expect(map['totalLabel'], '¥1,500');
    expect(map['count'], 2);
    expect(map['monthLabel'], '${DateTime.now().month}月');
  });

  test('items は支払い日が近い順に最大4件・停止中は含まない', () {
    // 初回支払日の「日」をずらして次回支払日の遠近を作る（本日=毎月の周回で決まる）
    // アクティブ5件＋停止1件 → 上限4件に絞られることを見る
    final subs = [
      for (var d = 1; d <= 28; d += 6) sub(name: 'D$d', firstDay: d),
      sub(name: 'paused', firstDay: 2, paused: true),
    ];
    final map =
        jsonDecode(buildWidgetPayload(subs, AppCurrency.jpy)) as Map<String, dynamic>;
    final items = (map['items'] as List).cast<Map<String, dynamic>>();
    expect(items.length, 4);
    expect(items.map((e) => e['name']), isNot(contains('paused')));
    // 並びが daysUntilNextPayment 昇順であること
    final expected = [
      for (final s in subs)
        if (!s.isPaused) s
    ]..sort((a, b) => a.daysUntilNextPayment.compareTo(b.daysUntilNextPayment));
    expect(items.map((e) => e['name']).toList(),
        expected.take(4).map((e) => e.name).toList());
    // epoch が次回支払日と一致
    expect(items.first['epoch'],
        expected.first.nextPaymentDate.millisecondsSinceEpoch);
  });

  test('外貨アイテムの額はメイン通貨に換算される（USD=155 フォールバック）', () {
    final subs = [sub(name: 'Claude', amount: 110, currency: 'USD')];
    final map =
        jsonDecode(buildWidgetPayload(subs, AppCurrency.jpy)) as Map<String, dynamic>;
    final items = (map['items'] as List).cast<Map<String, dynamic>>();
    expect(items.single['amount'], '¥17,050');
    expect(map['totalLabel'], '¥17,050');
  });

  test('テーマ色が primary/deep として載る（deep は AppAccent と同一導出）', () {
    // 既定（セージ #6E9080）
    final def =
        jsonDecode(buildWidgetPayload(const [], AppCurrency.jpy)) as Map<String, dynamic>;
    expect(def['accent'], '#6E9080');
    expect((def['accentDeep'] as String), startsWith('#'));
    // 別のテーマ色を渡すと変わる
    final blue = jsonDecode(buildWidgetPayload(const [], AppCurrency.jpy,
        accentArgb: 0xFF7EA6C6)) as Map<String, dynamic>;
    expect(blue['accent'], '#7EA6C6');
    expect(blue['accentDeep'], isNot(def['accentDeep']));
  });

  test('空のライブラリでも壊れない', () {
    final map =
        jsonDecode(buildWidgetPayload(const [], AppCurrency.jpy)) as Map<String, dynamic>;
    expect(map['totalLabel'], '¥0');
    expect(map['count'], 0);
    expect(map['items'], isEmpty);
  });
}
