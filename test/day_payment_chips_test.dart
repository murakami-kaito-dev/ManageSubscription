import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manage_subscription/core/utils/billing.dart';
import 'package:manage_subscription/data/models/subscription.dart';
import 'package:manage_subscription/features/calendar/widgets/day_payment_chips.dart';

/// カレンダーの日付セルは「その日に何を支払うか」を名前チップで示す。
/// セル幅が狭いので表示は最大2件＋「+N」に集約する。
void main() {
  var seq = 0;
  Subscription sub(String name) {
    seq++;
    return Subscription(
      id: 't$seq',
      name: name,
      amount: 1000,
      currencyCode: 'JPY',
      cycle: BillingCycle.monthly,
      firstPaymentDate: DateTime(2026, 1, 1),
      colorValue: 0xFF6E9080,
      usageCount: 0,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  Future<void> pump(WidgetTester tester, List<Subscription> events) =>
      tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 50, // 実際のセル幅（画面幅の1/7）を模す
              height: DayPaymentChips.rowHeight,
              child: DayPaymentChips(events: events),
            ),
          ),
        ),
      ));

  testWidgets('その日の支払いをサービス名で表示する', (tester) async {
    await pump(tester, [sub('Netflix')]);
    expect(find.text('Netflix'), findsOneWidget);
  });

  testWidgets('3件以上ある日は2件＋「+N」に集約する', (tester) async {
    await pump(tester, [sub('Claude'), sub('Kindle'), sub('chocoZAP')]);
    expect(find.text('Claude'), findsOneWidget);
    expect(find.text('Kindle'), findsOneWidget);
    expect(find.text('chocoZAP'), findsNothing, reason: '3件目は集約される');
    expect(find.text('+1'), findsOneWidget);
  });

  testWidgets('長い名前は末尾を省略して1行に収める（あふれない）', (tester) async {
    await pump(tester, [sub('YouTube Premium ものすごく長いサービス名')]);
    final text = tester.widget<Text>(find.byType(Text).first);
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull, reason: 'レイアウトがあふれない');
  });

  testWidgets('支払いがない日は何も描かない', (tester) async {
    await pump(tester, const []);
    expect(find.byType(Text), findsNothing);
  });
}
