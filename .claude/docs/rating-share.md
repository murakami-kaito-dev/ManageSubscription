# アプリ評価・レビュー誘導・共有

## ストアリンク（`core/store_links.dart`）
- `appStoreId`（数値のApple ID）: **未公開のため空（TODO）**。埋めると iOS 用URLが有効化
- `androidPackage`: `applicationId`（現 `com.example.manage_subscription`）
- `iosUrl`（ID未設定時 null）/ `androidUrl` / `currentPlatformUrl` / `shareLinks()`

## 評価メニュー（`services/rating/rating_service.dart`）
- 設定「アプリ」セクションの **「このアプリを応援する」** → `RatingService.rate()`
- `rate()`: ネイティブ In-App Review（`in_app_review`）を優先、不可なら store listing。best-effort（例外を握る）

## レビュー誘導（初回追加時）
- **タイミング**: ユーザーが**初めて自分でサブスクを新規追加した直後の1回のみ**（シードは対象外）。`rating_first_add_prompt_shown` フラグで一度きり
- トリガ: `SubscriptionFormScreen._save()` の新規作成成功後、**`RatingService.rate()` を直接呼ぶ**
- **自前のポップアップは廃止**（旧 `features/rating/rating_prompt.dart` は削除）。星や「コメントを書く」等の中間UIは挟まず、**OS標準のレビュー画面**（iOS: SKStoreReviewController / Android: Play In-App Review）をそのまま出す
- ⚠️ OS標準画面の「送信」ボタンは、**App Store から入れた本番ビルドでのみ**機能する。Debug/Simulator/TestFlight では Apple 側の仕様で送信が無効（グレー）＝これは不具合ではない。表示回数も Apple により年数回に制限され、出ないこともある

## 共有（設定「シェア」）
`Share.share('…\n${StoreLinks.shareUrl()}')`。

**なぜ受信者OSで出し分けできないか**: プレーンなテキスト/URL共有は送信時に文字列が固定され、受信者が
どのOSで開くかは分からない（判別できるのは“送信者”のOSのみ）。相手のOSに合わせて正しいストアを開くには、
**1本のスマートリンク（OS判定リダイレクトページ）**を共有し、受信者が開いた瞬間に User-Agent で振り分けるしかない。

- `StoreLinks.shareUrl()`:
  - `smartLink` が設定済み → **その1本のURL**を共有（受信者の端末がストアを選ぶ＝要望どおり）。
  - 未設定 → `shareLinks()`（既知のストアURLを両方併記）にフォールバック。App Store 行は `appStoreId` 設定後に出る。
- **スマートリンクの用意（`smartLink` を有効化する手順）**:
  1. リダイレクトHTML（`download.html`。User-Agent で iOS→App Store / Android→Google Play、その他→Play）を
     `submana-legal`（GitHub Pages）に配置。HTMLひな型はセッションのスクラッチパッドに生成済み。
  2. `APPLE_APP_ID`（公開後の数値ID）と `ANDROID_PACKAGE`（実 applicationId。現状 `com.example.…` は要変更）を差し替え。
  3. `StoreLinks.smartLink` に公開URL（例: `https://murakami-kaito-dev.github.io/submana-legal/download.html`）を設定。
  - 併せて `appStoreId` も設定すると、フォールバック時の併記にも App Store が載る。
