# 通知

支払日リマインダー。完全オンデバイス（サーバー不要）。

## 仕様
- 各サブスクに `NotifyRule(daysBefore, hour, minute)`。発火時刻 = 次回支払日 − daysBefore 日の HH:MM
- 本文: 「〇〇 の支払い / M月D日（N日後）に ¥金額 の支払いがあります」（当日は「本日 …」）
- **通知の真実の源は「各アイテムの `NotifyRule` だけ」**。アプリ全体の通知ON/OFFトグルは**廃止**（冗長かつ"設定したのに鳴らない"落とし穴の元だったため）。ルールがあれば鳴る／なければ鳴らない。起動時に全件再スケジュール
- **OS許可は"文脈で"要求**：ユーザーが最初の `NotifyRule` を追加した瞬間に許可を求める（起動時には求めない）
- **OS許可オフ時のフォールバック**：有効なルールがあるのにOS通知が許可されていない場合、ホーム上部に警告バナー（`features/notifications/notification_permission_banner.dart`）を表示。タップで許可要求→拒否済みなら `openSystemSettings()`（`app-settings:`）で設定へ誘導。復帰時に再判定。これで「鳴らないのに設定できてしまう」サイレント失敗を塞ぐ
- 「全部一時停止したい」ニーズは **iOSのアプリ別通知トグル**（OS側）が担う（アプリ内に重複トグルは持たない）

## OS ローカル通知（`services/notifications/notification_service.dart`）
- `flutter_local_notifications` ＋ `flutter_timezone`（端末TZを `tz.local` に設定。未設定だと発火時刻がずれる）
- Android: high importance チャンネル、音＋バイブ明示、exact alarm（不可時 inexact フォールバック）
- iOS: **フォアグラウンドは音のみ（バナー抑制）**。バックグラウンド/終了時は通常表示
- **通知アイコン**: アイテムに画像設定時、その画像を使用（Android=large icon、iOS=attachment）。iOS は attachment がファイルの所有権を奪うため**一時コピーを渡す**（元画像は保持）

## アプリアイコンのバッジ（未確認の通知件数・iOS）
- **仕様**: 通知が届くたびにアプリアイコン右上の数字（バッジ）が増え、**アプリを開くと消える**
  ＝「前回アプリを開いてから届いたリマインダーの件数」。通知（ルール）が無ければ当然出ない
- **仕組み**: ローカル通知は配信時にバッジを「+1」できないため、スケジュール時に
  `computeUpcomingReminders`（`data/models/reminder_fire.dart`、アプリ内バナーと共用の純関数）で
  全予約を発火時刻順に並べ、**累積の連番（1,2,3…）を各通知の `badgeNumber` に焼き込む**
- **リセット**: `rescheduleAll` の冒頭で必ずバッジを0化＋連番を振り直す。`rescheduleAll` は
  起動時（`main.dart`）・**フォアグラウンド復帰時**（`ForegroundReminderHost` が追加で呼ぶ）・
  データ変更時（`SubscriptionsNotifier`）に走るので、「開いたら消える」が常に成立する
- **ネイティブ**: バッジ0化はプラグインに API が無いため、手作りチャンネル `submana/badge`
  （`AppDelegate.swift`、`submana/widget` と同方式）で `setBadgeCount(0)`（iOS16未満は
  `applicationIconBadgeNumber = 0`）。Android は対象外（ランチャー任せ・iOS のみ配布中）
- **注意**: iOS の attachment は通知ごとにファイル所有権を奪うため、一時コピーは
  **サブスク単位でなく通知単位**で作る（複数ルール時に2件目の画像が壊れるのを防ぐ）

## アプリ内リマインダー（`features/notifications/foreground_reminder_host.dart`）
- OS はフォアグラウンド通知を抑制しがちなので、**アプリ起動中は自前の画面上部バナーを必ず表示**
- `MaterialApp.builder` で全画面の上に被せる。発火時刻をタイマー監視（データ変更/復帰で再計算）、発火時にバナー＋ハプティクス。6秒で自動 or タップで消える
- 発火時刻算出は `computeUpcomingReminders`（テスト: `test/foreground_reminder_test.dart`）

## まとめ
| 状態 | 見た目 | 音 |
|---|---|---|
| アプリ起動中 | アプリ内バナー（確実） | OS通知の音 |
| バックグラウンド/終了 | OS通知（画像アイコン付き） | OS通知の音 |
| OS通知オフ＋ルールあり | ホーム上部に許可誘導バナー | （OS通知は出ない） |
