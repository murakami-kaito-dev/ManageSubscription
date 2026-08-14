# 画面仕様

共通ヘッダー `SoftHeader`: **左スロット=各タブ固有アクション**、中央=タイトル、
**右スロット=設定歯車（`onSettings`）**。歯車は全タブ右上、閉じる/戻るは開いた側に合わせる。

タブ構成: `HomeShell`（ボトムナビ: ホーム/分析/カレンダー/支払い履歴/解約方法）＋ 各タブ上に
アプリ内リマインダー（`ForegroundReminderHost`）が重なる。

---

## ホーム（`features/home/home_screen.dart`）
- ヘッダー: 左=「…」メニュー（`showSubscriptionSettingsSheet` = 表示/管理/並べ替え）、右=歯車（設定）
- 「今月の合計」カード: 当月請求合計（メイン通貨換算）。巨大でも `FittedBox` で自動縮小
- サブスク一覧: `SubscriptionTile`（アイコン=`SubscriptionAvatar`、名称、次回支払日、金額/周期、支払いまで残日数、下部にゲージ=`periodProgress`）
- タップ→編集画面（`SubscriptionFormScreen(existing:)`）。右下 FAB→新規追加
- 並べ替え/停止表示は「…」シート（`subscription_settings_sheet.dart`）で設定
- **登録上限（サイレント）**: 合計100件（`PremiumLimits.hardMaxSubscriptions`）。UIに事前表記はせず、101件目を追加しようとした瞬間だけ警告ダイアログ。無料枠ゲート（`maxSubscriptions=8`）より前にチェック
- **複数選択・一括削除**: 「…」シートの「選択して削除」で選択モードに入る（状態は `home_selection_provider.dart`）。選択モード中はヘッダーが「N件を選択」に変わり、左=閉じる（`exit`）、右=全選択/全解除。各行は先頭チェック付きの `_SelectableTile`（タップでトグル・並べ替え/合計カードは非表示）。下部の `_DeleteBar`（危険色）でまとめて削除→確認ダイアログ→`SubscriptionsNotifier.deleteMany`

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
- 月間の下部リストは**「支払い済み」/「支払い予定」の2セクション**（`monthPaymentsProvider` が各支払いに `paid=!date.isAfter(today)` を付与＝棒グラフと同基準）。**支払い予定（未払い）は半透明**（`Opacity 0.5`）表示。各セクションが空なら「支払い済み/支払い予定アイテムはありません」のプレースホルダを出す。見出しの合計は支払い済みベース（棒グラフのテーマ色部分と一致）
- 年間の下部リストは支払い済みの年間集計（`yearSubscriptionTotalsProvider`・据え置き）。行は長押しで編集画面へ。年間はプレミアム

## 解約方法（`features/cancellation/cancel_guide_screen.dart`）
- 公式の解約ページへ飛ぶだけの**静的リンク集**（`cancel_guide_data.dart` の `kCancelGuideEntries`）。通信・データ収集なし
- 上から: 説明カード「公式の解約ページを開きます／このアプリで解約の手続きはできません」→ 検索欄（名称・カナ別名で絞り込み）→ カテゴリー別リスト
- カテゴリー順: 登録先（App Store / Google Play）→ 動画 → 音楽 → 仕事・AI・クラウド → ゲーム → 読書・雑誌・生活 → このアプリ（計39サービス）。**登録先が最上段**（アプリ内課金の解約先はサービスのサイトではないため）
- 行タップ→ボトムシート: 「どこから解約するか」/「解約する前に」/ `SoftButton`「公式の解約ページを開く」（`url_launcher` で外部ブラウザ、失敗時はスナックバー）
- **手順は書き写さない・「このアプリから解約できる」とは言わない**（詳細は [feature-cancellation-guide.md](feature-cancellation-guide.md)）

## 新規追加/編集（`features/subscription/subscription_form_screen.dart`）
- ヘッダー左に戻る矢印。保存バー下部固定
- 基本情報: サービス名 / 金額（**右揃え・3桁カンマ・上限1億・プレースホルダ「1,000」**）/ 通貨
- 支払いサイクル（月/年/週/カスタム）＋カスタムは数値タップで縦ホイール（1〜999）＋±ボタン。初回支払日（ピッカー 2000〜2100、範囲外はクランプ）
- 通知ルール（N日前 HH:MM、無料1件）
- メモ、状態（停止中トグル・編集時）、削除
- 詳細設定（折りたたみ）: アイコン（画像/文字＋背景色）、カテゴリ、支払い方法、コスパ
- 入力欄は Live Text（カメラ文字認識）を無効化
- **保存時**: 新規作成かつレビュー未表示なら **OS標準のレビュー画面を直接表示**（自前ポップアップは廃止。[rating-share.md](rating-share.md)）

## 設定（`features/settings/settings_screen.dart`）
- フルスクリーンダイアログ。閉じる×は**右上**（開く歯車と同じ側）
- プレミアムバナー: 現在プラン（有料時）。無料時はペイウォール誘導（試用カウントダウンは無し＝インストール直後は無料プラン）
- 「設定」: メイン通貨、テーマカラー（3列固定グリッド）、CSVエクスポート、CSVから読み込み、CSVの書式・サンプル ※通知の全体ON/OFFトグルは廃止（通知は各アイテムで設定）
- 「アプリ」: このアプリを応援する（ストア評価）、シェア（ストアURL入り）、ご意見・ご要望（`feedback_sheet`）
- 版数長押しでデバッグ: プレミアム切替

## ペイウォール（`features/premium/premium_screen.dart`）
- 閉じる **✗ は右上**（設定画面と統一）。Hero は実アプリアイコン（`assets/icon/icon.png`）
- 3プラン選択（年額おすすめ/月額/買い切り）＋状態バナー（無料 or 現プラン）＋無料/プレミアム比較表。購入/復元/利用規約/プライバシーポリシー
- サブスクは「2週間無料で始める」（App Store 導入オファー）。詳細は [monetization.md](monetization.md)

## 上限超過ロック（`features/premium/limit_gate.dart`）
- 無料ユーザーが上限超過アイテムを持つ場合、シェル全体を「整理 or アップグレード」画面に置換。
  その場で削除／プレミアム登録／復元でき、上限内に戻れば自動解除（[monetization.md](monetization.md)）

## CSVインポート関連
- プレビュー画面 `csv_import_screen.dart`、書式ヘルプ `features/csv/csv_import_help_screen.dart`。詳細は [csv-import.md](csv-import.md)
- 取り込みで100件を超える場合は**行ごとにチェックボックス**を出し、ユーザーが取り込む行を選ぶ。全選択は**全件**を選び（上限超過は赤字カウンタで許容・取り込みボタン非活性）、残り枠以内に絞ると活性。収まる場合は全件そのまま取り込み

## サブスクリプション設定シート（`subscription_settings_sheet.dart`）
- ホームの「…」から開くボトムシート。閉じ×は**左上**、タイトル中央
- 表示（停止中を表示）/ 管理（**選択して削除**・カテゴリー・支払い方法・停止中一覧）/ 並べ替え
- 「選択して削除」→シートを閉じてホームを選択モードに（`homeSelectionProvider.enter()`）
