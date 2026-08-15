# 機能: 「解約方法」タブ（サブスク解約ガイド）

> ステータス: **実装済み**（2026-08-14）。画面仕様は [screens.md](screens.md) にも記載。
> 実装: `lib/features/cancellation/cancel_guide_data.dart`（静的リンク集）＋
> `cancel_guide_screen.dart`（画面）、テストは `test/cancel_guide_test.dart`。

## 何をする機能か
契約中のサブスクを「解約したい」と思ったときに、**その解約入口の公式ページへ 1タップで飛べる**
リンク集。アプリ同梱の静的データで、通信もデータ収集もしない。

## 設計方針（★1を避ける）
- **手順は書き写さない。公式の解約ページに"リンク遷移"するだけ**（書き写した手順はすぐ古くなり、誤案内になる）。
- 各サービス = 「公式解約ページを開くボタン（URL）」＋「どこから解約するか（ブラウザ/アプリ/OS設定）」＋「解約前の注意（日割りなし・解約金・課金経路の違いなど）」。
- **誇張しない（絶対）**: 「このアプリから解約できます」とは言わない。UI 上も
  「公式の解約ページを開きます」「このアプリからは解約できません」と明記する。
- **80/20**: 200社網羅を目指さない。ユーザーが実際に持つ上位20前後に絞る。
- **URLは腐る**前提。リリース前に実際に開いて確認する（古い/切れたリンクは★1の元）。
- ガイドライン: 情報提供・公式ページへのリンクは**セーフ**（課金と無関係）。
- 自アプリの解約手順も隠さず載せる。

## 自動検出について（判断済み）
ユーザーの実アカウントの**自動検出は不可・不採用**（銀行/メール連携が必要でプライバシー的にもやらない）。
今回は**タブ方式**。ただし各エントリに検索用の `aliases`（カナ・英語表記）を持たせてあるので、
将来「登録済みサブスクのサービス名と文字列一致 → その詳細画面から解約ページを開く」導線を
足すのは低コスト（＝検出ではなく文字列一致）。

## 画面
- ボトムナビ5つ目のタブ「解約方法」（`CancelGuideScreen`）。ホーム/分析/カレンダー/支払い履歴 の右。
- 上から: 説明カード（「公式の解約ページを開きます」）→ 検索欄（サービス名・カナで絞り込み）→
  カテゴリー別のリスト。
- 行をタップ → ボトムシート（「どこから解約するか」/「解約する前に」/「公式の解約ページを開く」）。
  ボタンで `url_launcher` により**外部ブラウザ**へ。開けなければスナックバー。
- カテゴリー順: 登録先（App Store / Google Play）→ 動画 → 音楽 → 仕事・AI・クラウド → ゲーム → 読書・雑誌・生活 → 学び・教育 → フィットネス・健康 → このアプリ。

## 収録サービス（`kCancelGuideEntries`）
**最重要**: 日本のサブスクは **App Store / Google Play 経由課金が多数**。その場合の解約先は
サービスのサイトではなく **iOS設定 / Playストアのサブスク画面**。ここで迷う人が多いので**最上段**。

計 **46件**（2026-08-15 時点。会員数の定量根拠に基づき 7件追加）。カテゴリー順・定義順にそのまま画面に並ぶ。

**登録先**
| サービス | 解約入口 URL |
|---|---|
| App Store で登録したサブスク | `https://apps.apple.com/account/subscriptions` |
| Google Play で登録したサブスク | `https://play.google.com/store/account/subscriptions` |

**動画**
| サービス | 解約入口 URL |
|---|---|
| Netflix | `https://www.netflix.com/cancelplan` |
| Amazon プライム / Prime Video | `https://www.amazon.co.jp/gp/primecentral` |
| Disney+ | `https://www.disneyplus.com/ja-jp/commerce/subscription` |
| U-NEXT | `https://account.unext.jp/` |
| DAZN | `https://www.dazn.com/ja-JP/account/subscription` |
| Hulu（日本） | `https://www.hulu.jp/account` |
| ABEMA プレミアム | `https://abema.tv/account` |
| d アニメストア | `https://animestore.docomo.ne.jp/animestore/mp_viw_pc` |
| Lemino（旧 dTV） | `https://lemino.docomo.ne.jp/` |
| FOD | `https://fod.fujitv.co.jp/` |
| TELASA | `https://www.telasa.jp/` |
| WOWOW | `https://www.wowow.co.jp/support/cancel/`（Webだけで完結しない場合あり） |
| DMM TV / DMM プレミアム | `https://www.dmm.com/my/-/subscription/`（App Store 経由は注意） |
| ニコニコプレミアム | `https://premium.nicovideo.jp/` |

**音楽**
| サービス | 解約入口 URL |
|---|---|
| Spotify | `https://www.spotify.com/jp/account/overview/` |
| Apple Music | ＝App Store のサブスク画面 |
| Amazon Music Unlimited | `https://www.amazon.co.jp/music/settings` |
| YouTube Premium / Music | `https://www.youtube.com/paid_memberships` |
| LINE MUSIC | `https://music.line.me/` |

**仕事・AI・クラウド**
| サービス | 解約入口 URL |
|---|---|
| ChatGPT Plus | `https://chatgpt.com/`（設定 → Subscription） |
| Claude Pro / Max | `https://claude.ai/settings/billing` |
| Adobe Creative Cloud | `https://account.adobe.com/plans`（**解約金の注意**を表示） |
| Microsoft 365 | `https://account.microsoft.com/services` |
| Google One | `https://one.google.com/settings` |
| iCloud+ | ＝App Store のサブスク画面 |
| Dropbox | `https://www.dropbox.com/account/plan` |
| Canva Pro | `https://www.canva.com/settings/billing-and-plans/` |
| Notion | `https://www.notion.so/`（ワークスペース単位の契約） |
| GitHub Copilot | `https://github.com/settings/billing/summary` |

**ゲーム**（「解約」ではなく**自動更新オフ**の方式が多い＝迷いやすいので収録）
| サービス | 解約入口 URL |
|---|---|
| Nintendo Switch Online | `https://ec.nintendo.com/my/membership` |
| PlayStation Plus | `https://id.sonyentertainmentnetwork.com/id/management/` |
| Xbox Game Pass | `https://account.microsoft.com/services` |

**読書・雑誌・生活**
| サービス | 解約入口 URL |
|---|---|
| Kindle Unlimited | `https://www.amazon.co.jp/kindle-dbs/hz/subscribe/ku/manage` |
| d マガジン | `https://dmagazine.docomo.ne.jp/` |
| 楽天マガジン | `https://magazine.rakuten.co.jp/` |
| Audible | `https://www.audible.co.jp/account/overview` |
| 日経電子版 | `https://www.nikkei.com/my/` |
| Uber One | `https://www.ubereats.com/jp` |
| LYP プレミアム（旧 Yahoo! プレミアム） | `https://premium.yahoo.co.jp/`（登録経路で解約先が変わる） |
| X Premium（旧 Twitter Blue） | `https://x.com/i/premium`（App Store 経由は注意） |

**学び・教育**
| サービス | 解約入口 URL |
|---|---|
| スタディサプリ | `https://studysapuri.jp/info/guide/cancellation/`（「利用停止」と「退会」は別） |
| Duolingo（Super Duolingo） | `https://www.duolingo.com/help/cancel-my-super-duolingo-subscription`（App Store 経由は注意） |

**フィットネス・健康**
| サービス | 解約入口 URL |
|---|---|
| chocoZAP（チョコザップ） | `https://faq.chocozap.jp/chocozap_faq/qa/cancel`（最短解約は入会翌月末） |

**このアプリ**
| サービス | 解約入口 URL |
|---|---|
| サブスク家計簿 プレミアム | ＝App Store のサブスク画面（下記） |

URL は 2026-08-14 に到達確認済み（ログイン画面へのリダイレクトは正常）。
Claude / Uber One は bot 遮断で HTTP 403 が返るが、実ブラウザでは正常に開く。
サービス側の都合で変わるので、**リリース前に一度は実機で開いて確認する**。

2026-08-15 追加の 7件（DMM TV / ニコニコプレミアム / LYP プレミアム / X Premium /
スタディサプリ / Duolingo / chocoZAP）は、各サービスの**公式解約導線を Web で確認して採用**した
（会員数の定量根拠に基づく選定）。**URL の実機到達確認は次のリリース前にまとめて行う**（未実施）。

## このアプリ（サブスク家計簿 Pro）の解約方法（必ず載せる）
- プレミアム（月額/年額）は **App Store のサブスクリプションから解約**:
  iOS「設定」→ Apple ID →サブスクリプション→サブスク家計簿→キャンセル。
- **買い切り（永久）は解約不要**（一度きりの購入）— シート内の注意書きに明記。

## メンテナンス
- 追加するときは `kCancelGuideEntries` に 1 エントリ足すだけ（カテゴリー順・定義順に並ぶ）。
  「本当に契約者が多い順」で足す。網羅は目的にしない。
- `test/cancel_guide_test.dart` が id 重複・URL 形式・空文言・空セクション・検索を守る
  （リンク先が生きているかはテストでは分からない。手で開いて確認）。
- 文言でも UI でも「このアプリで解約できる」と読める表現にしないこと。

## ASO（開発者側の宿題・実装とは別）
「解約」系キーワード（解約 / 解約方法 / サブスク解約 / 退会 / 無料期間 / 自動更新）を
サブタイトル・キーワード・スクショに入れるかは配信時に判断する。実装側の作業ではない。
