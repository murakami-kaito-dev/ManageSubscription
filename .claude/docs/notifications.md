# 通知

支払日リマインダー。完全オンデバイス（サーバー不要）。

## 仕様
- 各サブスクに `NotifyRule(daysBefore, hour, minute)`。発火時刻 = 次回支払日 − daysBefore 日の HH:MM
- 本文: 「〇〇 の支払い / M月D日（N日後）に ¥金額 の支払いがあります」（当日は「本日 …」）
- 有効/無効は設定「支払い日前に通知でお知らせ」。起動時に全件再スケジュール

## OS ローカル通知（`services/notifications/notification_service.dart`）
- `flutter_local_notifications` ＋ `flutter_timezone`（端末TZを `tz.local` に設定。未設定だと発火時刻がずれる）
- Android: high importance チャンネル、音＋バイブ明示、exact alarm（不可時 inexact フォールバック）
- iOS: **フォアグラウンドは音のみ（バナー抑制）**。バックグラウンド/終了時は通常表示
- **通知アイコン**: アイテムに画像設定時、その画像を使用（Android=large icon、iOS=attachment）。iOS は attachment がファイルの所有権を奪うため**一時コピーを渡す**（元画像は保持）

## アプリ内リマインダー（`features/notifications/foreground_reminder_host.dart`）
- OS はフォアグラウンド通知を抑制しがちなので、**アプリ起動中は自前の画面上部バナーを必ず表示**
- `MaterialApp.builder` で全画面の上に被せる。発火時刻をタイマー監視（データ変更/復帰で再計算）、発火時にバナー＋ハプティクス。6秒で自動 or タップで消える
- 発火時刻算出は `computeUpcomingReminders`（テスト: `test/foreground_reminder_test.dart`）

## まとめ
| 状態 | 見た目 | 音 |
|---|---|---|
| アプリ起動中 | アプリ内バナー（確実） | OS通知の音 |
| バックグラウンド/終了 | OS通知（画像アイコン付き） | OS通知の音 |
