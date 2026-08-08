# 課金セットアップ 実行ガイド（画面順・あなたが操作）

これは [monetization_setup.md](monetization_setup.md)（全体像・役割分担）の**手を動かす版**です。
上から順にやれば、App Store Connect と RevenueCat の設定が終わります。**アカウント作成・契約同意・
2段階認証ログインは本人しかできない**ので、この章はあなたの操作、最後の“アプリへ反映”は私が行います。

用語の対応（このアプリで使う固定値）:

| 項目 | 値 |
|---|---|
| iOS Bundle ID | `com.submana.app` |
| エンタイトルメント名 | `premium` |
| Offering 名 | `default` |
| 買い切り Product ID | `subsc_pro_lifetime`（非消耗型 / ¥980） |
| 月額 Product ID | `subsc_pro_monthly`（自動更新 / ¥300 ・月） |
| 年額 Product ID | `subsc_pro_yearly`（自動更新 / ¥1,800 ・年） |

> Product ID は**あとから変更できません**。上の文字列を1字違わず使ってください（変えたい場合は先に相談を）。

---

## 事前チェック（最初に1回）
- [ ] **Apple Developer Program** に加入済み（有料・年額）。
- [ ] App Store Connect に **アプリのレコードが作成済み**（Bundle ID `com.submana.app`）。無ければ
      「マイApp → ＋ → 新規App」で作成（プラットフォーム iOS、Bundle ID を選択）。

---

## パート A：App Store Connect

### A-1. Paid Apps 契約に同意（未完だと課金は一切動かない）
1. App Store Connect → **契約/税金/口座（Agreements, Tax, and Banking）**。
2. **Paid Applications** 契約に「同意」。
3. **銀行口座**・**税務情報**を登録。ステータスが「有効（Active）」になるまで進める。

### A-2. 課金商品を3つ作成
App Store Connect → 対象アプリ →（左メニュー）**アプリ内課金（In-App Purchases）** / **サブスクリプション**。

**(a) 買い切り（非消耗型）**
1. アプリ内課金 → ＋ → **非消耗型（Non-Consumable）**。
2. **参照名**（内部用・任意）／**製品ID**＝`subsc_pro_lifetime`。
3. **価格**＝¥980。
4. **App内課金の表示名・説明**（日本語ローカライズ）を入力。
5. **審査用スクリーンショット**（ペイウォール画面でOK）と**レビューメモ**を添付。

**(b) 月額・年額（自動更新サブスク）— 1つのグループにまとめる**
1. サブスクリプション → **サブスクリプショングループを作成**（例：`Pro`）。グループ表示名（日本語）を設定。
2. グループ内に ＋ で2つ作成：
   - 製品ID＝`subsc_pro_monthly`、期間＝**1か月**、価格＝¥300。
   - 製品ID＝`subsc_pro_yearly`、期間＝**1年**、価格＝¥1,800。
3. 各サブスクに**表示名・説明**（日本語）、**審査用スクショ／レビューメモ**を添付。
   - ※アプリ内で2週間無料体験を実装済みなので、**Appleの「無料トライアル（Introductory Offer）」は設定不要**。

> どの商品も、作成直後の状態は「準備完了（Ready to Submit）」でOK。アプリのバージョン審査と一緒に提出されます。

### A-3. RevenueCat に渡す「鍵」を用意（どちらか一方）
RevenueCat が Apple のレシートを検証するために必要です。**推奨は In-App Purchase Key**。

- **推奨：In-App Purchase Key（.p8）**
  1. App Store Connect → **ユーザーとアクセス（Users and Access）** → **Integrations（統合）** → **In-App Purchase**。
  2. **鍵を生成** → **.p8 ファイルをダウンロード**（1回しか落とせない）。**Key ID** と **Issuer ID** も控える。
  3. ⚠️ この `.p8` は**秘密鍵**。RevenueCat に貼るだけで、**このリポジトリには絶対に置かない・コミットしない**。
- **代替：App-Specific Shared Secret**
  - 対象アプリ → **App情報** → **App専用共有シークレット（App-Specific Shared Secret）** を生成して控える。

### A-4.（テスト用）Sandbox テスターを作成
- **ユーザーとアクセス → Sandbox → テスター** で、実機テスト用のサンドボックスApple IDを1つ作成。
  （実機で購入フローを試すときに使います。普段のApple IDとは別のメールで。）

---

## パート B：RevenueCat ダッシュボード（無料枠でOK）

### B-1. プロジェクトと App
1. RevenueCat にサインアップ → **Project を作成**。
2. **＋ New app（App Store）** → **App name** 任意、**App Bundle ID**＝`com.submana.app`。
3. **App Store Connect の鍵を登録**：
   - In-App Purchase Key 方式 →（.p8 の内容 / Key ID / Issuer ID）を入力、または
   - Shared Secret 方式 → A-3 の共有シークレットを入力。

### B-2. Entitlement（権利）
1. **Entitlements** → ＋ → **Identifier**＝`premium` を作成。
   - これが「有効なら全機能開放」の唯一の判定。アプリは `premium` だけを見ます。

### B-3. Products（商品）を登録
1. **Products** → ＋ で3つ登録（**App Store Connect と同じ Product ID**）：
   - `subsc_pro_lifetime` / `subsc_pro_monthly` / `subsc_pro_yearly`
2. それぞれを **Entitlement `premium` に紐付け（attach）**。→「どれを買っても premium が有効」。

### B-4. Offering（提示）
1. **Offerings** → **`default`** を作成（無ければ）。
2. **Packages** を3つ追加し、対応する Product を割り当て：
   - Lifetime → `subsc_pro_lifetime`
   - Monthly → `subsc_pro_monthly`
   - Annual → `subsc_pro_yearly`
   - ※アプリのペイウォールは Offering から動的にプランを出します。

### B-5. iOS API キーを控える
1. **API keys**（Project settings）→ **Apple App Store 用の Public SDK key**（`appl_...`）をコピー。
   - これは**クライアント公開キー**（`.p8` のような秘密鍵ではない）。私に渡してOK。

---

## パート C：私に渡す（ここから私が仕上げる）
そろったら次の3つをこのチャットに貼ってください：
1. **RevenueCat の iOS API キー（`appl_...`）**
2. **Product ID**（上の3つのままで良いか。変えたなら新しい文字列）
3. （変更した場合のみ）**利用規約URL / プライバシーポリシーURL**

私が行う仕上げ：
- `PurchaseService` の `useRevenueCat = true` 化＋APIキー設定（`lib/core/monetization/iap.dart` / `PurchaseService`）
- ペイウォールの規約/ポリシーリンクの最終確認
- StoreKit ローカルテスト構成（実機/シミュレータで購入フロー検証）

---

## つまずきやすい点
- **課金が全く出ない/エラー**：A-1 の Paid Apps 契約が「有効」になっていないのが最多原因。
- **Product が RevenueCat に出てこない**：Product ID の綴り違い、または App Store Connect 側が未保存。
- **実機で購入できない**：通常の Apple ID ではなく **Sandbox テスター**でサインインして試す。
- **買い切りの復元**：非消耗型は復元導線が必要 → アプリに実装済み（「購入を復元」）。
- **秘密情報**：`.p8`（In-App Purchase Key / AuthKey）や Shared Secret は**リポジトリに置かない**。
