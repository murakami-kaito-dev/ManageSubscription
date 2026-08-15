import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manage_subscription/core/utils/billing.dart';
import 'package:manage_subscription/core/utils/currency.dart';
import 'package:manage_subscription/core/widgets/converted_amount.dart';
import 'package:manage_subscription/data/models/subscription.dart';

/// 表示額は「メイン通貨に換算」して出す。外貨アイテムのときは元の額も併記し、
/// メイン通貨と同じアイテムでは併記しない、という表示ルールを守る。
/// （為替は RatesService 未ロード時のフォールバック USD=155 を使う）
void main() {
  Subscription sub({double amount = 110, String currency = 'USD'}) =>
      Subscription(
        id: 't',
        name: 'Test',
        amount: amount,
        currencyCode: currency,
        cycle: BillingCycle.monthly,
        firstPaymentDate: DateTime(2026, 1, 1),
        colorValue: 0xFF000000,
        usageCount: 0,
        createdAt: DateTime(2026, 1, 1),
      );

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Center(child: child))),
      );

  testWidgets('外貨アイテムは換算額を主表示し、元の額を併記する', (tester) async {
    await pump(
      tester,
      ConvertedAmount(sub: sub(amount: 110, currency: 'USD'), main: AppCurrency.jpy),
    );
    // $110 × 155（フォールバック）= ¥17,050 を主表示。
    expect(find.text('¥17,050'), findsOneWidget);
    // 元の外貨額も残す。
    expect(find.text(r'$110.00'), findsOneWidget);
  });

  testWidgets('メイン通貨と同じアイテムは換算額のみ（元額は併記しない）', (tester) async {
    await pump(
      tester,
      ConvertedAmount(sub: sub(amount: 1200, currency: 'JPY'), main: AppCurrency.jpy),
    );
    expect(find.text('¥1,200'), findsOneWidget);
    // 同一通貨なので併記なし（$ は出ない）。
    expect(find.textContaining(r'$'), findsNothing);
  });
}
