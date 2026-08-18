# アーキテクチャ

## 技術スタック
- **Flutter**（Dart）。iOS/Android。UI は `Locale('ja')` 固定
- **Riverpod**（flutter_riverpod）— 状態管理
- **sqflite** — サブスク/カテゴリ/支払い方法の永続化
- **SharedPreferences** — 設定・フラグ（試用開始日、テーマ色、レビュー表示済み等）。※アプリ全体の通知ON/OFFは廃止（通知は各アイテムのルールが真実の源）
- 主なパッケージ: fl_chart（グラフ）, table_calendar（カレンダー）, flutter_local_notifications ＋ flutter_timezone（通知）, image_picker ＋ image_cropper（アイコン画像）, file_picker（CSV選択）, csv（CSV入出力）, share_plus（共有）, purchases_flutter（RevenueCat）, in_app_review（評価）, http（為替・フィードバック）, url_launcher（規約/ポリシー）

## レイヤ構成（`lib/`）
- `main.dart` — 起動時初期化（DB/prefs/画像パス/為替/購入の順）、`ProviderScope` overrides。**通知の再スケジュールは `runApp` の後に fire-and-forget で実行**（起動クリティカルパスから外す。[起動コスト](#起動コストとスケール)参照）
- `app.dart` — `MaterialApp`。テーマ・日本語ローカライズ。`builder` で `ForegroundReminderHost` を全画面の上に被せる。`home: HomeShell`
- `core/` — テーマ（`app_colors`/`AppAccent`/`app_typography`/`app_spacing`/`app_shadows`）、`utils/`（billing・currency・amount_input・image_paths・dates・text_input）、`monetization/iap.dart`、`store_links.dart`、`legal.dart`、`premium_limits.dart`、`dev_config.dart`、共通 `widgets/`
- `data/` — `database/app_database.dart`（スキーマ+シード）、`models/`、`repositories/`
- `providers/` — `core_providers`（DB/prefs/サービス）、`subscription_providers`、`analytics_providers`、`settings_provider`、`premium_provider`
- `features/` — 画面ごと（home / subscription（編集/追加）/ analytics / calendar / history / csv（取込UI）/ settings / premium / rating / notifications / shell）
- `services/` — ads / csv / currency / image / notifications / purchases / rating / widget

## ホーム画面ウィジェット（iOS WidgetKit）
- **データの流れ**: `widgetSyncProvider`（`app.dart` で watch）が `subscriptionsProvider` と
  メイン通貨を `ref.listen`（`fireImmediately: true`）→ 変化のたびに
  `buildWidgetPayload()`（`services/widget/widget_payload.dart`・純関数・テスト有）で
  JSON を組み立て → `WidgetBridge.update()`（`services/widget/widget_bridge.dart`、
  MethodChannel `submana/widget`・専用パッケージ不使用）→ ネイティブ
  （`ios/Runner/AppDelegate.swift`）が **App Group** `group.com.submana.app` の
  UserDefaults に保存し `WidgetCenter.reloadTimelines`。
- **表示ルールはアプリと同一**: 合計=停止中を除く `monthlyAmountIn(メイン通貨)` 総和、
  アイテム額もメイン通貨換算。日付・「あと◯日」は **Swift 側がタイムライン
  （今＋7日分の深夜0時）で毎日再計算**するので、アプリを開かない日もラベルが進む。
- **ネイティブ側**: `ios/SubmanaWidget/`（SwiftUI・systemSmall/Medium。ベース配色は
  claymorphism パレットの固定移植、**アクセント色は設定のテーマ色に追従**——ペイロードに
  `accent`/`accentDeep`（hex）を載せ、deep の導出は `AppAccent.from` と同一ロジック）。Xcode ターゲット `SubmanaWidget`
  （bundle id `com.submana.app.widget`、Info.plist の版数は `$(FLUTTER_BUILD_NAME)/
  $(FLUTTER_BUILD_NUMBER)`＝アプリと自動同期）。App Group entitlements は
  `Runner/Runner.entitlements` と `SubmanaWidget/SubmanaWidget.entitlements`。
  拡張にも `PrivacyInfo.xcprivacy`（UserDefaults CA92.1）を同梱。
- **⚠️ リリース時の一回だけの署名作業**: 新 bundle id `com.submana.app.widget` と
  App Group の Developer Portal 登録が必要（`xcodebuild -allowProvisioningUpdates`
  ＋ASC APIキー、または Xcode を一度開いて自動署名に解決させる）。

## 主要 Provider（この名前で参照される）
- `databaseProvider` / `prefsProvider` / `purchaseServiceProvider` — main() で override
- `subscriptionsProvider`（`AsyncNotifier<List<Subscription>>`）: `.save` / `.saveAll` / `.delete` / `.deleteMany` / `.setPaused` / `.reorder`
- `visibleSubscriptionsProvider` — 表示用（停止中フィルタ＋並べ替え）
- `subscriptionCountProvider`
- `categoriesProvider` / `paymentMethodsProvider` と `…MapProvider`（id→エンティティ）
- `analyticsProvider(AnalyticsQuery)` / `analyticsMembersProvider` / `monthlyHistoryProvider` / `yearlyHistoryProvider` / `monthPaymentsProvider` / `yearSubscriptionTotalsProvider`
- `settingsProvider`（`Notifier<AppSettings>`）— 通貨/テーマ色/通知ON/表示設定/並べ替え/停止表示
- `premiumProvider`（bool = 有料 or 試用中 or dev）/ `entitlementProvider`（プラン+試用残日数）
- サービス: `notificationServiceProvider` / `csvExportServiceProvider` / `csvImportServiceProvider` / `imagePickerServiceProvider` / `ratingServiceProvider` / `adServiceProvider`
- `widgetSyncProvider` — ホーム画面ウィジェットへの同期（上記「ホーム画面ウィジェット」参照）
- `sessionRestoreProvider`（`SessionRestore`）— **jetsam 対策のセッション復元**。iOS は背面アプリを
  メモリ圧力で数分でも kill する（防止不可）ため、「最後に開いていたタブ」と「編集フォームの
  下書き」を SharedPreferences（`restore_*`）に退避し、**30分以内の再起動でだけ**復元する。
  タブ＝`HomeShell`（タップ時保存・起動時復元・背面時に鮮度スタンプ）。下書き＝フォームが
  背面に回る瞬間（`didChangeAppLifecycleState`）に保存し、`dispose`（＝ユーザーが自分で
  閉じた）と鮮度切れで破棄。復元時は `HomeShell` が post-frame でフォームを draft 付きで push。

## テーマ
- `AppAccent`（primary/deep/soft）はユーザー選択のテーマ色から算出。`AppAccent.of(context)` で参照
- サブスクのアイコン/円グラフ等は**各アイテム固有の色**（`sub.color`）を使用（テーマ色ではない）
- claymorphism（`SoftCard` / `SoftButton` / `SoftHeader` / `Pressable` / 影）

## 起動コストとスケール
「アプリのバイナリは約70MBなのに、件数が増える（例: 1億円×1000件）と起動が極端に遅くなる／起動しない」件の技術的な原因。**バイナリサイズ（≒70MB）は無関係**——ダウンロード/インストール時の一度きりのコストで、起動速度に効くのは「起動時に何件ぶんのデータを、メインスレッドで何回処理するか」。件数に対して線形（O(n)）以上に効く箇所が起動を支配する。

1. **通知の再スケジュールが O(件数) でメインを塞いでいた（最大の原因）**
   `NotificationService.rescheduleAll` はサブスク1件ごとに `zonedSchedule`（＝プラットフォームへの MethodChannel 往復）を呼び、通知にアイコン画像を添付するため**1件ごとにテンポラリへ画像コピー（ディスクI/O）**まで走る。これを以前は `runApp` の**前で await** していたため、件数×(チャンネル往復＋ファイルコピー)が終わるまで最初のフレームが描けない＝「起動しない」ように見えた。加えて iOS は保留通知に**64件の上限**があり、それ以上は無駄な試行になる。
   → 対策: `runApp` を先に呼び、再スケジュールは**後追いの fire-and-forget**（`main.dart`）に移動。起動のクリティカルパスから外した。

2. **一覧を全件いっぺんに build していた**
   ホームの非手動ソート表示は全タイルを `Column` に一括生成。各 `SubscriptionTile` は `periodProgress` 等の請求計算に加え、アイコン解決で `File.existsSync`（同期ディスクI/O）を行う。件数が増えるほど初回レイアウトが重くなる（`ListView.builder` の遅延生成が効かない構造）。

3. **メモリ**
   全 `Subscription` をメモリ常駐し、派生プロバイダ（可視一覧・分析・履歴）が件数に比例して再計算。金額の桁（1億）は `double` なので**桁が大きくても1件あたりのコストは一定**——効くのは金額の大きさではなく**件数**。

**恒久対策＝100件のハード上限**（`PremiumLimits.hardMaxSubscriptions`、[data-model.md](data-model.md)）。上の1〜3すべてを定数で有界化し、起動が件数で暴れないことを保証する。あわせて（1）の再スケジュールも非同期化済み。将来さらに伸ばすなら、一覧の `ListView.builder` 化・アイコン存在チェックのキャッシュ・通知の間引き（次回分だけスケジュール）が候補。

## エラー耐性の原則
- 金額など非有限値（Infinity/NaN）は表示側（`CurrencyFormatter`・ドーナツ・`FittedBox`）でフォールバック
- CSV は「解析→プレビュー→確定」で、不正行はスキップ。DB破壊はしない
- 日付計算は fast-forward で長スパンでも正確（[billing.md](billing.md)）
