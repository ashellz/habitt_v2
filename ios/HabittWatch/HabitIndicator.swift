import SwiftUI

// The habit's check, identical to the phone's habit card (NewHabitProgress):
// no progress → grey check (check-off-dark.svg), done → filled accent with a
// near-black check (check-on-dark.svg), partial → a filled pie from 12
// o'clock with a faint accent ring (_CircularProgressPie). Geometry is the
// SVGs' 24×24 viewBox, scaled.

enum IndicatorState: Equatable {
  case off, partial, done
}

struct HabitIndicator: View {
  var progress: Double
  var isDone: Bool
  var accent: Color
  var size: CGFloat = 26

  static let offGrey = Color(hex: 0x565963)
  static let checkOnDone = Color(hex: 0x0C0C0C)

  private var state: IndicatorState {
    if isDone { return .done }
    return progress > 0 ? .partial : .off
  }

  var body: some View {
    let unit = size / 24
    ZStack {
      switch state {
      case .off:
        ZStack {
          Circle().strokeBorder(Self.offGrey, lineWidth: 1.26 * unit)
          CheckGlyph().stroke(Self.offGrey, style: CheckGlyph.style(unit))
        }
        .transition(.scale)
      case .done:
        ZStack {
          Circle().fill(accent)
          CheckGlyph().stroke(Self.checkOnDone, style: CheckGlyph.style(unit))
        }
        .transition(.scale)
      case .partial:
        ZStack {
          PieShape(progress: min(max(progress, 0), 1)).fill(accent)
          Circle().inset(by: unit).stroke(accent.opacity(0.2), lineWidth: 2 * unit)
        }
        .transition(.scale)
      }
    }
    .frame(width: size, height: size)
    // the pie tweens like the phone's (1250 ms), the pie/check swap scales (300 ms)
    .animation(.easeInOut(duration: 1.25), value: progress)
    .animation(.easeInOut(duration: 0.3), value: state)
  }
}

/// The check mark of the app's check SVGs: a round-capped polyline through
/// (6.9, 12) → (10.3, 15.4) → (17.08, 8.62), 2.93 wide, in a 24×24 box.
struct CheckGlyph: Shape {
  static func style(_ unit: CGFloat) -> StrokeStyle {
    StrokeStyle(lineWidth: 2.93 * unit, lineCap: .round, lineJoin: .round)
  }

  func path(in rect: CGRect) -> Path {
    let u = rect.width / 24
    var p = Path()
    p.move(to: CGPoint(x: rect.minX + 6.9 * u, y: rect.minY + 12 * u))
    p.addLine(to: CGPoint(x: rect.minX + 10.3 * u, y: rect.minY + 15.4 * u))
    p.addLine(to: CGPoint(x: rect.minX + 17.08 * u, y: rect.minY + 8.62 * u))
    return p
  }
}

/// A filled wedge from 12 o'clock, clockwise; animatable.
struct PieShape: Shape {
  var progress: Double

  var animatableData: Double {
    get { progress }
    set { progress = newValue }
  }

  func path(in rect: CGRect) -> Path {
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let radius = min(rect.width, rect.height) / 2
    var p = Path()
    guard progress > 0 else { return p }
    p.move(to: center)
    p.addArc(
      center: center, radius: radius, startAngle: .degrees(-90),
      endAngle: .degrees(-90 + 360 * min(progress, 1)), clockwise: false)
    p.closeSubpath()
    return p
  }
}

/// The big progress ring of the log and read-only screens; animated.
struct ProgressRing: View {
  var progress: Double
  var accent: Color
  var lineWidth: CGFloat = 8
  var duration: Double = 0.35

  var body: some View {
    ZStack {
      Circle().stroke(Color(hex: 0x2C2C2E), lineWidth: lineWidth)
      Circle()
        .trim(from: 0, to: min(max(progress, 0), 1))
        .stroke(accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        .rotationEffect(.degrees(-90))
    }
    .animation(.easeInOut(duration: duration), value: progress)
  }
}
