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
- [x] **Bundle ID `com.submana.app` は登録済み**（2026-08、Claude が ASC API で登録。name: Submana / id: `Y3NRAJ84RM`）。
- [ ] App Store Connect に **アプリのレコードを作成**（マイApp → ＋ → 新規App）。Bundle ID は上記を選ぶだけ。

---

## パート A：App Store Connect

### A-1. Paid Apps 契約に同意（未完だと課金は一切動かない）
1. App Store Connect → **契約/税金/口座（Agreements, Tax, and Banking）**。
2. **Paid Applications** 契約に「同意」。
3. **銀行口座**・**税務情報**を登録。ステータスが「有効（Active）」になるまで進める。

### A-2. 課金商品を3つ作成
> ✅ **実施済み（2026-08-08、Claude が ASC API で作成）**：App ID `6799400490` に
> `subsc_pro_lifetime`（買い切り、日本語名・**¥980 価格まで完了**）／サブスクグループ `Pro` ＋
> `subsc_pro_monthly`・`subsc_pro_yearly`（日本語名まで完了）。
>
> ⚠️ **サブスク2商品の「初期価格」（¥300 / ¥1,800）だけは API で設定できない**（Apple の既知の制約：
> 自動更新サブスクの初期価格は `subscriptionPrices` API がエラーになる。IAP は設定可）。
> → **ASC の UI で一度だけ価格を設定**する（下記 A-2b）。以降の価格変更は API でも可能。

#### A-2b. サブスク価格をUIで設定（あなた・各30秒）
1. App Store Connect → アプリ「サブスク家計簿」→ **サブスクリプション** → グループ `Pro`。
2. `月額プラン（subsc_pro_monthly）` を開く → **サブスク価格** → 「価格を設定」→ 国/地域は日本基準、
   **¥300** を選択 → 保存。
3. `年額プラン（subsc_pro_yearly）` も同様に **¥1,800** を設定。
   - 日本の価格を選ぶと他地域は自動で均等価格が入る。

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

> **役割分担**：B-1（アカウント/プロジェクト作成・App追加・App Store 鍵の登録）は
> **本人のみ**（ログイン・秘密情報の入力のため Claude 代行不可）。
> B-2〜B-4（Entitlement `premium`・Products 紐付け・Offering `default`）は、
> RevenueCat の **Secret API key（v2）を Claude に渡せば API で代行可能**。UIで自分でやってもOK。
> アプリに埋める **Public SDK key（`appl_...`）** は必ず Claude に渡すこと（`useRevenueCat=true` 化に必要）。

### B-1. プロジェクトと App（本人・詳細手順）
1. RevenueCat にサインアップ → **Project を作成**（作成済みならスキップ）。
2. **App を追加**：Project settings（歯車）→ **Apps** → **＋ New**（または「Add app」）→ **App Store** を選択
   → App name 任意、**Bundle ID＝`com.submana.app`** → 保存。
3. **In-App Purchase Key を登録**（レシート検証に必須。ASC APIキーとは別物・専用に新規生成する）：
   - App Store Connect → **ユーザーとアクセス** → **Integrations（統合）** タブ → 左 **In-App Purchase（アプリ内課金）**
     → **Generate In-App Purchase Key**（または＋）→ 名前（例 `RevenueCat`）→ 生成 → **Download API Key**（.p8、DLは1回だけ）。
     この画面**上部の Issuer ID** と、鍵行の **Key ID** を控える。
   - RevenueCat → **Apps** → 対象App → **In-app purchase key configuration** タブ → **.p8 をアップロード**＋**Issuer ID** を入力 → **Save**。
   - ⚠️ この `.p8` は秘密鍵。RevenueCat に入れるだけで、**リポジトリや Claude には渡さない**。
4. **鍵を2つ控える**（Project settings → **API keys**）：
   - **Public SDK key**（App specific keys の `appl_...`）… アプリ埋め込み用 → Claude へ。
   - **Secret API key（v2）**… B-2〜B-4 を Claude に代行させる場合に発行 → Claude へ（任意）。

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

---

# パート D：App Store 申請の残作業（本人・UIクリック手順）

前提（Claude が API 済み）：3商品 READY_TO_SUBMIT／ビルド2をv1.0へ紐付け／説明・キーワード・サポートURL・
プライバシーURL・コンテンツ権利・輸出コンプライアンス 設定済み。残りを ASC UI で行う。

## D-1. カテゴリ（アプリ全体）
1. App Store Connect → **アプリ** → 「サブスク家計簿」→ 左サイド **App情報**
2. 「一般情報」の **カテゴリ** → プライマリ＝**ファイナンス**（サブに「ユーティリティ」でも可）→ 右上 **保存**

## D-2. 年齢レーティング（アプリ全体）
1. 同じ **App情報** ページの **年齢制限指定** → **編集**
2. すべての項目を「**なし**」／「**いいえ**」で回答（暴力・性的・ギャンブル等すべて該当なし）→ **完了** → **保存**
   → 判定は **4+** になる

## D-3. 価格＝無料（アプリ全体）
1. 左サイド **価格および配信状況**
2. **価格** → 「価格スケジュール」→ **無料（¥0 / Free）** を選択 → **保存**
3. （下の「App の配信可否」は全地域のままでOK）

## D-4. スクリーンショット（バージョン1.0のページ）
1. 左サイドのプラットフォーム下 **iOS版 1.0（提出準備中）** をクリック
2. 「**App プレビューとスクリーンショット**」→ タブで **iPhone 6.9インチディスプレイ** を選択
3. **1290×2796 か 1320×2868** のPNG/JPGを 1枚以上ドラッグ&ドロップ
   - ペイウォール画像は用意済み（`…/scratchpad/paywall_final2.png`＝¥表記）だが、サイズが6.9型と異なる場合あり。
     実機（この端末）でホーム・分析・カレンダー・ペイウォール等を撮って入れるのが確実。最低1枚で審査は通る。
4. 6.5インチ枠は「6.9で入れた画像を流用」ボタンが出れば流用可

## D-5. App のプライバシー（アプリ全体・**本人の申告**）
1. 左サイド **App のプライバシー** → **編集/開始**
2. 「このAppはデータを収集しますか？」→ **はい**
3. データの種類を選択（RevenueCat連携が実態）：
   - **購入（Purchases / 購入履歴）**：用途＝**Appの機能**／ユーザIDに**リンクしない**／トラッキング**しない**
   - **識別子（Identifiers / デバイスID）**：用途＝**Appの機能**／**リンクしない**／トラッキング**しない**
   - ※メール・氏名・位置情報・連絡先・利用状況アナリティクスは**収集していない**ので選ばない
4. **公開** で確定（この申告は法的責任があるため内容は必ず自分で確認）

## D-6. 課金商品を「審査用に追加」（初回は本体と同時提出）
1. **アプリ内課金**（または各商品ページ）で `subsc_pro_lifetime` / `subsc_pro_monthly` / `subsc_pro_yearly` を開く
2. 各ページ右上の **審査用に追加** を押す（3商品とも）→ v1.0 の提出に含まれる

## D-7. 提出
1. バージョン1.0 ページ右上 **審査へ追加 → 提出**
2. 輸出コンプライアンス：Info.plist で申告済みのため質問は出ない想定（出たら「いいえ（免除）」）
3. 「コンテンツ配信権」等の確認に回答 → **提出**
   → ステータスが **審査待ち（Waiting for Review）** になれば完了
