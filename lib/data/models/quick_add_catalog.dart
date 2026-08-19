import 'dart:convert';

import '../../core/utils/billing.dart';

/// クイック追加メニューのカタログ（`catalog.json`）。
///
/// 配信元は GitHub の公開リポジトリ `submana-catalog`（開発者が価格改定を
/// push するだけで全ユーザーに反映される）。取得できない環境でも動くよう、
/// 同内容のフォールバックを `assets/quick_add/catalog.json` に同梱する。
/// 読み込み・キャッシュは `CatalogService` が担う。
///
/// 価格は日本の公式価格（JPY）。表示は既存の仕組みでメイン通貨に換算される。
class QuickAddCatalog {
  const QuickAddCatalog({
    required this.updatedAt,
    required this.services,
    required this.fixedCosts,
  });

  static const supportedSchema = 1;

  final String updatedAt;
  final List<QuickAddService> services;
  final List<QuickAddFixedCost> fixedCosts;

  /// JSON 文字列から復元する。形式が不正・スキーマ非対応・中身が空のときは
  /// null（呼び出し側が前回値/同梱値へフォールバックする）。
  static QuickAddCatalog? tryParse(String raw) {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      if (m['schemaVersion'] != supportedSchema) return null;
      final services = [
        for (final e in (m['services'] as List))
          QuickAddService._fromMap(e as Map<String, dynamic>)
      ];
      final fixed = [
        for (final e in (m['fixedCosts'] as List? ?? const []))
          QuickAddFixedCost._fromMap(e as Map<String, dynamic>)
      ];
      if (services.isEmpty) return null;
      return QuickAddCatalog(
        updatedAt: m['updatedAt'] as String? ?? '',
        services: services,
        fixedCosts: fixed,
      );
    } catch (_) {
      return null;
    }
  }
}

/// 公式価格つきのサブスク1件。
class QuickAddService {
  const QuickAddService({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.plans,
  });

  final String id;
  final String name;

  /// プリセットアイコンID（`assets/preset_icons/<icon>.svg`）。
  final String icon;
  final int colorValue;
  final List<QuickAddPlan> plans;

  static QuickAddService _fromMap(Map<String, dynamic> m) => QuickAddService(
        id: m['id'] as String,
        name: m['name'] as String,
        icon: m['icon'] as String? ?? '',
        colorValue: _argb(m['color'] as String),
        plans: [
          for (final p in (m['plans'] as List))
            QuickAddPlan._fromMap(p as Map<String, dynamic>)
        ],
      );
}

/// 料金プラン1つ（例:「スタンダード ¥1,590/月」）。
class QuickAddPlan {
  const QuickAddPlan({
    required this.label,
    required this.amount,
    required this.cycle,
  });

  final String label;
  final double amount;
  final BillingCycle cycle;

  static QuickAddPlan _fromMap(Map<String, dynamic> m) => QuickAddPlan(
        label: m['label'] as String,
        amount: (m['amount'] as num).toDouble(),
        cycle: m['cycle'] == 'yearly' ? BillingCycle.yearly : BillingCycle.monthly,
      );
}

/// 固定費1件（家賃など）。価格は決まっていないため、追加時に金額だけ入力させる。
class QuickAddFixedCost {
  const QuickAddFixedCost({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
  });

  final String id;
  final String name;
  final String icon;
  final int colorValue;

  static QuickAddFixedCost _fromMap(Map<String, dynamic> m) =>
      QuickAddFixedCost(
        id: m['id'] as String,
        name: m['name'] as String,
        icon: m['icon'] as String? ?? '',
        colorValue: _argb(m['color'] as String),
      );
}

/// "FFE50914" のような8桁hexを ARGB int へ。
int _argb(String hex) => int.parse(hex, radix: 16);
