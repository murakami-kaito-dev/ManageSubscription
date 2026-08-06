# 画面仕様

共通ヘッダー `SoftHeader`: **左スロット=各タブ固有アクション**、中央=タイトル、
**右スロット=設定歯車（`onSettings`）**。歯車は全タブ右上、閉じる/戻るは開いた側に合わせる。

タブ構成: `HomeShell`（ボトムナビ: ホーム/分析/カレンダー/支払い履歴）＋ 各タブ上に
アプリ内リマインダー（`ForegroundReminderHost`）が重なる。

---

## ホーム（`features/home/home_screen.dart`）
- ヘッダー: 左=「…」メニュー（`showSubscriptionSettingsSheet` = 表示/管理/並べ替え）、右=歯車（設定）
- 「今月の合計」カード: 当月請求合計（メイン通貨換算）。巨大でも `FittedBox` で自動縮小
- サブスク一覧: `SubscriptionTile`（アイコン=`SubscriptionAvatar`、名称、次回支払日、金額/周期、支払いまで残日数、下部にゲージ=`periodProgress`）
- タップ→編集画面（`SubscriptionFormScreen(existing:)`）。右下 FAB→新規追加
- 並べ替え/停止表示は「…」シート（`subscription_settings_sheet.dart`）で設定

## 分析（`features/analytics/analytics_screen.dart`）
- 月間/年間タブ（下線式）。軸セレクタ: サブスク別 / カテゴリー別 / 支払い方法別（後2つはプレミアム）
- ドーナツ（`donut_chart.dart`）: 各スライスは**アイテム固有色**。ラベル文字は黒固定
- タップでスライス選択→中心に「名前＋割合%」、下部リスト該当行をアイテム色で薄くハイライト。再タップ解除
- 長押し: サブスク別→そのまま編集画面へ / カテゴリ・支払い方法別→内訳シート
- サブスク別のときコスパチェッカー一覧も表示
- 非有限値はガードして必ず描画。中心合計は `FittedBox`

## カレンダー（`features/calendar/calendar_screen.dart`）
- `table_calendar`（locale ja）。各日に支払いドット（アイテム色）。上部に当月合計（`FittedBox`）
- 選択日の支払い一覧。行は長押しで編集画面へ
- 無料枠: 当月のみ閲覧、過去/未来はプレミアム誘導

## 支払い履歴（`features/history/history_screen.dart`）
- 月間/年間タブ（分析と同じ下線式、ヘッダー下）
- 棒グラフ（`history_bar_chart.dart`）: 1期間1本。**グレー=予定額 / テーマ色=支払い済み（当日以前）をスタック**
- 下部リストは**未来（未到来）の支払いを除外**。合計も支払い済みベース（`FittedBox`）
- 行は長押しで編集画面へ。年間はプレミアム

## 新規追加/編集（`features/subscription/subscription_form_screen.dart`）
- ヘッダー左に戻る矢印。保存バー下部固定
- 基本情報: サービス名 / 金額（**右揃え・3桁カンマ・上限1億・プレースホルダ「1,000」**）/ 通貨
- 支払いサイクル（月/年/週/カスタム）＋カスタムは数値タップで縦ホイール（1〜999）＋±ボタン。初回支払日（ピッカー 2000〜2100、範囲外はクランプ）
- 通知ルール（N日前 HH:MM、無料1件）
- メモ、状態（停止中トグル・編集時）、削除
- 詳細設定（折りたたみ）: アイコン（画像/文字＋背景色）、カテゴリ、支払い方法、コスパ
- 入力欄は Live Text（カメラ文字認識）を無効化
- **保存時**: 新規作成かつレビュー未表示なら初回追加レビュー誘導ポップアップ（[rating-share.md](rating-share.md)）

## 設定（`features/settings/settings_screen.dart`）
- フルスクリーンダイアログ。閉じる×は**右上**（開く歯車と同じ側）
- プレミアムバナー: 試用残日数 or 現在プラン。無料時はペイウォール誘導
- 「設定」: 通知ON/OFF、メイン通貨、テーマカラー（3列固定グリッド）、CSVエクスポート、CSVから読み込み、CSVの書式・サンプル
- 「アプリ」: このアプリを応援する（ストア評価）、シェア（ストアURL入り）、ご意見・ご要望（`feedback_sheet`）
- 版数長押しでデバッグ: プレミアム切替

## ペイウォール（`features/premium/premium_screen.dart`）
- 3プラン選択（年額おすすめ/月額/買い切り）＋試用状況バナー。購入/復元/利用規約/プライバシーポリシー
- 詳細は [monetization.md](monetization.md)

## CSVインポート関連
- プレビュー画面 `csv_import_screen.dart`、書式ヘルプ `features/csv/csv_import_help_screen.dart`。詳細は [csv-import.md](csv-import.md)

## サブスクリプション設定シート（`subscription_settings_sheet.dart`）
- ホームの「…」から開くボトムシート。閉じ×は**左上**、タイトル中央
- 表示（停止中を表示）/ 管理（カテゴリー・支払い方法・停止中一覧）/ 並べ替え
