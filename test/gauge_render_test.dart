import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manage_subscription/core/widgets/soft_progress_bar.dart';

void main() {
  // Regression guard: the fill must have BOTH width and height. A missing
  // heightFactor once made it render at the right width but height 0, so every
  // home-tile gauge looked empty.
  testWidgets('progress fill fills width and height', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 200,
            child: SoftProgressBar(value: 0.9, height: 8, color: Colors.red),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    // The gradient fill is the DecoratedBox; measure its rendered size.
    final size = tester.getSize(find.byType(DecoratedBox).first);
    expect(size.height, 8, reason: 'fill must be full height, not collapsed');
    expect(size.width, closeTo(180, 0.5), reason: '90% of 200');
  });
}
