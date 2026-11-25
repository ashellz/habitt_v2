import SwiftUI
import WidgetKit

// Streak: the ember card. Big count, "day(s) streak", the line; gradient,
// glow and flame by the streak's health; a badge once today is perfect.
// Dormant shows 0 and the invite line with the healthy look. Opens home.

struct StreakWidget: Widget {
  let kind = "HabittStreakWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: HabittProvider(kind: kind)) { entry in
      StreakWidgetView(entry: entry)
    }
    .configurationDisplayName(Text("widgetStreakName"))
    .description(Text("widgetStreakDescription"))
    .supportedFamilies([.systemSmall])
    .contentMarginsDisabled()
  }
}

struct StreakWidgetView: View {
  let entry: HabittEntry
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    TintReader { tinted in
      content(Palette(snapshot: entry.snapshot, scheme: scheme, tinted: tinted))
    }
    .widgetURL(WidgetLinks.home)
  }

  private func content(_ palette: Palette) -> some View {
    let streak = entry.block.streak
    let ember = Ember(streak.health, dark: palette.dark)
    return GeometryReader { geo in
      let u = min(geo.size.width, geo.size.height) / 170
      ZStack(alignment: .topLeading) {
        EmberArt(health: streak.health, size: .card, u: u, palette: palette)
        VStack(alignment: .leading, spacing: 0) {
          Text("\(streak.count)")
            .font(Satoshi.font(48 * u, .bold))
            .tracking(-1 * u)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.vertical, -6 * u)
          Text(entry.snapshot.strings.streakLabel(streak.count))
            .font(Satoshi.font(15 * u, .medium))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.top, 6 * u)
          Text(streak.line)
            .font(Satoshi.font(12 * u))
            .foregroundColor(palette.emberSub)
            .lineLimit(3)
            .minimumScaleFactor(0.7)
            .padding(.top, 3 * u)
        }
        .foregroundColor(palette.text)
        .frame(width: 110 * u, alignment: .leading)
        .padding(.leading, 16 * u)
        .padding(.top, 14 * u)
        if streak.perfectToday {
          PerfectBadge(size: 26 * u, palette: palette)
            .padding(12 * u)
            .frame(maxWidth: .infinity, alignment: .topTrailing)
        }
      }
      .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
    }
    .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    .widgetBackground { ember.gradient }
  }
}
