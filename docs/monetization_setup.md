# 課金（収益化）セットアップ手順

アプリ側の実装は完了しています。ここでは**あなたが行う必要がある設定**（App Store
Connect と RevenueCat）と、**私が仕上げる部分**を整理します。

## 全体像（採用したモデル）

| プラン | 商品タイプ | 価格 | 商品ID（Product ID） |
|---|---|---|---|
| ③ 買い切り | 非消耗型（Non-Consumable） | ¥980 | `subsc_pro_lifetime` |
| ② 月額 | 自動更新サブスク | ¥300 / 月 | `subsc_pro_monthly` |
| ② 年額 | 自動更新サブスク | ¥1,800 / 年 | `subsc_pro_yearly` |
| ① 無料 | —（購入なし） | ¥0 | — |

- **2週間の無料体験**は**アプリ内で実装済み**（初回起動日から14日間、全機能開放）。
  App Store 側の「無料トライアル（intro offer）」設定は不要です。
- 3つの有料商品は RevenueCat の**1つのエンタイトルメント `premium`** に束ねます
  →「どれを買っても全機能開放」。アプリは `premium` が有効かだけを見ます。

## アプリ側（実装済み ✅）
- プラン/試用のロジック、エンタイトルメント判定の一本化（`premiumProvider`）
- 3プランを見せるペイウォール（`PremiumScreen`）、試用残日数の表示、購入・復元
- 商品ID・価格・エンタイトルメント名の定義（`lib/core/monetization/iap.dart`）
- RevenueCat 連携コード（`PurchaseService`）。今は `useRevenueCat = false` のモック動作

---

## 🧑 あなたの作業

### A. App Store Connect
1. **Paid Applications 契約に同意**：Business → 契約/税金/口座（Agreements）で
   「Paid Apps」契約に同意し、銀行・税情報を登録（これが未完だと課金は一切動きません）。
2. **アプリ内課金の商品を3つ作成**（上表の Product ID を**正確に**使用）：
   - `subsc_pro_lifetime`：非消耗型、¥980
   - サブスク2つは**1つのサブスクリプショングループ**にまとめる（ユーザーが月↔年を移行可能に）：
     - `subsc_pro_monthly`：自動更新、¥300 / 月
     - `subsc_pro_yearly`：自動更新、¥1,800 / 年
   - 各商品に**表示名・説明**（日本語）を設定。
3. サブスクの審査用に**レビューメモ／スクリーンショット**を添付。
4. **App-Specific Shared Secret**（または In-App Purchase Key）を発行 → RevenueCat に登録。

### B. RevenueCat ダッシュボード（無料枠でOK）
1. プロジェクト作成 → **App Store アプリを追加**（Bundle ID `com.submana.app`）。
2. 上記 **Shared Secret / IAP Key** を登録。
3. **Entitlement `premium`** を作成。
4. **Products** に3商品を追加し、**すべて `premium` に紐付け**。
5. **Offering（例 `default`）** に3つの Package（lifetime / monthly / yearly）を追加。
6. **iOS 用 API キー（`appl_...`）** を控える → 私に渡してください（下記C）。

### C. 公開URLを2つ用意（サブスク審査に必須）
Apple は自動更新サブスクのペイウォールに **利用規約(EULA)** と **プライバシー
ポリシー** のリンクを要求します。
- どちらも公開URLが必要（GitHub Pages 等で可）。**文面は私がドラフトします**。

---

## 🤖 私が仕上げる部分（材料が揃えば即対応）
- `PurchaseService` の `useRevenueCat = true` 化＋**RevenueCat の iOS APIキー**を設定
  （このキーはクライアント公開キーで `.p8` のような秘密鍵ではありませんが、私が入れます）
- ペイウォールの「利用規約 / プライバシーポリシー」リンクに**実URL**を接続
- 必要なら**プライバシーポリシー／利用規約の文面ドラフト**を作成
- StoreKit のローカルテスト設定（実機/シミュレータで購入フローを検証する構成）

## いま私に渡すと進むもの
1. RevenueCat の **iOS APIキー（`appl_...`）**
2. **利用規約URL** と **プライバシーポリシーURL**（用意でき次第。文面が要るなら言ってください）
3. 商品ID（上記のままで良いか。変えたい場合はその文字列）

## 補足・注意
- **無料体験はアプリ内方式**のため、アプリの再インストールでリセットされ得ます
  （ストア強制ではない）。より厳密にするなら、将来サブスクに「ストアの無料トライアル
  （intro offer）」を付ける方式へ移行できます。
- 買い切り（`subsc_pro_lifetime`）は**復元**が必要な非消耗型なので、「購入を復元」導線は実装済みです。
