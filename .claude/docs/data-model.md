# データモデル

永続化は sqflite（`AppDatabase`）。設定はまとめて SharedPreferences。

## テーブル: subscriptions
`Subscription`（`lib/data/models/subscription.dart`）。列名 → 意味:
| 列 | 型 | 意味 |
|---|---|---|
| id | TEXT | UUID |
| name | TEXT | サービス名 |
| amount | REAL | 金額（そのサブスクの通貨建て）。上限 `kMaxAmount`=1億 |
| currency | TEXT | 通貨コード（JPY/USD/EUR/GBP） |
| cycle | TEXT | monthly/yearly/weekly/custom |
| first_payment | INT | 初回支払日（epoch ms） |
| color | INT | アイコン色（ARGB int）→ `sub.color` |
| emoji | TEXT? | 表示文字/絵文字（画像未設定時） |
| category_id | TEXT? | カテゴリ参照 |
| payment_method_id | TEXT? | 支払い方法参照 |
| memo | TEXT? | メモ |
| usage_count / usage_unit | REAL/TEXT | コスパ計算用（月あたり利用回数・単位） |
| is_paused | INT | 0/1 停止中 |
| image_path | TEXT? | アイコン画像の**ファイル名のみ**、または**プリセット参照 `preset:<id>`**（[image 保存](#アイコン画像の保存)。プリセットは `PresetIcons`／`assets/preset_icons/<id>.svg`、id は解約ガイドの `CancelGuideEntry.id` と1:1） |
| notify_days | TEXT | 通知ルール（`NotifyRule.encode`） |
| sort_order | INT | 手動並べ替え順 |
| interval_count / interval_unit | INT/TEXT | cycle=custom のときの「N 日/週/ヶ月」 |
| created_at | INT | 作成 epoch ms |

派生プロパティ: `recurrence` / `periodLabel`（月・年・週・`N単位`）/ `nextPaymentDate` / `daysUntilNextPayment` / `periodProgress` / `monthlyAmount` / `yearlyAmount` / `amountIn(currency)` / `costPerUse` / `displayGlyph`。

**通貨の保存と表示（重要）**: 額は**各サブスクの通貨建てで保存**（編集画面もその通貨のまま）。一方、
**一覧・タイル・カレンダー・履歴・停止中の「表示額」は、設定の"メイン通貨"に換算して出す**
（合計・分析と一致させるため）。換算は `Subscription.amountIn(通貨)` ＝ `CurrencyRates`。共通表示は
`ConvertedAmount`（`lib/core/widgets/converted_amount.dart`。外貨のときだけ元の額を小さく併記）。
為替は起動時に `RatesService`（open.er-api.com）が当日レートを取得、オフライン時はフォールバック
（USD=155 等）を使うため、外貨の円換算値は日々わずかに変動する。

### BillingCycle / IntervalUnit
- `BillingCycle { monthly, yearly, weekly, custom }`
- `IntervalUnit { day, week, month }`（shortLabel: 日/週/ヶ月）
- `Recurrence(count, unit)` に正規化。詳細は [billing.md](billing.md)

## テーブル: categories / payment_methods
`Category` / `PaymentMethod`: id, name, icon(codePoint), color(int), sort_order, is_built_in。
無料枠の上限は `PremiumLimits`（カテゴリ**5** / 支払い方法**5**、プレミアムは無制限）。

## NotifyRule
`NotifyRule(daysBefore, hour=9, minute=0)`。「支払日の N 日前 HH:MM」。`encode/decode` で TEXT 保存。
**1サブスクにつき最大5件**（`PremiumLimits.maxNotifyRules`）。**プレミアム制限ではなく全ユーザー共通の上限**
（課金しても増えない）ため `isPremium` を取る関数ではなく定数。6件目の追加を試みるとフォームがダイアログで
上限を知らせる（ペイウォールは出さない）。上限を下げる前に作られた6件以上のデータは**そのまま保持・通知も従来どおり**
発火し、追加のみブロックされる。

## AppSettings（SharedPreferences）
`settingsProvider`。主なキー: メイン通貨、テーマ色(accent int)、詳細常時表示、停止中表示、並べ替えモード(`SortMode`)。※通知ON(`settings_notify`)は廃止（通知は各アイテムの `NotifyRule` が真実の源）。
その他フラグ: `first_launch_ms`（試用起点）、`is_premium`/`plan_kind`（課金）、`rating_first_add_prompt_shown`、`fx_rates_json`/`fx_rates_date`。

## シードデータ
初回DB作成時に Netflix / Spotify の2件のみ投入（`AppDatabase`）。ユーザー追加とは区別（レビュー誘導はユーザー初回追加時のみ）。

## アイコン画像の保存
`ImagePaths`（`core/utils/image_paths.dart`）。画像は**ファイル名のみ**を保存し、読み出し時に現在のドキュメントディレクトリで解決する。理由: iOS はアプリ再インストール/開発ビルドでコンテナの絶対パスが変わるため、絶対パス保存だと画像が消える。旧データの絶対パスも後方互換で解決可。

## 上限・不変条件
- 金額: 0〜1億。非有限は保存させない（フォーム/CSV両方で担保）
- 初回支払日: 2000〜2100年
- interval_count（custom）: 1〜999
- **サブスク総数: 全ユーザー100件（`PremiumLimits.hardMaxSubscriptions`）**。プレミアム/試用でも超えられないハード上限。事前UI表記なしのサイレント制限で、超過を試みた瞬間のみ警告（フォーム追加・CSV取り込みの両方で担保）。起動時の一覧構築・通知再スケジュールがO(件数)なので、パフォーマンス保護も兼ねる（[architecture.md](architecture.md) の起動コスト参照）
