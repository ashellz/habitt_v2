import SwiftUI
import WidgetKit

// Streak week: a plain card with a soft mood glow, a small flame, the count
// and "days", the line, then the last 7 days as embers (flame for a perfect
// day, Habitt green arc for partial days and today, grey dot for a miss).
// Opens home.

struct StreakWeekWidget: Widget {
  let kind = "HabittStreakWeekWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: HabittProvider(kind: kind)) { entry in
      StreakWeekWidgetView(entry: entry)
    }
    .configurationDisplayName(Text("widgetStreakWeekName"))
    .description(Text("widgetStreakWeekDescription"))
    .supportedFamilies([.systemSmall])
    .contentMarginsDisabled()
  }
}

struct StreakWeekWidgetView: View {
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
      ZStack(alignment: .topTrailing) {
        if !palette.tinted {
          Circle()
            .fill(
              RadialGradient(
                colors: [ember.soft, ember.soft.opacity(0)], center: .center,
                startRadius: 0, endRadius: 84 * u)
            )
            .frame(width: 170 * u, height: 170 * u)
            .offset(x: 70 * u, y: -70 * u)
        }
        VStack(alignment: .leading, spacing: 0) {
          header(streak, palette, u)
          Text(streak.line)
            .font(Satoshi.font(12 * u))
            .foregroundColor(palette.weekSub)
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .padding(.top, 6 * u)
          Spacer(minLength: 4 * u)
          HStack(spacing: 0) {
            ForEach(Array(streak.week.enumerated()), id: \.offset) { i, day in
              let isToday = i == streak.week.count - 1
              VStack(spacing: 5 * u) {
                Text(day.label)
                  .font(Satoshi.font(10 * u, isToday ? .bold : .medium))
                  .foregroundColor(isToday ? palette.text : palette.weekSub)
                  .lineLimit(1)
                  .minimumScaleFactor(0.6)
                marker(day, streak.health, palette, u)
              }
              .frame(maxWidth: .infinity)
            }
          }
        }
        .foregroundColor(palette.text)
        .padding(.horizontal, 14 * u)
        .padding(.top, 14 * u)
        .padding(.bottom, 12 * u)
        .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
      }
      .frame(width: geo.size.width, height: geo.size.height)
      .overlay(CardBorder(color: palette.plainBorder))
    }
    .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    .widgetBackground { palette.plainBg }
  }

  private func header(_ streak: StreakInfo, _ palette: Palette, _ u: CGFloat) -> some View {
    HStack(alignment: .center, spacing: 6 * u) {
      flame(streak.health, size: 22 * u, header: true)
      HStack(alignment: .firstTextBaseline, spacing: 5 * u) {
        Text("\(streak.count)")
          .font(Satoshi.font(28 * u, .bold))
          .tracking(-0.5 * u)
        Text(entry.snapshot.strings.dayLabel(streak.count))
          .font(Satoshi.font(13 * u, .medium))
          .foregroundColor(palette.weekSub)
      }
      .lineLimit(1)
      .minimumScaleFactor(0.6)
    }
  }

  /// The small flame; muted by the streak's health as in the design.
  @ViewBuilder
  private func flame(_ health: StreakInfo.Health, size: CGFloat, header: Bool) -> some View {
    let image = Image("art_streak").resizable().desaturatedWhenTinted().frame(width: size, height: size)
    switch health {
    case .fading where header:
      image.saturation(0.55).opacity(0.8)
    case .critical where header:
      image.hueRotation(.degrees(185)).saturation(0.75).brightness(0.05)
    case .critical:
      image.saturation(0.5).opacity(0.55)
    default:
      image
    }
  }

  @ViewBuilder
  private func marker(_ day: WeekDay, _ health: StreakInfo.Health, _ palette: Palette, _ u: CGFloat) -> some View {
    ZStack {
      switch day.status {
      case .perfect:
        flame(health, size: 17 * u, header: false)
      case .partial, .today:
        Circle()
          .stroke(palette.weekTrack, lineWidth: 2.4 * u)
          .frame(width: 14 * u, height: 14 * u)
        if day.progress > 0 {
          RingArc(from: 0, to: 360 * day.progress)
            .stroke(palette.habittGreen, style: StrokeStyle(lineWidth: 2.4 * u, lineCap: .round))
            .frame(width: 14 * u, height: 14 * u)
            .accentable()
        }
      case .miss:
        Circle().fill(palette.weekTrack).frame(width: 6 * u, height: 6 * u)
      case .none:
        EmptyView()
      }
    }
    .frame(width: 18 * u, height: 18 * u)
  }
}
