import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manage_subscription/core/utils/billing.dart';
import 'package:manage_subscription/data/models/quick_add_catalog.dart';
import 'package:manage_subscription/services/catalog/catalog_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// クイック追加カタログの約束事:
/// - 同梱 catalog.json は常にパース可能で、参照アイコンは実在する
/// - 不正なJSON・非対応スキーマは null（呼び出し側がフォールバック）
/// - CatalogService は 前回取得値 → 同梱アセット の順で必ず何かを返す
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuickAddCatalog.tryParse', () {
    test('同梱アセットの catalog.json をパースでき、アイコンが全て実在する', () {
      final raw = File('assets/quick_add/catalog.json').readAsStringSync();
      final c = QuickAddCatalog.tryParse(raw);
      expect(c, isNotNull);
      expect(c!.services.length, greaterThanOrEqualTo(20));
      expect(c.fixedCosts, isNotEmpty);
      for (final s in c.services) {
        expect(s.plans, isNotEmpty, reason: '${s.id}: プランが空');
        expect(File('assets/preset_icons/${s.icon}.svg').existsSync(), isTrue,
            reason: '${s.id}: アイコン ${s.icon}.svg が無い');
      }
      for (final f in c.fixedCosts) {
        expect(File('assets/preset_icons/${f.icon}.svg').existsSync(), isTrue,
            reason: '${f.id}: アイコン ${f.icon}.svg が無い');
      }
    });

    test('年額プランは yearly、指定なしは monthly になる', () {
      final raw = File('assets/quick_add/catalog.json').readAsStringSync();
      final c = QuickAddCatalog.tryParse(raw)!;
      final prime = c.services.firstWhere((s) => s.id == 'amazon_prime');
      expect(prime.plans.first.cycle, BillingCycle.monthly);
      expect(prime.plans.last.cycle, BillingCycle.yearly);
      expect(prime.plans.last.amount, 5900);
    });

    test('壊れたJSON・非対応スキーマ・空servicesは null', () {
      expect(QuickAddCatalog.tryParse('{broken'), isNull);
      expect(
          QuickAddCatalog.tryParse(
              '{"schemaVersion": 99, "services": [], "fixedCosts": []}'),
          isNull);
      expect(
          QuickAddCatalog.tryParse(
              '{"schemaVersion": 1, "services": [], "fixedCosts": []}'),
          isNull);
    });
  });

  group('CatalogService.loadLocal', () {
    test('キャッシュが無ければ同梱アセットで起動できる', () async {
      SharedPreferences.setMockInitialValues({});
      final svc = CatalogService(await SharedPreferences.getInstance());
      await svc.loadLocal();
      expect(svc.catalog.services, isNotEmpty);
    });

    test('壊れたキャッシュは無視して同梱アセットに落ちる', () async {
      SharedPreferences.setMockInitialValues(
          {'quick_add_catalog_json': '{broken json'});
      final svc = CatalogService(await SharedPreferences.getInstance());
      await svc.loadLocal();
      expect(svc.catalog.services, isNotEmpty);
    });

    test('有効なキャッシュがあればそれを優先する', () async {
      const cached = '{"schemaVersion":1,"updatedAt":"2099-01-01","services":['
          '{"id":"x","name":"Cached","icon":"","color":"FF000000",'
          '"plans":[{"label":"m","amount":123}]}],"fixedCosts":[]}';
      SharedPreferences.setMockInitialValues(
          {'quick_add_catalog_json': cached});
      final svc = CatalogService(await SharedPreferences.getInstance());
      await svc.loadLocal();
      expect(svc.catalog.services.single.name, 'Cached');
      expect(svc.catalog.services.single.plans.single.amount, 123);
    });
  });
}
