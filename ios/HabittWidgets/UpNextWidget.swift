import SwiftUI
import WidgetKit

// Up next: the current part of the day (label and icon), up to 3 habits as
// rows with their indicator, and a 104 pt streak tile. Day complete when the
// section is null, the empty box when the app has no habits. Rows open Log
// progress for their habit, the rest of the widget the home page.

struct UpNextWidget: Widget {
  let kind = "HabittUpNextWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: HabittProvider(kind: kind)) { entry in
      UpNextWidgetView(entry: entry)
    }
    .configurationDisplayName(Text("widgetUpNextName"))
    .description(Text("widgetUpNextDescription"))
    .supportedFamilies([.systemMedium])
    .contentMarginsDisabled()
  }
}

struct UpNextWidgetView: View {
  let entry: HabittEntry
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    TintReader { tinted in
      content(Palette(snapshot: entry.snapshot, scheme: scheme, tinted: tinted))
    }
    .widgetURL(WidgetLinks.home)
  }

  private func content(_ palette: Palette) -> some View {
    let block = entry.block
    let section = block.upNext(at: entry.date, calendar: .current)
    return GeometryReader { geo in
      // the design is 364×170; rows stretch with the width
      let u = min(geo.size.width / 364, geo.size.height / 170)
      HStack(spacing: 10 * u) {
        Group {
          if let section {
            sectionView(section, block, palette, u)
          } else if !entry.snapshot.hasHabits {
            NoHabitsView(text: entry.snapshot.strings.noHabits, u: u, textSize: 12.5, palette: palette)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          } else if block.habits.isEmpty {
            endState(nil, entry.snapshot.strings.nothingToday, palette, u)
          } else {
            endState(entry.snapshot.strings.dayComplete, entry.snapshot.strings.dayCompleteBody, palette, u)
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        StreakTile(streak: block.streak, strings: entry.snapshot.strings, u: u, palette: palette)
          .frame(width: 104 * u)
      }
      .padding(10 * u)
      .frame(width: geo.size.width, height: geo.size.height)
      .overlay(CardBorder(color: palette.plainBorder))
    }
    .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    .widgetBackground { palette.upBg }
  }

  // MARK: Section

  private func sectionView(_ section: UpNextSection, _ block: DayBlock, _ palette: Palette, _ u: CGFloat) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 5 * u) {
        Image(icon(section.icon))
          .resizable()
          .renderingMode(.template)
          .frame(width: 13 * u, height: 13 * u)
        Text(section.label)
          .font(Satoshi.font(12 * u, .medium))
          .lineLimit(1)
      }
      .foregroundColor(palette.upSub)
      .frame(height: 16 * u)
      .padding(.horizontal, 6 * u)
      VStack(spacing: 3 * u) {
        ForEach(block.rows(section), id: \.id) { habit in
          Link(destination: WidgetLinks.log(habit.id)) {
            row(habit, palette, u)
          }
        }
      }
      .padding(.top, 5 * u)
    }
  }

  private func icon(_ key: String) -> String {
    switch key {
    case "evening": return "icon_moon"
    case "anyTime": return "icon_anytime"
    default: return "icon_sun"
    }
  }

  private func row(_ habit: WidgetHabit, _ palette: Palette, _ u: CGFloat) -> some View {
    let done = habit.isDone
    let shape = RoundedRectangle(cornerRadius: 20 * u, style: .continuous)
    return HStack(spacing: 10 * u) {
      Text(habit.emoji)
        .font(.system(size: 15 * u))
        .frame(width: 30 * u, height: 30 * u)
        .background(Circle().fill(done ? palette.doneDisc : palette.disc))
      VStack(alignment: .leading, spacing: 0) {
        Text(habit.name)
          .font(Satoshi.font(13.5 * u, .medium))
          .foregroundColor(palette.text)
          .lineLimit(1)
          .truncationMode(.tail)
        // checkbox habits have no progress text: the name stays centred
        if !habit.progressText.isEmpty {
          Text(habit.progressText)
            .font(Satoshi.font(11 * u))
            .foregroundColor(palette.upSub)
            .lineLimit(1)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      indicator(habit, palette, 22 * u)
    }
    .padding(.leading, 4 * u)
    .padding(.trailing, 9 * u)
    .frame(height: 40 * u)
    .background(shape.fill(done ? palette.doneRow : palette.card))
    .overlay(shape.strokeBorder(done ? palette.doneRowBorder : palette.cardBorder, lineWidth: 1))
  }

  /// The app's habit indicator: grey check-circle, accent pie, or filled accent check.
  @ViewBuilder
  private func indicator(_ habit: WidgetHabit, _ palette: Palette, _ size: CGFloat) -> some View {
    let k = size / 24
    switch habit.state {
    case .done:
      AccentCheck(size: size, palette: palette)
    case .partial:
      ZStack {
        Pie(progress: habit.progress).fill(palette.accent).accentable()
        Circle().inset(by: 1 * k).stroke(palette.pieRing, lineWidth: 2 * k).accentable()
      }
      .frame(width: size, height: size)
    case .todo:
      ZStack {
        Circle().inset(by: 0.63 * k).stroke(palette.offRing, lineWidth: 1.26 * k)
        Image("icon_check").resizable().renderingMode(.template).foregroundColor(palette.offCheck)
      }
      .frame(width: size, height: size)
    }
  }

  // MARK: End states

  private func endState(_ title: String?, _ body: String, _ palette: Palette, _ u: CGFloat) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      if let title {
        AccentCheck(size: 40 * u, palette: palette)
        Text(title)
          .font(Satoshi.font(19 * u, .bold))
          .foregroundColor(palette.text)
          .lineLimit(1)
          .minimumScaleFactor(0.6)
          .padding(.top, 12 * u)
      }
      Text(body)
        .font(Satoshi.font(12.5 * u))
        .foregroundColor(palette.upSub)
        .lineLimit(3)
        .minimumScaleFactor(0.7)
        .padding(.top, title == nil ? 0 : 6 * u)
    }
    .padding(.leading, 10 * u)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }
}

/// The streak as an ember tile on the right of Up next.
private struct StreakTile: View {
  let streak: StreakInfo
  let strings: WidgetSnapshot.Strings
  let u: CGFloat
  let palette: Palette

  var body: some View {
    let ember = Ember(streak.health, dark: palette.dark)
    let shape = RoundedRectangle(cornerRadius: 18 * u, style: .continuous)
    ZStack(alignment: .topLeading) {
      if !palette.tinted { ember.gradient }
      EmberArt(health: streak.health, size: .tile, u: u, palette: palette)
      VStack(alignment: .leading, spacing: 0) {
        Text("\(streak.count)")
          .font(Satoshi.font(32 * u, .bold))
          .tracking(-0.5 * u)
          .lineLimit(1)
          .minimumScaleFactor(0.5)
          .padding(.vertical, -4 * u)
        Text(strings.streakLabel(streak.count))
          .font(Satoshi.font(12 * u, .medium))
          .lineLimit(2)
          .minimumScaleFactor(0.7)
          .padding(.top, 6 * u)
      }
      .foregroundColor(palette.dark || palette.tinted ? .white : Color(hex: 0x0C0C0C))
      .padding(.leading, 12 * u)
      .padding(.top, 11 * u)
      .padding(.trailing, streak.perfectToday ? 30 * u : 8 * u)
      if streak.perfectToday {
        PerfectBadge(size: 22 * u, palette: palette)
          .padding(10 * u)
          .frame(maxWidth: .infinity, alignment: .topTrailing)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(palette.tinted ? Color.white(0.08) : Color.clear)
    .clipShape(shape)
  }
}
