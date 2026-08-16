import SwiftUI
import WidgetKit

// MARK: - Shared payload (written by the app via WidgetBridge / AppDelegate)

/// JSON stored in the App Group defaults under "widget_payload".
/// Produced by `lib/services/widget/widget_payload.dart` — labels are
/// preformatted in the app's main currency; only date math happens here so
/// "あと◯日" stays correct on days the app isn't opened.
struct WidgetPayload: Decodable {
  struct Item: Decodable {
    let name: String
    let amount: String
    let epoch: Double  // next payment date, ms since epoch
  }

  let monthLabel: String
  let totalLabel: String
  let count: Int
  let items: [Item]
  // アプリで選択中のテーマ色（"#RRGGBB"）。旧形式ペイロードには無いので optional。
  let accent: String?
  let accentDeep: String?

  static let appGroupId = "group.com.submana.app"

  static func load() -> WidgetPayload? {
    guard
      let raw = UserDefaults(suiteName: appGroupId)?
        .string(forKey: "widget_payload"),
      let data = raw.data(using: .utf8)
    else { return nil }
    return try? JSONDecoder().decode(WidgetPayload.self, from: data)
  }

  static let sample = WidgetPayload(
    monthLabel: "8月",
    totalLabel: "¥12,480",
    count: 6,
    items: [
      Item(name: "Netflix", amount: "¥1,590",
           epoch: Date().addingTimeInterval(2 * 86400).timeIntervalSince1970 * 1000),
      Item(name: "Spotify", amount: "¥980",
           epoch: Date().addingTimeInterval(6 * 86400).timeIntervalSince1970 * 1000),
      Item(name: "iCloud+", amount: "¥450",
           epoch: Date().addingTimeInterval(11 * 86400).timeIntervalSince1970 * 1000),
    ],
    accent: nil,
    accentDeep: nil)
}

// MARK: - Timeline

struct SubmanaEntry: TimelineEntry {
  let date: Date
  let payload: WidgetPayload?
}

struct SubmanaProvider: TimelineProvider {
  func placeholder(in context: Context) -> SubmanaEntry {
    SubmanaEntry(date: Date(), payload: .sample)
  }

  func getSnapshot(in context: Context, completion: @escaping (SubmanaEntry) -> Void) {
    completion(SubmanaEntry(date: Date(), payload: WidgetPayload.load() ?? .sample))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<SubmanaEntry>) -> Void) {
    // One entry now + one at each of the next 7 midnights, so the day-count
    // labels advance daily even if the app isn't opened. The app itself pushes
    // fresh data (and a timeline reload) on every change.
    let payload = WidgetPayload.load()
    let cal = Calendar.current
    var entries = [SubmanaEntry(date: Date(), payload: payload)]
    let today = cal.startOfDay(for: Date())
    for day in 1...7 {
      if let d = cal.date(byAdding: .day, value: day, to: today) {
        entries.append(SubmanaEntry(date: d, payload: payload))
      }
    }
    completion(Timeline(entries: entries, policy: .atEnd))
  }
}

// MARK: - Palette (matches the app's claymorphism theme — light, fixed)

enum Palette {
  static let canvas = Color(red: 0.917, green: 0.902, blue: 0.867)      // #EAE6DD
  static let surface = Color(red: 0.984, green: 0.976, blue: 0.957)     // #FBF9F4
  static let textPrimary = Color(red: 0.231, green: 0.227, blue: 0.212) // #3B3A36
  static let textSecondary = Color(red: 0.522, green: 0.498, blue: 0.451) // #857F73
  static let accent = Color(red: 0.431, green: 0.565, blue: 0.502)      // #6E9080
  static let accentDeep = Color(red: 0.329, green: 0.424, blue: 0.376)  // #546C60
  static let coral = Color(red: 0.882, green: 0.514, blue: 0.420)       // #E1836B
}

extension Color {
  /// "#RRGGBB" → Color。不正な値は nil（呼び出し側でフォールバック）。
  init?(hexString: String?) {
    guard var s = hexString else { return nil }
    s = s.replacingOccurrences(of: "#", with: "")
    guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
    self.init(
      red: Double((v >> 16) & 0xFF) / 255,
      green: Double((v >> 8) & 0xFF) / 255,
      blue: Double(v & 0xFF) / 255)
  }
}

extension WidgetPayload {
  /// アプリで選択中のテーマ色（未指定・旧形式なら既定のセージ）。
  var accentColor: Color { Color(hexString: accent) ?? Palette.accent }
  var accentDeepColor: Color { Color(hexString: accentDeep) ?? Palette.accentDeep }
}

// MARK: - Date helpers

func daysLabel(from entryDate: Date, toEpochMs epoch: Double) -> (text: String, urgent: Bool) {
  let cal = Calendar.current
  let target = cal.startOfDay(for: Date(timeIntervalSince1970: epoch / 1000))
  let base = cal.startOfDay(for: entryDate)
  let days = cal.dateComponents([.day], from: base, to: target).day ?? 0
  if days <= 0 { return ("本日", true) }
  if days == 1 { return ("明日", true) }
  return ("あと\(days)日", days <= 3)
}

func dateLabel(epochMs epoch: Double) -> String {
  let f = DateFormatter()
  f.locale = Locale(identifier: "ja_JP")
  f.dateFormat = "M月d日"
  return f.string(from: Date(timeIntervalSince1970: epoch / 1000))
}

// MARK: - Views

struct TotalBlock: View {
  let payload: WidgetPayload

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text("\(payload.monthLabel)の合計")
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .foregroundColor(Palette.textSecondary)
      Text(payload.totalLabel)
        .font(.system(size: 24, weight: .heavy, design: .rounded))
        .foregroundColor(Palette.textPrimary)
        .minimumScaleFactor(0.5)
        .lineLimit(1)
      Text("\(payload.count)件が利用中")
        .font(.system(size: 10, weight: .medium, design: .rounded))
        .foregroundColor(Palette.textSecondary)
    }
  }
}

struct ItemRow: View {
  let item: WidgetPayload.Item
  let entryDate: Date
  var compact = false
  var accentColor: Color = Palette.accent
  var accentDeepColor: Color = Palette.accentDeep

  var body: some View {
    let due = daysLabel(from: entryDate, toEpochMs: item.epoch)
    HStack(spacing: 6) {
      Circle()
        .fill(due.urgent ? Palette.coral : accentColor)
        .frame(width: 6, height: 6)
      Text(item.name)
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .foregroundColor(Palette.textPrimary)
        .lineLimit(1)
      Spacer(minLength: 4)
      if !compact {
        Text(item.amount)
          .font(.system(size: 11, weight: .semibold, design: .rounded))
          .foregroundColor(Palette.textSecondary)
          .lineLimit(1)
      }
      Text(due.text)
        .font(.system(size: 11, weight: .bold, design: .rounded))
        .foregroundColor(due.urgent ? Palette.coral : accentDeepColor)
        .lineLimit(1)
    }
  }
}

/// medium 用の全幅行: 「何を・いつ・いくら」を省略なしで1行に収める。
/// 名前 …… M月d日・あと◯日 …… 金額（右寄せ）
struct WideItemRow: View {
  let item: WidgetPayload.Item
  let entryDate: Date
  var accentColor: Color = Palette.accent
  var accentDeepColor: Color = Palette.accentDeep

  var body: some View {
    let due = daysLabel(from: entryDate, toEpochMs: item.epoch)
    HStack(spacing: 6) {
      Circle()
        .fill(due.urgent ? Palette.coral : accentColor)
        .frame(width: 6, height: 6)
      Text(item.name)
        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
        .foregroundColor(Palette.textPrimary)
        .lineLimit(1)
      Spacer(minLength: 8)
      Text(dateLabel(epochMs: item.epoch))
        .font(.system(size: 11, weight: .medium, design: .rounded))
        .foregroundColor(Palette.textSecondary)
        .lineLimit(1)
        .layoutPriority(1)
      Text(due.text)
        .font(.system(size: 11, weight: .bold, design: .rounded))
        .foregroundColor(due.urgent ? Palette.coral : accentDeepColor)
        .lineLimit(1)
        .layoutPriority(1)
      Text(item.amount)
        .font(.system(size: 12.5, weight: .bold, design: .rounded))
        .foregroundColor(Palette.textPrimary)
        .lineLimit(1)
        .layoutPriority(1)
        .frame(minWidth: 52, alignment: .trailing)
    }
  }
}

struct EmptyHint: View {
  var body: some View {
    VStack(spacing: 4) {
      Text("サブスク家計簿")
        .font(.system(size: 13, weight: .bold, design: .rounded))
        .foregroundColor(Palette.textPrimary)
      Text("アプリを開くと\nここに表示されます")
        .font(.system(size: 11, design: .rounded))
        .foregroundColor(Palette.textSecondary)
        .multilineTextAlignment(.center)
    }
  }
}

struct SubmanaWidgetView: View {
  @Environment(\.widgetFamily) var family
  let entry: SubmanaEntry

  var body: some View {
    Group {
      if let p = entry.payload {
        switch family {
        case .systemMedium: medium(p)
        default: small(p)
        }
      } else {
        EmptyHint()
      }
    }
    .widgetBackground(Palette.canvas)
  }

  private func small(_ p: WidgetPayload) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      TotalBlock(payload: p)
      Spacer(minLength: 0)
      if let first = p.items.first {
        VStack(alignment: .leading, spacing: 2) {
          Text("次の支払い")
            .font(.system(size: 9, weight: .semibold, design: .rounded))
            .foregroundColor(Palette.textSecondary)
          ItemRow(item: first, entryDate: entry.date, compact: true,
                  accentColor: p.accentColor, accentDeepColor: p.accentDeepColor)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  // 上半分=今月の合計 / 下半分=次の支払い3件（全幅）。
  // 左右分割だと名前・金額・日付が全て中途半端に見切れて
  // 「何を・いつ・いくら」が読めないため、縦分割にしている。
  private func medium(_ p: WidgetPayload) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 1) {
          Text("\(p.monthLabel)の合計")
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(Palette.textSecondary)
          Text(p.totalLabel)
            .font(.system(size: 23, weight: .heavy, design: .rounded))
            .foregroundColor(Palette.textPrimary)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
        }
        Spacer(minLength: 8)
        Text("\(p.count)件が利用中")
          .font(.system(size: 10, weight: .medium, design: .rounded))
          .foregroundColor(Palette.textSecondary)
      }
      Rectangle()
        .fill(Palette.textSecondary.opacity(0.18))
        .frame(height: 1)
      if p.items.isEmpty {
        Text("次の支払い予定はありません")
          .font(.system(size: 11, design: .rounded))
          .foregroundColor(Palette.textSecondary)
      } else {
        VStack(spacing: 4) {
          ForEach(0..<min(p.items.count, 4), id: \.self) { i in
            WideItemRow(item: p.items[i], entryDate: entry.date,
                        accentColor: p.accentColor,
                        accentDeepColor: p.accentDeepColor)
          }
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

// iOS 17 requires containerBackground; older versions use a plain background.
extension View {
  @ViewBuilder
  func widgetBackground(_ color: Color) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(for: .widget) { color }
    } else {
      padding(12).background(color)
    }
  }
}

// MARK: - Widget definition

struct SubmanaWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "SubmanaWidget", provider: SubmanaProvider()) {
      SubmanaWidgetView(entry: $0)
    }
    .configurationDisplayName("今月のサブスク")
    .description("今月の合計と、支払い日が近いサブスクを表示します。")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

@main
struct SubmanaWidgetBundle: WidgetBundle {
  var body: some Widget {
    SubmanaWidget()
  }
}
