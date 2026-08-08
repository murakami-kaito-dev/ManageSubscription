import 'package:flutter_test/flutter_test.dart';
import 'package:manage_subscription/core/monetization/iap.dart';
import 'package:manage_subscription/services/purchases/purchase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<PurchaseService> serviceWith(Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  // Force the offline mock path (no RevenueCat plugin in unit tests).
  final s = PurchaseService(prefs, useRevenueCat: false);
  await s.init();
  return s;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fresh install → free plan, no premium access (no app-side trial)',
      () async {
    final s = await serviceWith({});
    expect(s.hasPaid, isFalse);
    expect(s.hasFullAccess, isFalse);
    expect(s.currentPlan, PlanKind.free);
  });

  test('purchasing a plan grants access and records the plan', () async {
    final s = await serviceWith({});

    final ok = await s.purchase(PlanKind.monthly);
    expect(ok, isTrue);
    expect(s.hasPaid, isTrue);
    expect(s.hasFullAccess, isTrue);
    expect(s.currentPlan, PlanKind.monthly);
  });

  test('the free plan kind cannot be "purchased"', () async {
    final s = await serviceWith({});
    expect(await s.purchase(PlanKind.free), isFalse);
    expect(await s.purchase(PlanKind.trial), isFalse);
  });

  test('lifetime purchase persists as the lifetime plan', () async {
    final s = await serviceWith({});
    await s.purchase(PlanKind.lifetime);
    expect(s.currentPlan, PlanKind.lifetime);
    expect(Iap.productId(PlanKind.lifetime), Iap.lifetimeId);
  });
}
