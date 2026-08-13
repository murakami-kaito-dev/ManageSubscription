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
- `services/` — ads / csv / currency / image / notifications / purchases / rating

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
