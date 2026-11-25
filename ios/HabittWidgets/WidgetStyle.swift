import SwiftUI
import WidgetKit

// Colours, fonts and modifiers of the home screen widgets. Values come from
// the design canvas "Habitt Home Widgets" (Flame, Ring "beads", NextList) and
// match android/.../widgets/WidgetUi.kt. See docs/home_widgets.md.

extension Color {
  init(hex: UInt32, alpha: Double = 1) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255,
      opacity: alpha
    )
  }

  static func white(_ alpha: Double) -> Color { Color(hex: 0xFFFFFF, alpha: alpha) }
}

// MARK: - Fonts

/// Satoshi, bundled with the extension (UIAppFonts). Scales with Dynamic Type
/// within the range each widget allows.
enum Satoshi {
  enum Weight: String {
    case regular = "Satoshi-Regular"
    case medium = "Satoshi-Medium"
    case bold = "Satoshi-Bold"
  }

  static func font(_ size: CGFloat, _ weight: Weight = .regular) -> Font {
    .custom(weight.rawValue, size: size)
  }
}

// MARK: - Palette

/// Every colour a widget uses, for light, dark and the tinted / clear home
/// screen (iOS 18+ accented rendering, where only alpha survives and accent
/// marked parts take the tint).
struct Palette {
  let dark: Bool
  let tinted: Bool
  let accent: Color

  init(snapshot: WidgetSnapshot, scheme: ColorScheme, tinted: Bool) {
    dark = scheme == .dark
    self.tinted = tinted
    accent = tinted ? .white : Color(hex: dark ? snapshot.accentDark : snapshot.accentLight)
    accentHex = dark ? snapshot.accentDark : snapshot.accentLight
  }

  private let accentHex: UInt32

  private func pick(_ light: Color, _ dark: Color, tinted: Color) -> Color {
    self.tinted ? tinted : (self.dark ? dark : light)
  }

  var text: Color { pick(Color(hex: 0x0C0C0C), .white, tinted: .white) }

  // Ember cards (Streak, Up next's tile)
  var emberSub: Color { pick(Color(hex: 0x0C0C0C, alpha: 0.66), .white(0.68), tinted: .white(0.62)) }
  var badgeBg: Color { tinted ? .white(0.2) : .white(0.92) }
  var badgeInk: Color { tinted ? .white : Color(hex: 0xF47200) }

  // Plain cards (Streak week, Today ring)
  var plainBg: Color { pick(.white, Color(hex: 0x181818), tinted: Color(hex: 0x33353B)) }
  var plainBorder: Color { pick(Color(hex: 0xEDECEC), Color(hex: 0x2F3030), tinted: .white(0.08)) }

  // Streak week
  var weekSub: Color { emberSub }
  var weekTrack: Color { pick(Color(hex: 0xE4E4E6), Color(hex: 0x343536), tinted: .white(0.18)) }
  /// Week progress arcs are always Habitt green, whatever the theme.
  var habittGreen: Color { pick(Color(hex: 0x02D382), Color(hex: 0x11F29B), tinted: .white) }

  // Today ring
  var ringSub: Color { pick(Color(hex: 0xA4A7AE), .white(0.55), tinted: .white(0.55)) }
  var ringTrack: Color { pick(Color(hex: 0xF1F1F1), Color(hex: 0x2A2B2C), tinted: .white(0.16)) }
  /// The check on an accent circle.
  var checkInk: Color { pick(.white, Color(hex: 0x0C0C0C), tinted: Color(hex: 0x33353B)) }

  // Up next
  var upBg: Color { pick(Color(hex: 0xF4F4F4), Color(hex: 0x121212), tinted: Color(hex: 0x33353B)) }
  var upSub: Color { pick(Color(hex: 0x7A7C81), .white(0.6), tinted: .white(0.6)) }
  var card: Color { pick(.white, Color(hex: 0x1C1C1C), tinted: .white(0.06)) }
  var cardBorder: Color { pick(Color(hex: 0xEDECEC), Color(hex: 0x2F3030), tinted: .white(0.10)) }
  var disc: Color { pick(Color(hex: 0xF4F4F4), Color(hex: 0x2A2A2A), tinted: .white(0.12)) }
  var doneDisc: Color { pick(.white, Color(hex: 0x0C0C0C), tinted: .white(0.18)) }
  var offRing: Color { pick(Color(hex: 0xEDECEC), Color(hex: 0x565963), tinted: .white(0.35)) }
  var offCheck: Color { pick(Color(hex: 0xDCDCDC), Color(hex: 0x565963), tinted: .white(0.35)) }
  var doneRow: Color { tinted ? .white(0.12) : Color(hex: accentHex, alpha: dark ? 0.12 : 0.10) }
  var doneRowBorder: Color { tinted ? .white(0.18) : Color(hex: accentHex, alpha: 0.2) }
  var pieRing: Color { tinted ? .white(0.25) : Color(hex: accentHex, alpha: 0.2) }
}

/// The streak's mood colours: background gradient, glow and the soft glow of
/// Streak week. Dormant looks healthy, as on the home page streak card.
struct Ember {
  let top: Color
  let bottom: Color
  let glow: Color
  let soft: Color

  init(_ health: StreakInfo.Health, dark: Bool) {
    switch (health, dark) {
    case (.fading, false):
      self.init(0xFFFEEE, 0xFFF2CF, 0xFFB331, 0.36, 0.26)
    case (.fading, true):
      self.init(0x4C2E0E, 0x75471F, 0xD1761C, 0.8, 0.32)
    case (.critical, false):
      self.init(0xE5F0FB, 0xDFE9FF, 0x96C5FF, 0.9, 0.45)
    case (.critical, true):
      self.init(0x0F4E8D, 0x243966, 0x86B9F9, 0.9, 0.30)
    case (_, false):
      self.init(0xFFF6DA, 0xFFDFB1, 0xFF9831, 0.9, 0.30)
    case (_, true):
      self.init(0xFFE07A, 0xF47200, 0xF47200, 0.9, 0.34)
    }
  }

  private init(_ a: UInt32, _ b: UInt32, _ glow: UInt32, _ glowAlpha: Double, _ softAlpha: Double) {
    top = Color(hex: a)
    bottom = Color(hex: b)
    self.glow = Color(hex: glow, alpha: glowAlpha)
    soft = Color(hex: glow, alpha: softAlpha)
  }

  /// CSS `linear-gradient(225deg, a, b)`: from the top right corner to the bottom left.
  var gradient: LinearGradient {
    LinearGradient(colors: [top, bottom], startPoint: .topTrailing, endPoint: .bottomLeading)
  }
}

// MARK: - Modifiers

extension View {
  /// The widget's background: `containerBackground` on iOS 17+ (removed by
  /// the system on a tinted / clear home screen), a plain background before.
  @ViewBuilder
  func widgetBackground<B: View>(@ViewBuilder _ background: () -> B) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(for: .widget) { background() }
    } else {
      self.background(background())
    }
  }

  /// Takes the tint on a tinted home screen (iOS 16+).
  @ViewBuilder
  func accentable(_ on: Bool = true) -> some View {
    if #available(iOSApplicationExtension 16.0, *) {
      widgetAccentable(on)
    } else {
      self
    }
  }
}

extension Image {
  /// Artwork on a tinted home screen: desaturated rather than a flat tint (iOS 18+).
  @ViewBuilder
  func desaturatedWhenTinted() -> some View {
    if #available(iOSApplicationExtension 18.0, *) {
      widgetAccentedRenderingMode(.desaturated)
    } else {
      self
    }
  }
}

/// Hands the content whether the home screen is tinted or clear (iOS 16+
/// `widgetRenderingMode` is accented); false before iOS 16.
struct TintReader<Content: View>: View {
  let content: (Bool) -> Content

  init(@ViewBuilder content: @escaping (Bool) -> Content) {
    self.content = content
  }

  var body: some View {
    if #available(iOSApplicationExtension 16.0, *) {
      Modern(content: content)
    } else {
      content(false)
    }
  }

  @available(iOSApplicationExtension 16.0, *)
  private struct Modern: View {
    @Environment(\.widgetRenderingMode) private var mode
    let content: (Bool) -> Content

    var body: some View { content(mode == .accented) }
  }
}
