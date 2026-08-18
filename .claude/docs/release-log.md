# リリースログ（バージョン・ビルド番号の履歴）

バージョン／ビルド番号が動いたら**その場で**ここに追記する。運用ルールは
グローバルスキル `release-log` を参照。新しいものが上。

- **ビルドしただけ**と**配信した**は必ず区別する
- 秘密情報（APIキー・Issuer ID・証明書）は書かない

---

## 2.1.0 (build 15) — 2026-08-16 · App Store（★現行の公開版）

build 14 の審査提出後に「正方形(small)ウィジェットは1件しか出ない」改善要望が出たため、
**build 14 の審査は取り下げ**、修正を込めて同じ 2.1.0 の build 15 として再提出した。

- **fix**: small ウィジェットでも支払い予定を最大4件表示（合計22pt化・見出し省略で4行確保）

**配信**: App Store Connect にアップロード（Delivery UUID `acd63e58-aab5-4f80-b2a7-e14f05001ab1`）。
ビルド処理 VALID → 既存バージョン 2.1.0（文面は build 14 提出時のまま）に build 15 を紐付け →
再提出（reviewSubmission `affea3c9…`）。タグ `v2.1.0` = `8a875e0`（付け直し）
**状態**: **公開済み（`READY_FOR_SALE`）＝いま App Store にある最新版はこれ**。
2026-08-16 再提出 → 審査通過（reviewSubmission `affea3c9…` = COMPLETE）→
`releaseType=AFTER_APPROVAL` により自動配信（ASC API で 2026-08-18 に確認）

## 2.1.0 (build 14) — 2026-08-16 · App Store Connect（審査取り下げ）

- **ホーム画面ウィジェット（iOS WidgetKit）を新規追加**。small=今月の合計＋次の支払い1件、
  medium=上段に今月の合計・下段に支払い日が近い順4件（名前/M月d日/あと◯日/金額を全幅表示）。
  額はメイン通貨換算・「あと◯日」はウィジェット側で毎日再計算・アクセント色はアプリの
  テーマカラーに追従。実装詳細は [architecture.md](architecture.md) の「ホーム画面ウィジェット」
- 「解約方法」の収録を **46 → 48件** に拡張（スカパー！[加入約256万件]・
  エニタイムフィットネス[会員100万人超]。いずれも公式導線を確認して収録）
- 新ターゲット `SubmanaWidget`（bundle id `com.submana.app.widget`）・App Group
  `group.com.submana.app` を導入（Developer Portal 登録は実機ビルド時に解決済み）

**配信**: App Store Connect にアップロード（Delivery UUID `9141b4db-a4dc-499a-98cc-c15ce8c5494a`）。
ビルド処理 VALID → バージョン 2.1.0 作成 → What's New（開発者確認済み文面）＋プロモ引き継ぎ →
build 14 紐付け → 審査提出（reviewSubmission `4dc2a473…`）
**状態**: **審査取り下げ（開発者都合・2026-08-16）**。small ウィジェット4件表示の修正を
込めるため。同版 2.1.0 は build 15 で再提出（上のエントリ参照）
**⚠️ 禁忌チェック**: 購入経路コードは 2.0.0 から無変更（公開中の版と同一）。デバッグ導線
`kDebugMode` ガード済・共有リンク `6799400490` 確認済

## 2.0.1 (build 13) — 2026-08-16 · App Store（公開済み・旧版）

2.0.0 公開の直後に出した小改修。2点。

- **一覧の表示額をメイン通貨に換算**して表示するよう統一（ホームタイル／カレンダー日別／
  支払い履歴／停止中一覧）。外貨アイテムは元の額（例 `$110.00`）を小さく併記。合計・分析は
  従来からメイン通貨換算なので、これで全画面が一致する。**編集画面の設定通貨表示は変更なし**。
  共通表示 `ConvertedAmount`（`lib/core/widgets/converted_amount.dart`）を新設、ウィジェットテスト追加。
- 「解約方法」タブの収録を **39 → 46件**に拡張（会員数の定量根拠に基づき DMM TV / ニコニコ
  プレミアム / LYP プレミアム / X Premium / スタディサプリ / Duolingo / chocoZAP を追加。
  新カテゴリ「学び・教育」「フィットネス・健康」）。

**配信**: App Store Connect にアップロード（Delivery UUID `33cfa679-5e3e-45f1-9e88-b7aade911e6e`）。
ビルド処理 VALID → バージョン 2.0.1 作成 → What's New 設定＋プロモーションは 2.0.0 から引き継ぎ →
build 13 紐付け → **審査提出**（reviewSubmission `9471b3ae…`）。
**状態**: 公開済み（`READY_FOR_SALE`、公開日 2026-08-16 JST。その後 2.1.0 に置き換え。現行は 2.1.0）。
審査は 2026-08-16 提出 → 即日承認・自動配信（`AFTER_APPROVAL`）。
提出前チェック: analyze 0 / test 緑、デバッグ導線 `kDebugMode` ガード済、共有リンク `6799400490` 確認済。
サブスク購入は 2.0.1 で経路コード無変更（＝公開中の 2.0.0 と同一）。タグ `v2.0.1` = `076dbea`。
**メモ**: 追加7件の解約 URL は Web 確認済・実機到達確認は未実施（次リリース前にまとめて）。

## 2.0.0 (build 12) — 2026-08-14 · App Store（公開済み・旧版）

build 8〜11 の全機能を束ねたメジャーバージョン。機能追加は無く、以下の審査用対応のみ。

- **`ios/Runner/PrivacyInfo.xcprivacy` を新規作成**（従来は**存在しなかった**）。
  トラッキング無し／データ収集無し／Required Reason API は UserDefaults(CA92.1) と
  FileTimestamp(C617.1) を申告。`project.pbxproj` の Resources ビルドフェーズにも登録した
  （登録しないとバンドルに入らない）。`Payload/Runner.app/PrivacyInfo.xcprivacy` として
  同梱されていることを確認済み
- バージョン表記を 1.3.0 → 2.0.0（設定画面フッターも同時更新）

**配信**: App Store Connect にアップロード（Delivery UUID `0967ca3f-da9a-4916-8986-f8898cf06099`）。
タグ `v2.0.0` = `c85915a`
**状態**: 公開済み（2026-08-15 JST に承認・公開 → 翌日 2.0.1 に置き換え。現行は 2.0.1）。
提出前チェック 3点（購入実機確認 / IDFA・App Privacy 見直し / 前回審査の状況）は提出前に消化済み。

## 1.3.0 (build 11) — 2026-08-14 · TestFlight

- **画像のメモリ消費を約97%削減**。`Image` は `width`/`height` を指定しても元解像度のまま
  展開されるため、表示サイズ相当の `cacheWidth` を指定するよう修正
  （アバター48pt統一 / ペイウォール110pt / 編集プレビュー72pt）。
  併せて `imageCache` の上限を 100MB・1000枚 → 16MiB・200枚に変更。
  画像アイコン8件の環境で **約52MiB → 約1.4MiB**。表示は1pxも変わらない
- **未保存の入力を破棄する前に確認ダイアログ**を表示（新規追加・編集の両方）。
  ヘッダーの戻る矢印とシステムの戻る操作の両方を `PopScope` で受ける
- **広告(AdMob)を依存ごと無効化**（削除ではなくコメントアウト。復活手順は
  `lib/services/ads/ad_service.dart` の先頭）。アプリサイズ 42.9MB → 36MB

**配信**: TestFlight にアップロード
**状態**: 審査未提出
**メモ**: 広告はもともと `kAdsEnabled = false` で動いておらず、メモリ削減効果はほぼ無し。
効いたのはアプリサイズ。「数分でOSに終了される」症状への本命は画像のデコードサイズ修正

## 1.3.0 (build 10) — 2026-08-14 · TestFlight

- iOS の最低対応バージョンを **13.0 → 15.0** に引き上げ
  （altool 警告 90068 対応。2027年春以降、15.0 未満はアップロード自体が拒否される）
- 変更箇所4つ: `ios/Podfile`（`platform` と `post_install` の全Pod強制指定）／
  `ios/Runner.xcodeproj/project.pbxproj`（Debug・Release・Profile の3構成）／
  `ios/Flutter/AppFrameworkInfo.plist`
- `pod install` 実行済み（24 pods 再構成）

**配信**: TestFlight にアップロード（Delivery UUID `63d1f426-175f-4224-ad40-2611326ee426`）
**状態**: 審査未提出
**メモ**: このビルドで警告90068 が消え、検証・アップロードとも
`SUCCEEDED with no errors`（警告0）になった

## 1.3.0 (build 9) — 2026-08-14 · TestFlight

- 「解約方法」タブの収録サービスを **23 → 39** に拡張
  - AI・仕事: Claude Pro / Max、Dropbox、Canva Pro、Notion、GitHub Copilot
  - ゲーム（新カテゴリ）: Nintendo Switch Online、PlayStation Plus、Xbox Game Pass
  - 動画: Lemino、FOD、TELASA、WOWOW
  - 音楽: LINE MUSIC
  - 読書・雑誌・生活（カテゴリ改称）: Audible、日経電子版、Uber One
- 全URLを到達確認のうえ収録

**配信**: TestFlight にアップロード（Delivery UUID `04029b91-f854-4bc0-9e02-1c4dfcb8b2de`）
**状態**: 審査未提出
**メモ**: 警告90068（MinimumOSVersion 13.0）が出た → build 10 で対応

## 1.3.0 (build 8) — 2026-08-14 · TestFlight

- **「解約方法」タブを新設**（ボトムナビ5つ目）。主要サブスク23件の公式解約ページへ
  リンク遷移するだけの静的リンク集。検索欄つき。詳細は
  [feature-cancellation-guide.md](feature-cancellation-guide.md)

**配信**: TestFlight にアップロード（Delivery UUID `17b2392d-a9ce-402a-bf8d-cb90ad82cead`）
**状態**: 審査未提出
**メモ**: build 8〜11 は **TestFlight のみで App Store には出していない**。App Store の 1.3.0 公開版は
**build 7**。これら（解約タブ 等）は v2.0.0 (build 12) に集約されている

## 1.3.0 (build 7) — 2026-08-14 · App Store（公開済み・旧版）

- 通知を「OS＋アイテム個別」の単一ソースに再設計（`06edbc1`）
- 設定画面のフッター表記も v1.3.0 に更新（`986eef7`）

**配信**: **App Store で公開中（`READY_FOR_SALE`、公開日 2026-08-14）**。タグ `v1.3.0` = `986eef7`
**状態**: 公開済み（当時の公開版・最低iOS 13.0。その後 2.0.0 → 2.0.1 に置き換え。現行は 2.0.1）
**メモ**: App Store の 1.3.0 は **build 7**。以降の build 8〜11（解約タブ拡張・iOS15引き上げ・
画像メモリ削減 等）は **TestFlight 止まりで App Store 1.3.0 には含まれない** → それらは
v2.0.0 (build 12) に集約。（タグ `v1.3.0` の注釈にも同旨を記録）

## 1.2.0 (build 6) — App Store（公開済み・旧版）

- 支払い履歴を「支払い済み／支払い予定」の2セクション表示に（`0e07420`）
- フッター表記を v1.2.0 に更新（`03062a0`）

**配信**: App Store で公開（`READY_FOR_SALE`）。タグ `v1.2.0` = `03062a0`
**状態**: 公開済み（現行は 1.3.0 のため、これは過去の公開版）

## 1.1.0 (build 5) — App Store（公開済み・旧版）

- 決済の堅牢化、デバッグ導線の Release 除外、問い合わせ／シェアの修正を同梱（`ecba2f8`）

**配信**: App Store で公開（`READY_FOR_SALE`）。タグ `v1.1.0` = `ecba2f8`
**状態**: 公開済み（現行は 1.3.0 のため、これは過去の公開版）

## 1.0.0 (build 4) — 2026-08-09 · App Store（初回公開）

- iPhone 専用化（`TARGETED_DEVICE_FAMILY=1`）（`958c1b6`）。初回申請（2026-08-09）で公開された版。

**配信**: App Store で公開（`READY_FOR_SALE`）。タグ `v1.0.0` = `958c1b6`
**状態**: 公開済み（初回公開版。build 1〜3 はこれ以前のイテレーションで、公開されたのは build 4）

## build 3 — 配信不明（git から復元）

- `NSUserTrackingUsageDescription` を削除（v1 では ATT／トラッキングを行わないため）（`e59ad77`）

**配信**: 不明（git から復元）

## build 2 — 配信不明（git から復元）

- 起動画面をブランド仕様に（ブランド背景＋アプリアイコン）（`021f020`）

**配信**: 不明（git から復元）

## build 1 — 初期

- 初回。App Store には 2026-08-09 に申請済み（Waiting for Review）だが、
  どのビルド番号で申請したかは記録が残っていない

**配信**: 不明（git から復元）
