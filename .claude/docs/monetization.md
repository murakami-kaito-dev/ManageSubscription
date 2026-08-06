# 料金プラン・課金

## モデル
| プラン | 種別 | 価格 | Product ID |
|---|---|---|---|
| 買い切り | 非消耗型 | ¥980 | `subsc_pro_lifetime` |
| 月額 | 自動更新サブスク | ¥300/月 | `subsc_pro_monthly` |
| 年額 | 自動更新サブスク | ¥1,800/年 | `subsc_pro_yearly` |
| 無料 | — | ¥0 | — |
| 無料体験 | アプリ内実装 | 初回起動から**14日** 全機能開放 | — |

定義: `lib/core/monetization/iap.dart`（`PlanKind`, `Iap.entitlement='premium'`, 商品ID, 価格, `Iap.trialDuration=14日`）。

## エンタイトルメント判定
- `PurchaseService`（`services/purchases/purchase_service.dart`）: 試用起点 `first_launch_ms` を記録。`hasFullAccess = 有料 or 試用中`。プランは `plan_kind`
- `premiumProvider`（bool）= **有料 or 試用中 or `kDevUnlockAll`**。全ゲートはこの bool を見る
- `entitlementProvider` = `Entitlement { isPremium, kind(PlanKind), trialDaysLeft, devUnlocked }`（バナー/ペイウォール表示用）
- 無料枠の制限は `core/premium_limits.dart`（サブスク8/カテゴリ3/支払い方法3/通知1、画像・CSV・カテゴリ別分析・全期間閲覧はプレミアム）

## RevenueCat
- `purchases_flutter`。3商品を**1エンタイトルメント `premium`** に束ねる → 「どれを買っても全機能」
- 現在 `useRevenueCat=false`（モック: 購入は即付与）。iOS API キー（`appl_...`）設定＋`true` 化で本番
- 本番化に必要なユーザー作業は `docs/monetization_setup.md`（App Store Connect 商品登録・契約、RevenueCat 設定）

## ペイウォール（`features/premium/premium_screen.dart`）
- 3プランカード（年額に「おすすめ」）＋試用バナー（残日数 / 体験終了 / 現プラン）
- CTA はプランで文言可変（買い切り=「¥980 で購入する」/ サブスク=「2週間無料で始める」）
- 「無料プランのまま使う」で閉じる。復元・利用規約・プライバシーポリシー（`core/legal.dart` のURL、GitHub Pages `submana-legal`）
- 成功時 confetti＋祝福ダイアログ

## 広告
`kAdsEnabled=false`（`services/ads/ad_service.dart`）。v1は広告なし（プライバシー方針と整合）。AdMob SDK は初期化されず、バナーも生成されない。将来 true で復帰。

## テスト
`test/monetization_test.dart`（新規=試用有効/期限切れ=無料/購入で付与とプラン記録）。
