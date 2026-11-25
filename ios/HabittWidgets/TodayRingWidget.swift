import SwiftUI
import WidgetKit

// Today ring ("Beads"): one segment per counted habit (4° gaps, butt caps,
// stroke 26 on the 170 card) filled to its progress in the accent, its emoji
// on the segment, done/total or an accent check in the centre. Above 8 habits
// one plain ring filled to the day's progress, no emojis. Opens Log progress
// of the first habit not done, home when the day is perfect or empty.

struct TodayRingWidget: Widget {
  let kind = "HabittTodayRingWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: HabittProvider(kind: kind)) { entry in
      TodayRingWidgetView(entry: entry)
    }
    .configurationDisplayName(Text("widgetTodayRingName"))
    .description(Text("widgetTodayRingDescription"))
    .supportedFamilies([.systemSmall])
    .contentMarginsDisabled()
  }
}

struct TodayRingWidgetView: View {
  let entry: HabittEntry
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    TintReader { tinted in
      content(Palette(snapshot: entry.snapshot, scheme: scheme, tinted: tinted))
    }
    .widgetURL(WidgetLinks.ring(entry.block))
  }

  private func content(_ palette: Palette) -> some View {
    let block = entry.block
    return GeometryReader { geo in
      let side = min(geo.size.width, geo.size.height)
      let u = side / 170
      ZStack {
        if !entry.snapshot.hasHabits {
          NoHabitsView(text: entry.snapshot.strings.noHabits, u: u, textSize: 12, palette: palette)
            .padding(14 * u)
        } else if block.total == 0 {
          Text(entry.snapshot.strings.nothingToday)
            .font(Satoshi.font(13 * u, .medium))
            .foregroundColor(palette.ringSub)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .minimumScaleFactor(0.7)
            .padding(14 * u)
        } else {
          BeadsRing(block: block, u: u, palette: palette)
            .frame(width: side, height: side)
        }
      }
      .frame(width: geo.size.width, height: geo.size.height)
      .overlay(CardBorder(color: palette.plainBorder))
    }
    .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    .widgetBackground { palette.plainBg }
  }
}

private struct BeadsRing: View {
  let block: DayBlock
  let u: CGFloat
  let palette: Palette

  private let radius: CGFloat = 60
  private let stroke: CGFloat = 26

  var body: some View {
    let habits = block.ringHabits
    let continuous = habits.count > DayBlock.maxRingSegments
    let step = 360 / Double(max(habits.count, 1))
    let ringSize = 2 * radius * u
    let style = StrokeStyle(lineWidth: stroke * u, lineCap: .butt)
    ZStack {
      if continuous {
        Circle().stroke(palette.ringTrack, style: style).frame(width: ringSize, height: ringSize)
        if block.dayProgress > 0 {
          RingArc(from: 0, to: 360 * block.dayProgress)
            .stroke(palette.accent, style: style)
            .frame(width: ringSize, height: ringSize)
            .accentable()
        }
      } else {
        ForEach(Array(habits.enumerated()), id: \.offset) { i, habit in
          let (start, sweep) = span(i, count: habits.count, step: step)
          let progress = habit.isDone ? 1 : habit.progress
          RingArc(from: start, to: start + sweep)
            .stroke(palette.ringTrack, style: style)
            .frame(width: ringSize, height: ringSize)
          if progress > 0 {
            RingArc(from: start, to: start + max(sweep * progress, 0.4))
              .stroke(palette.accent, style: style)
              .frame(width: ringSize, height: ringSize)
              .accentable()
          }
          let mid = (-90 + Double(i) * step + step / 2) * .pi / 180
          Text(habit.emoji)
            .font(.system(size: 17 * u))
            .fixedSize()
            .offset(x: radius * u * CGFloat(cos(mid)), y: radius * u * CGFloat(sin(mid)))
        }
      }
      center
    }
  }

  /// Segment `i` of `count`: 2° trimmed off each end (4° gaps); one habit is a full ring.
  private func span(_ i: Int, count: Int, step: Double) -> (Double, Double) {
    let start = Double(i) * step
    return count <= 1 ? (start, 360) : (start + 2, step - 4)
  }

  @ViewBuilder
  private var center: some View {
    if block.perfect {
      ZStack {
        Circle().fill(palette.accent).accentable()
        CheckStroke()
          .stroke(palette.checkInk, style: StrokeStyle(lineWidth: 2.2 * 24 * u / 16, lineCap: .round, lineJoin: .round))
          .frame(width: 24 * u, height: 24 * u)
      }
      .frame(width: 40 * u, height: 40 * u)
    } else {
      HStack(alignment: .firstTextBaseline, spacing: 0) {
        Text("\(block.done)")
          .font(Satoshi.font(30 * u, .bold))
          .tracking(-0.5 * u)
          .foregroundColor(palette.text)
        Text("/\(block.total)")
          .font(Satoshi.font(16 * u, .medium))
          .foregroundColor(palette.ringSub)
      }
      .lineLimit(1)
      .minimumScaleFactor(0.5)
      .frame(maxWidth: 68 * u)
    }
  }
}
