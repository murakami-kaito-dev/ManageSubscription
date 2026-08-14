# リリースログ（バージョン・ビルド番号の履歴）

バージョン／ビルド番号が動いたら**その場で**ここに追記する。運用ルールは
グローバルスキル `release-log` を参照。新しいものが上。

- **ビルドしただけ**と**配信した**は必ず区別する
- 秘密情報（APIキー・Issuer ID・証明書）は書かない

---

## 2.0.0 (build 12) — 2026-08-14 · App Store Connect（審査提出は保留）

build 8〜11 の全機能を束ねたメジャーバージョン。機能追加は無く、以下の審査用対応のみ。

- **`ios/Runner/PrivacyInfo.xcprivacy` を新規作成**（従来は**存在しなかった**）。
  トラッキング無し／データ収集無し／Required Reason API は UserDefaults(CA92.1) と
  FileTimestamp(C617.1) を申告。`project.pbxproj` の Resources ビルドフェーズにも登録した
  （登録しないとバンドルに入らない）。`Payload/Runner.app/PrivacyInfo.xcprivacy` として
  同梱されていることを確認済み
- バージョン表記を 1.3.0 → 2.0.0（設定画面フッターも同時更新）

**配信**: App Store Connect にアップロード（Delivery UUID `0967ca3f-da9a-4916-8986-f8898cf06099`）
**状態**: **審査未提出**。理由は下記

**⚠️ 提出前に必ず解消すること**:
1. **サブスク購入の実機確認が未実施**（`CLAUDE.md` の禁忌事項1。「1つでも欠けたらリリースしない」）
2. 広告SDKを外したため、App Store Connect の **IDFA/広告識別子の申告と App Privacy の回答を
   見直す必要がある**（「使用しない」に変わるはず）
3. 前回申請（2026-08-09）の審査状況が未確認。審査中なら先に取り下げが必要

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

## 1.3.0 (build 7) — 2026-08-13 · 配信不明（git から復元）

- 通知を「OS＋アイテム個別」の単一ソースに再設計（`06edbc1`）
- 設定画面のフッター表記も v1.3.0 に更新（`986eef7`）

**配信**: 不明（git から復元。TestFlight/App Store に上がったかは未確認）
**状態**: 不明

## 1.2.0 (build 6) — 配信不明（git から復元）

- 支払い履歴を「支払い済み／支払い予定」の2セクション表示に（`0e07420`）
- フッター表記を v1.2.0 に更新（`03062a0`）

**配信**: 不明（git から復元）
**状態**: 不明

## 1.1.0 (build 5) — 配信不明（git から復元）

- 決済の堅牢化、デバッグ導線の Release 除外、問い合わせ／シェアの修正を同梱（`ecba2f8`）

**配信**: 不明（git から復元）
**状態**: 不明

## build 4 — 配信不明（git から復元）

- iPhone 専用化（`TARGETED_DEVICE_FAMILY=1`）（`958c1b6`）

**配信**: 不明（git から復元）

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
