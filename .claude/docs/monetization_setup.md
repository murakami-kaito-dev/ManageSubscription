# 課金（収益化）セットアップ手順

アプリ側の実装は完了しています。ここでは**あなたが行う必要がある設定**（App Store
Connect と RevenueCat）と、**私が仕上げる部分**を整理します。

> 👉 実際に手を動かす**画面順のクリックガイド**は [monetization_setup_guide.md](monetization_setup_guide.md) にあります。

## 進捗（現在地）
- ✅ **アプリ側の実装**：3プラン＋2週間無料体験＋ペイウォール＋復元（完了）
- ✅ **利用規約・プライバシーポリシーの公開**：法務ページ専用の別Publicリポジトリ
  `murakami-kaito-dev/submana-legal` を作成し GitHub Pages で公開（アプリ本体のリポジトリからは分離）。アプリのペイウォールにも接続済み
  - 利用規約：https://murakami-kaito-dev.github.io/submana-legal/terms.html
  - プライバシーポリシー：https://murakami-kaito-dev.github.io/submana-legal/privacy.html
- ⏳ **残り（あなたのアカウント操作が必須）**：App Store Connect の契約・商品登録、RevenueCat のアカウント作成・設定（下記）
- ⏳ **その後、私が仕上げる**：RevenueCat の iOSキーを設定して `useRevenueCat=true` 化

> なぜ「あなたの操作が必須」か：Apple/RevenueCat の**アカウント作成・法的契約への同意・2段階認証ログイン**は本人しかできず、私（Claude）は代行できません。コードで済む部分は完了済みです。

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

## App Store Connect の役割分担（重要）
ASC API キー（`ios/AuthKey_*.p8` ＋ keyID/issuerID）は**有効**で、Claude 側から ASC API を叩ける
（read 確認済み）。ただし **API では出来ないこと**があり、そこは人間の UI 操作が必須：

- 🧑 **あなた（UI 必須・API 不可）**
  1. **アプリレコードの新規作成**（マイApp → ＋）。ASC API に「アプリ新規作成」エンドポイントは無い。
     - 現状 `com.submana.app` は**アプリ未作成・Bundle ID も未登録**（2026-08 時点、API で確認）。
  2. **Paid Applications 契約への同意**＋**銀行・税務情報**の登録（法的同意なので API 不可。未完だと課金は一切動かない）。
- 🤖 **Claude（ASC API キーで自動化できる）**
  - 上記1・2が済み、アプリレコードが存在すれば、**アプリ内課金の商品3つを API で作成**できる：
    `subsc_pro_lifetime`（非消耗型 ¥980）／サブスクグループ＋`subsc_pro_monthly`（¥300月）
    `subsc_pro_yearly`（¥1,800年）、価格・日本語ローカライズまで。※ライブ口座への書き込みなので事前に確認を取る。
  - 審査用スクショ等の素材が要るものは別途相談。

（従来ここは「全部あなたの作業」と書いていたが、正確には**アプリ作成と契約同意だけが人間必須**で、商品作成は Claude が API で代行可能。）
4. **App-Specific Shared Secret**（または In-App Purchase Key）を発行 → RevenueCat に登録。

### B. RevenueCat ダッシュボード（無料枠でOK）
1. プロジェクト作成 → **App Store アプリを追加**（Bundle ID `com.submana.app`）。
2. 上記 **Shared Secret / IAP Key** を登録。
3. **Entitlement `premium`** を作成。
4. **Products** に3商品を追加し、**すべて `premium` に紐付け**。
5. **Offering（例 `default`）** に3つの Package（lifetime / monthly / yearly）を追加。
6. **iOS 用 API キー（`appl_...`）** を控える → 私に渡してください（下記C）。

### C. 公開URL（利用規約・プライバシーポリシー）— ✅ 完了（私が対応済み）
GitHub Pages を有効化し、下記URLが稼働中・アプリに接続済みです。あなたの作業は
ありません（文面を直したい場合のみ言ってください）。
- 利用規約：https://murakami-kaito-dev.github.io/submana-legal/terms.html
- プライバシーポリシー：https://murakami-kaito-dev.github.io/submana-legal/privacy.html

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
