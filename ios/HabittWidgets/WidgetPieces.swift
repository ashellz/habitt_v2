import SwiftUI
import WidgetKit

// Pieces shared by the widgets. Sizes are in design points (the 170 small /
// 364×170 medium canvas) times `u`, the widget's scale.

// MARK: - Ember artwork

/// The glow and the flame (plus ice when critical) in a streak card's bottom
/// right corner. Offsets are the design's CSS `right` / `bottom`.
struct EmberArt: View {
  enum Size { case card, tile }

  let health: StreakInfo.Health
  let size: Size
  let u: CGFloat
  let palette: Palette

  var body: some View {
    let ember = Ember(health, dark: palette.dark)
    let (glow, glowOffset) = size == .card ? (CGFloat(180), CGFloat(58)) : (130, 46)
    // an overlay on an empty view: the glow and art are bigger than the
    // card and must not take part in layout (they would widen Up next's tile)
    Color.clear.overlay(alignment: .bottomTrailing) {
      ZStack(alignment: .bottomTrailing) {
      if !palette.tinted {
        Circle()
          .fill(
            RadialGradient(
              colors: [ember.glow, ember.glow.opacity(0)], center: .center,
              startRadius: 0, endRadius: glow / 2 * 1.414 * 0.68 * u)
          )
          .frame(width: glow * u, height: glow * u)
          .offset(x: glowOffset * u, y: glowOffset * u)
      }
      ForEach(pieces, id: \.name) { p in
        Image(p.name)
          .resizable()
          .desaturatedWhenTinted()
          .frame(width: p.w * u, height: p.h * u)
          .saturation(p.saturation)
          .opacity(p.opacity)
          .offset(x: -p.right * u, y: -p.bottom * u)
      }
      }
    }
  }

  private struct Piece {
    let name: String
    let w: CGFloat, h: CGFloat, right: CGFloat, bottom: CGFloat
    var saturation: Double = 1
    var opacity: Double = 1
  }

  private var pieces: [Piece] {
    switch (health, size) {
    case (.fading, .card):
      return [Piece(name: "art_streak_fade", w: 118, h: 138, right: -30, bottom: -56)]
    case (.fading, .tile):
      return [Piece(name: "art_streak", w: 64, h: 64, right: -6, bottom: -8, saturation: 0.6, opacity: 0.85)]
    case (.critical, .card):
      return [
        Piece(name: "art_streak", w: 77, h: 77, right: -14, bottom: -14),
        Piece(name: "art_ice_left", w: 57, h: 77, right: 27, bottom: -30),
        Piece(name: "art_ice_over", w: 111, h: 171, right: -39, bottom: -96),
      ]
    case (.critical, .tile):
      return [
        Piece(name: "art_streak", w: 60, h: 60, right: -8, bottom: -8),
        Piece(name: "art_ice_left", w: 45, h: 60, right: 24, bottom: -21),
        Piece(name: "art_ice_over", w: 86, h: 134, right: -27, bottom: -72),
      ]
    case (_, .card):
      return [Piece(name: "art_streak", w: 94, h: 94, right: -8, bottom: -14)]
    case (_, .tile):
      return [Piece(name: "art_streak", w: 64, h: 64, right: -6, bottom: -8)]
    }
  }
}

// MARK: - Checks and badges

/// The design's stroked check mark in a 16 box.
struct CheckStroke: Shape {
  func path(in rect: CGRect) -> Path {
    let k = rect.width / 16
    var p = Path()
    p.move(to: CGPoint(x: 3.5 * k, y: 8.4 * k))
    p.addLine(to: CGPoint(x: 6.6 * k, y: 11.4 * k))
    p.addLine(to: CGPoint(x: 12.5 * k, y: 4.8 * k))
    return p
  }
}

/// White circle with an orange check: today is already perfect.
struct PerfectBadge: View {
  let size: CGFloat
  let palette: Palette

  var body: some View {
    ZStack {
      Circle().fill(palette.badgeBg)
      CheckStroke()
        .stroke(palette.badgeInk, style: StrokeStyle(lineWidth: size * 0.077, lineCap: .round, lineJoin: .round))
        .frame(width: size * 0.6, height: size * 0.6)
    }
    .frame(width: size, height: size)
    .accentable()
  }
}

/// Filled accent circle with the app's check (done habit, Day complete).
struct AccentCheck: View {
  let size: CGFloat
  let palette: Palette

  var body: some View {
    ZStack {
      Circle().fill(palette.accent).accentable()
      Image("icon_check").resizable().renderingMode(.template).foregroundColor(palette.checkInk)
    }
    .frame(width: size, height: size)
  }
}

/// A pie wedge from 12 o'clock, clockwise, filling the rect's circle.
struct Pie: Shape {
  var progress: Double

  func path(in rect: CGRect) -> Path {
    var p = Path()
    guard progress > 0 else { return p }
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let r = min(rect.width, rect.height) / 2
    if progress >= 1 {
      p.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
      return p
    }
    p.move(to: c)
    p.addArc(
      center: c, radius: r, startAngle: .degrees(-90), endAngle: .degrees(-90 + 360 * progress),
      clockwise: false)
    p.closeSubpath()
    return p
  }
}

/// An arc of a circle inscribed in the rect, in degrees clockwise from 12 o'clock.
struct RingArc: Shape {
  var from: Double
  var to: Double

  func path(in rect: CGRect) -> Path {
    var p = Path()
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let r = min(rect.width, rect.height) / 2
    if to - from >= 360 {
      p.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
      return p
    }
    p.addArc(
      center: c, radius: r, startAngle: .degrees(from - 90), endAngle: .degrees(to - 90), clockwise: false)
    return p
  }
}

// MARK: - States

/// No habits in the app at all: the app's empty box art over its text.
struct NoHabitsView: View {
  let text: String
  let u: CGFloat
  let textSize: CGFloat
  let palette: Palette

  var body: some View {
    VStack(spacing: 10 * u) {
      Image("art_empty_box").resizable().desaturatedWhenTinted().frame(width: 46 * u, height: 46 * u)
      Text(text)
        .font(Satoshi.font(textSize * u, .medium))
        .foregroundColor(palette.upSub)
        .multilineTextAlignment(.center)
        .lineLimit(3)
        .minimumScaleFactor(0.7)
    }
  }
}

/// A card's 1 pt border, following the widget's corner radius.
struct CardBorder: View {
  let color: Color

  var body: some View {
    ContainerRelativeShape().strokeBorder(color, lineWidth: 1)
  }
}
