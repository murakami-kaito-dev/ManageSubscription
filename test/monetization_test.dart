import 'package:flutter_test/flutter_test.dart';
import 'package:manage_subscription/core/monetization/iap.dart';
import 'package:manage_subscription/services/purchases/purchase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<PurchaseService> serviceWith(Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  final s = PurchaseService(prefs);
  await s.init();
  return s;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fresh install → 2-week trial active, full access, no payment', () async {
    final s = await serviceWith({});
    expect(s.isTrialActive, isTrue);
    expect(s.hasPaid, isFalse);
    expect(s.hasFullAccess, isTrue);
    expect(s.currentPlan, PlanKind.trial);
    expect(s.trialDaysLeft, inInclusiveRange(13, 14));
  });

  test('after the trial window with no purchase → free, no access', () async {
    final longAgo = DateTime.now()
        .subtract(const Duration(days: 20))
        .millisecondsSinceEpoch;
    final s = await serviceWith({'first_launch_ms': longAgo});
    expect(s.isTrialActive, isFalse);
    expect(s.hasFullAccess, isFalse);
    expect(s.currentPlan, PlanKind.free);
    expect(s.trialDaysLeft, 0);
  });

  test('purchasing a plan grants access and records the plan', () async {
    final longAgo = DateTime.now()
        .subtract(const Duration(days: 20))
        .millisecondsSinceEpoch;
    final s = await serviceWith({'first_launch_ms': longAgo});

    final ok = await s.purchase(PlanKind.monthly);
    expect(ok, isTrue);
    expect(s.hasPaid, isTrue);
    expect(s.hasFullAccess, isTrue);
    expect(s.currentPlan, PlanKind.monthly);
    // Trial reads as inactive once paid (paid supersedes trial).
    expect(s.isTrialActive, isFalse);
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
