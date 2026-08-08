# 料金プラン・課金

## モデル
| プラン | 種別 | 価格 | Product ID |
|---|---|---|---|
| 無料 | —（初期状態・ずっと使える） | ¥0 | — |
| 買い切り | 非消耗型 | ¥980 | `subsc_pro_lifetime` |
| 月額 | 自動更新サブスク（初回2週間無料） | ¥300/月 | `subsc_pro_monthly` |
| 年額 | 自動更新サブスク（初回2週間無料） | ¥1,800/年 | `subsc_pro_yearly` |

- **インストール直後は「無料プラン」**。アプリ内の期限付き無料体験は**廃止**（「残り◯日」は無い）。
- **2週間の無料体験は月額/年額サブスクの App Store 導入オファー（Introductory Offer: FREE_TRIAL / TWO_WEEKS）**。
  購入すると2週間無料 → その後自動で課金に移行。RevenueCat は体験期間中もエンタイトルメントを active として返す。
- サブスクが継続されず期限切れ／解約になると `premium` が inactive → **自動的に無料プランへ戻る**。
- 定義: `lib/core/monetization/iap.dart`（`PlanKind`, `Iap.entitlement='premium'`, 商品ID, 価格）。

## エンタイトルメント判定
- `PurchaseService`（`services/purchases/purchase_service.dart`）: **`hasFullAccess = hasPaid`**（有料エンタイトルメントのみ。アプリ側の試用タイマーは無し）。プランは `plan_kind`
- `premiumProvider`（bool）= **有料 or `kDevUnlockAll`**。全ゲートはこの bool を見る
- `entitlementProvider` = `Entitlement { isPremium, kind(PlanKind), devUnlocked }`（バナー/ペイウォール表示用）

## 無料枠と制限（`core/premium_limits.dart`）
| 機能 | 無料 | プレミアム |
|---|---|---|
| サブスク登録数 | 8件 | 100件（`hardMaxSubscriptions`） |
| カテゴリー登録数 | 5件 | 無制限 |
| 支払い方法登録数 | 5件 | 無制限 |
| 支払い前通知ルール | **無制限**（全員） | 無制限 |
| カテゴリー別/支払い方法別の分析 | **✓（無料）** | ✓ |
| 並べ替え・テーマカラー | ✓ | ✓ |
| アイコン画像 / CSVエクスポート / CSVインポート | ✗ | ✓ |
| カレンダー/履歴の閲覧範囲 | 当月のみ | 全期間 |

## 上限超過ロック（`features/premium/limit_gate.dart`）
無料ユーザーが上限を超えた項目を持つ場合（例：課金失効で 100→8 に降格）、`LimitGate` がシェル全体を
「整理 or アップグレード」画面に置き換える。超過リソースをその場で削除でき、`プレミアムに登録`／`購入を復元`
も可能。**上限内に戻った瞬間 or プレミアム化で自動的に解除**（行き止まりにしない＝2-5）。built-in の
カテゴリ/支払い方法は削除不可アイコン表示。

## RevenueCat
- `purchases_flutter`。3商品を**1エンタイトルメント `premium`** に束ねる → 「どれを買っても全機能」
- **本番稼働中**：`useRevenueCat=true`、iOS Public SDK key（`appl_...`）を `purchase_service.dart` に設定済み。
  RevenueCat 側で Entitlement `premium` / Products / Offering `default`（月/年/買い切り）設定済み。
- セットアップ経緯・鍵の場所は `monetization_setup*.md` と `.local`（Git管理外）。

## ペイウォール（`features/premium/premium_screen.dart`）
- 閉じる **✗ は右上**（設定画面と統一）。Hero は**実アプリアイコン**（`assets/icon/icon.png`）
- 3プランカード（年額に「おすすめ」）＋状態バナー（無料 / 現プラン。試用カウントダウンは無し）
- CTA はプランで文言可変（買い切り=「¥980 で購入する」/ サブスク=「2週間無料で始める（その後 ¥X）」）
- 下部に無料 vs プレミアムの比較表。「無料プランのまま使う」で閉じる。復元・規約・ポリシー

## 広告
`kAdsEnabled=false`（`services/ads/ad_service.dart`）。v1は広告なし。将来 true で「プレミアムは非表示」。

## テスト
`test/monetization_test.dart`（新規=無料/購入で付与とプラン記録）、`test/logic_test.dart`（無料枠ゲート）。
