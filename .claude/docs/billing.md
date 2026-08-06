# 支払いサイクルと日付計算

実装: `lib/core/utils/billing.dart`（`Billing` / `Recurrence`）。全画面がこれを使う。

## サイクルの正規化
`Subscription.recurrence`:
- monthly → `Recurrence(1, month)`
- yearly → `Recurrence(12, month)`
- weekly → `Recurrence(1, week)`
- custom → `Recurrence(intervalCount, intervalUnit)`

## 進め方（暦ベース）
初回支払日（anchor）から次の周期へ:
| 単位 | 進め方 | 例（5/31開始） |
|---|---|---|
| 月（monthly / custom ヶ月 / yearly=12ヶ月） | 同じ日で月だけ +N、**その月に無い日は末日に丸め** | 5/31→6/30→7/31→8/31→9/30 |
| 週 | N×7日 | 5/31→6/7→… |
| 日 | N日 | 5/31→6/3（3日ごと） |

## 主要関数
- `nextPaymentDate(anchor, r, {from})` — from（既定=今日）以降で最初の支払日
- `currentPeriodStart` — 直近の支払日（進捗バーの起点）
- `daysUntil(target)` — 暦日数
- `periodProgress(anchor, r)` — 現在周期の経過割合 0..1（支払直後=0、支払日=1）。ホームのゲージに使用
- `paymentsInRange(anchor, r, start, end)` — 範囲内の全支払日（カレンダー/履歴/分析）

## 長スパン対策（重要）
古い anchor（ピッカーは2000年まで可）＋短い周期（日/週）だと、1周期ずつ進める素朴実装ではガード（5000回）に達して誤った日付/件数になる。
→ **`_skipTo` で日/週はまとめて一気に進めてから**ループ。月は暦月なので件数が小さくループで安全。テスト: `test/billing_longspan_test.dart`。

## 月額換算 / 年額換算
`Recurrence.monthlyFactor`:
- day: `(365.25/12)/count`
- week: `(52/12)/count`
- month: `1/count`
`yearlyFactor = monthlyFactor*12`。分析/コスパ/履歴の換算に使用。
