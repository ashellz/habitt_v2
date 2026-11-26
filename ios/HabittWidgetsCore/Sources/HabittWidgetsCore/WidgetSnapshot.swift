import Foundation

// The widget snapshot the Flutter app writes (key `habitt_snapshot` in the App
// Group defaults, see docs/home_widgets.md). The widgets only draw it: every
// habit, streak and schedule decision was already made in Dart. Foundation
// only, so it is unit tested on the Mac (`swift test` in ios/HabittWidgetsCore)
// and compiled as is into the HabittWidgets extension.

public struct WidgetSnapshot: Equatable {
  public static let version = 1
  public static let appGroup = "group.com.shellz.habitt"
  public static let storageKey = "habitt_snapshot"
  public static let defaultAccentLight: UInt32 = 0x02D382
  public static let defaultAccentDark: UInt32 = 0x11F29B
  public static let defaultNoHabits = "You haven’t added any habits yet"

  public var dayKey: String
  /// When `today` ends; from then on the widgets show `tomorrow`.
  public var nextDayStartsAt: Date
  public var accentLight: UInt32
  public var accentDark: UInt32
  public var strings: Strings
  public var today: DayBlock
  public var tomorrow: DayBlock
  /// False when the app has no habits at all, not just none today.
  public var hasHabits: Bool
  /// Ids of Apple Watch actions the app has applied (docs/watch_app.md).
  public var watchAcks: [String] = []

  public struct Strings: Equatable {
    public var dayStreak: String
    public var daysStreak: String
    public var day: String
    public var days: String
    public var dayComplete: String
    public var dayCompleteBody: String
    public var nothingToday: String
    public var noHabits: String
    /// Every snapshot string by key, in the app's language (the Apple Watch
    /// reads its list labels and UI text from here). Empty in old snapshots.
    public var labels: [String: String] = [:]

    public init(
      dayStreak: String, daysStreak: String, day: String, days: String,
      dayComplete: String, dayCompleteBody: String, nothingToday: String, noHabits: String,
      labels: [String: String] = [:]
    ) {
      self.dayStreak = dayStreak
      self.daysStreak = daysStreak
      self.day = day
      self.days = days
      self.dayComplete = dayComplete
      self.dayCompleteBody = dayCompleteBody
      self.nothingToday = nothingToday
      self.noHabits = noHabits
      self.labels = labels
    }

    public func streakLabel(_ count: Int) -> String { count == 1 ? dayStreak : daysStreak }
    public func dayLabel(_ count: Int) -> String { count == 1 ? day : days }
  }

  /// The block the widgets show at `now`: `tomorrow` once the next day has started.
  public func block(at now: Date) -> DayBlock { now >= nextDayStartsAt ? tomorrow : today }

  // MARK: Decoding

  /// The snapshot's `v`, without decoding the rest; nil when unreadable. The
  /// watch uses it to tell "from a newer app" apart from "malformed".
  public static func peekVersion(_ json: String?) -> Int? {
    guard let json, let data = json.data(using: .utf8),
      let raw = try? JSONDecoder().decode(RawVersion.self, from: data)
    else { return nil }
    return raw.v
  }

  /// Parses `json`; nil for no snapshot, another version or anything malformed.
  /// Times in the snapshot are local (Dart's `toIso8601String()` of a local
  /// `DateTime`), read in `calendar`'s time zone.
  public static func decode(_ json: String?, calendar: Calendar = .current) -> WidgetSnapshot? {
    guard let json, !json.isEmpty, let data = json.data(using: .utf8) else { return nil }
    guard let raw = try? JSONDecoder().decode(RawSnapshot.self, from: data),
      raw.v == version,
      let dayKey = raw.dayKey,
      let nextDay = raw.nextDayStartsAt.flatMap({ parseLocalDateTime($0, calendar: calendar) }),
      let today = raw.today, let tomorrow = raw.tomorrow
    else { return nil }
    let s = raw.strings
    let dayStreak = s?.dayStreak ?? "day streak"
    let daysStreak = s?.daysStreak ?? "days streak"
    return WidgetSnapshot(
      dayKey: dayKey,
      nextDayStartsAt: nextDay,
      accentLight: parseColor(raw.theme?.light?.accent) ?? defaultAccentLight,
      accentDark: parseColor(raw.theme?.dark?.accent) ?? defaultAccentDark,
      strings: Strings(
        dayStreak: dayStreak,
        daysStreak: daysStreak,
        // older snapshots have no short form: fall back to the first word
        day: s?.day ?? firstWord(dayStreak),
        days: s?.days ?? firstWord(daysStreak),
        dayComplete: s?.dayComplete ?? "Day complete",
        dayCompleteBody: s?.dayCompleteBody ?? "",
        nothingToday: s?.nothingToday ?? "",
        noHabits: s?.noHabits ?? defaultNoHabits,
        labels: (try? JSONDecoder().decode(RawStringsMap.self, from: data))?.strings ?? [:]
      ),
      today: DayBlock(raw: today),
      tomorrow: DayBlock(raw: tomorrow),
      hasHabits: raw.hasHabits ?? true,
      watchAcks: raw.watchAcks ?? []
    )
  }

  /// What the widgets show before the app wrote its first snapshot (just
  /// installed, never opened): no habits and a streak of 0, in the device
  /// language. Never rolls over to a "tomorrow".
  public static func placeholder(
    strings: Strings, startStreak: String, weekLabels: [String], dayKey: String
  ) -> WidgetSnapshot {
    let week = weekLabels.enumerated().map { i, label in
      WeekDay(label: label, status: i == weekLabels.count - 1 ? .today : WeekDay.Status.none, progress: 0)
    }
    let block = DayBlock(
      habits: [], ring: [], done: 0, total: 0, perfect: false,
      streak: StreakInfo(count: 0, health: .dormant, perfectToday: false, line: startStreak, week: week),
      upNext: [:]
    )
    return WidgetSnapshot(
      dayKey: dayKey, nextDayStartsAt: .distantFuture,
      accentLight: defaultAccentLight, accentDark: defaultAccentDark,
      strings: strings, today: block, tomorrow: block, hasHabits: false
    )
  }

  /// Sample data for the widget gallery while the user has no habits of
  /// their own (the design canvas' "morning" state): a healthy 12 day
  /// streak and five premade habits at different stages. `names`: brush
  /// teeth, shower, drink water, read, mindfulness; `partLabels`: the
  /// localized Morning / Afternoon / Evening.
  public static func sample(
    strings: Strings, names: [String], partLabels: [PartOfDay: String], line: String, weekLabels: [String]
  ) -> WidgetSnapshot {
    func name(_ i: Int) -> String { i < names.count ? names[i] : "" }
    let habits = [
      WidgetHabit(id: 1, emoji: "🪥", name: name(0), category: 2, progress: 1, state: .done),
      WidgetHabit(id: 2, emoji: "🚿", name: name(1), category: 2, progress: 0.8, progressText: "8m / 10m", state: .partial),
      WidgetHabit(id: 3, emoji: "💧", name: name(2), category: 1, progress: 0.25, progressText: "2 / 8", state: .partial),
      WidgetHabit(id: 4, emoji: "📖", name: name(3), category: 4, progress: 0.6, progressText: "12 / 20", state: .partial),
      WidgetHabit(id: 5, emoji: "🧘", name: name(4), category: 4, progress: 0, progressText: "0m / 10m", state: .todo),
    ]
    let days: [(WeekDay.Status, Double)] = [
      (.perfect, 1), (.perfect, 1), (.perfect, 1), (.partial, 0.55), (.perfect, 1), (.perfect, 1), (.today, 0.6),
    ]
    let week = zip(weekLabels, days).map { WeekDay(label: $0, status: $1.0, progress: $1.1) }
    var upNext: [PartOfDay: UpNextSection] = [:]
    for part in PartOfDay.allCases {
      upNext[part] = UpNextSection(label: partLabels[part] ?? "", icon: part.rawValue, habitIds: [1, 2, 3])
    }
    let block = DayBlock(
      habits: habits, ring: habits.map(\.id), done: 1, total: habits.count, perfect: false,
      streak: StreakInfo(count: 12, health: .healthy, perfectToday: false, line: line, week: week),
      upNext: upNext
    )
    return WidgetSnapshot(
      dayKey: "", nextDayStartsAt: .distantFuture,
      accentLight: defaultAccentLight, accentDark: defaultAccentDark,
      strings: strings, today: block, tomorrow: block, hasHabits: true
    )
  }

  /// Dart's `DateTime.toIso8601String()` of a local time
  /// (`2026-11-25T00:00:00.000`, optionally with microseconds), or a bare date.
  public static func parseLocalDateTime(_ s: String, calendar: Calendar) -> Date? {
    let chars = Array(s)
    func int(_ from: Int, _ len: Int) -> Int? {
      guard chars.count >= from + len else { return nil }
      return Int(String(chars[from..<(from + len)]))
    }
    guard let y = int(0, 4), let mo = int(5, 2), let d = int(8, 2) else { return nil }
    var c = DateComponents(year: y, month: mo, day: d, hour: 0, minute: 0, second: 0)
    if chars.count >= 19 {
      guard let h = int(11, 2), let mi = int(14, 2), let se = int(17, 2) else { return nil }
      c.hour = h
      c.minute = mi
      c.second = se
    }
    return calendar.date(from: c)
  }

  /// `#RRGGBB` → 0xRRGGBB.
  public static func parseColor(_ hex: String?) -> UInt32? {
    guard var v = hex else { return nil }
    if v.hasPrefix("#") { v.removeFirst() }
    guard v.count == 6 else { return nil }
    return UInt32(v, radix: 16)
  }

  private static func firstWord(_ s: String) -> String {
    String(s.split(separator: " ", maxSplits: 1).first ?? Substring(s))
  }
}

// MARK: - Day block

public struct WidgetHabit: Equatable {
  public enum State: String { case done, partial, todo }

  /// Microsecond timestamps (16 digits): always 64-bit.
  public var id: Int64
  public var emoji: String
  public var name: String
  public var category: Int
  public var optional: Bool
  public var progress: Double
  public var progressText: String
  public var state: State
  /// The habit's own completed flag (`state` done also covers skipped).
  public var completed: Bool
  public var log: HabitLog

  public var isDone: Bool { state == .done }

  /// Health-linked and time-of-day habits only show their state on the watch.
  public var watchReadOnly: Bool { log.healthLinked || log.kind == .timeOfDay }

  public init(
    id: Int64, emoji: String, name: String, category: Int = 1, optional: Bool = false,
    progress: Double, progressText: String = "", state: State, completed: Bool? = nil,
    log: HabitLog = .none
  ) {
    self.id = id
    self.emoji = emoji
    self.name = name
    self.category = category
    self.optional = optional
    self.progress = progress
    self.progressText = progressText
    self.state = state
    self.completed = completed ?? (state == .done)
    self.log = log
  }
}

/// How a habit is logged, for the Apple Watch. Durations are in seconds.
public struct HabitLog: Equatable {
  public enum Kind: String { case amount, duration, timeOfDay }

  public var kind: Kind?
  public var target: Int
  public var value: Int
  /// Amount label for the target, already localized ("pages"); "" otherwise.
  public var unit: String
  public var step: Int
  public var healthLinked: Bool
  /// Amount or duration without Health sync: the watch can set its value.
  public var watchLoggable: Bool

  public static let none = HabitLog(
    kind: nil, target: 0, value: 0, unit: "", step: 1, healthLinked: false, watchLoggable: false)

  public init(
    kind: Kind?, target: Int, value: Int, unit: String = "", step: Int = 1,
    healthLinked: Bool = false, watchLoggable: Bool = false
  ) {
    self.kind = kind
    self.target = target
    self.value = value
    self.unit = unit
    self.step = step
    self.healthLinked = healthLinked
    self.watchLoggable = watchLoggable
  }
}

public struct WeekDay: Equatable {
  public enum Status: String { case perfect, partial, miss, none, today }
  public var label: String
  public var status: Status
  public var progress: Double
}

public struct StreakInfo: Equatable {
  public enum Health: String { case healthy, fading, critical, dormant }
  public var count: Int
  public var health: Health
  public var perfectToday: Bool
  public var line: String
  public var week: [WeekDay]
}

public struct UpNextSection: Equatable {
  /// "morning", "afternoon", "evening" or "anyTime".
  public var label: String
  public var icon: String
  public var habitIds: [Int64]
}

/// Parts of the day as the app's `categoryIdForMinutes`: Morning 04–12,
/// Afternoon 12–19, Evening 19–04.
public enum PartOfDay: String, CaseIterable {
  case morning, afternoon, evening

  public static func at(_ date: Date, calendar: Calendar) -> PartOfDay {
    switch calendar.component(.hour, from: date) {
    case 4..<12: return .morning
    case 12..<19: return .afternoon
    default: return .evening
    }
  }

  /// Hours at which the part of the day changes.
  public static let boundaryHours = [4, 12, 19]
}

public struct DayBlock: Equatable {
  /// Above this many counted habits the ring is one plain ring (no emojis).
  public static let maxRingSegments = 8

  public var habits: [WidgetHabit]
  public var ring: [Int64]
  public var done: Int
  public var total: Int
  public var perfect: Bool
  public var streak: StreakInfo
  public var upNext: [PartOfDay: UpNextSection]

  public func habit(_ id: Int64) -> WidgetHabit? { habits.first { $0.id == id } }

  /// Ring segments in order, as habits.
  public var ringHabits: [WidgetHabit] { ring.compactMap { habit($0) } }

  /// Where a tap on the Today ring goes: the first counted habit not done, nil when none.
  public var firstNotDone: WidgetHabit? { ringHabits.first { !$0.isDone } }

  /// The day's progress for the plain ring: done habits count 1, partial ones their share.
  public var dayProgress: Double {
    let h = ringHabits
    guard !h.isEmpty else { return 0 }
    return h.reduce(0) { $0 + ($1.isDone ? 1 : $1.progress) } / Double(h.count)
  }

  /// Up next while the part of the day at `date` is current; nil → Day complete / nothing.
  public func upNext(at date: Date, calendar: Calendar) -> UpNextSection? {
    upNext[PartOfDay.at(date, calendar: calendar)]
  }

  /// Up next's rows: the section's habits, at most `limit`.
  public func rows(_ section: UpNextSection, limit: Int = 3) -> [WidgetHabit] {
    Array(section.habitIds.compactMap { habit($0) }.prefix(limit))
  }

  public init(
    habits: [WidgetHabit], ring: [Int64], done: Int, total: Int, perfect: Bool,
    streak: StreakInfo, upNext: [PartOfDay: UpNextSection]
  ) {
    self.habits = habits
    self.ring = ring
    self.done = done
    self.total = total
    self.perfect = perfect
    self.streak = streak
    self.upNext = upNext
  }

  fileprivate init(raw: RawBlock) {
    habits = (raw.habits ?? []).compactMap { h in
      guard let id = h.id else { return nil }
      return WidgetHabit(
        id: id,
        emoji: h.emoji ?? "",
        name: h.name ?? "",
        category: h.category ?? 1,
        optional: h.optional ?? false,
        progress: min(max(h.progress ?? 0, 0), 1),
        progressText: h.progressText ?? "",
        state: WidgetHabit.State(rawValue: h.state ?? "") ?? .todo,
        completed: h.completed,
        log: h.log.map { l in
          HabitLog(
            kind: l.type.flatMap { HabitLog.Kind(rawValue: $0) },
            target: l.target ?? 0,
            value: l.value ?? 0,
            unit: l.unit ?? "",
            step: max(l.step ?? 1, 1),
            healthLinked: l.healthLinked ?? false,
            watchLoggable: l.watchLoggable ?? false
          )
        } ?? .none
      )
    }
    ring = raw.ring ?? []
    done = raw.done ?? 0
    total = raw.total ?? 0
    perfect = raw.perfect ?? false
    let s = raw.streak
    streak = StreakInfo(
      count: s?.count ?? 0,
      health: StreakInfo.Health(rawValue: s?.health ?? "") ?? .dormant,
      perfectToday: s?.perfectToday ?? false,
      line: s?.line ?? "",
      week: (s?.week ?? []).map { d in
        WeekDay(
          label: d.label ?? "",
          status: WeekDay.Status(rawValue: d.s ?? "") ?? WeekDay.Status.none,
          progress: min(max(d.p ?? 0, 0), 1)
        )
      }
    )
    var up: [PartOfDay: UpNextSection] = [:]
    for part in PartOfDay.allCases {
      guard let sec = raw.upNext?[part.rawValue] ?? nil else { continue }
      up[part] = UpNextSection(
        label: sec.label ?? "", icon: sec.icon ?? part.rawValue, habitIds: sec.habits ?? [])
    }
    upNext = up
  }
}

// MARK: - Timeline and taps

public enum WidgetTimeline {
  /// When what the widgets show can change on its own: now, then every part
  /// of day boundary (04:00, 12:00, 19:00) in the next 24 hours and
  /// `nextDayStartsAt` (when the `tomorrow` block takes over). Sorted, unique.
  public static func entryDates(now: Date, nextDayStartsAt: Date?, calendar: Calendar) -> [Date] {
    let horizon = now.addingTimeInterval(24 * 3600)
    var dates: Set<Date> = []
    let startOfToday = calendar.startOfDay(for: now)
    for dayOffset in 0...1 {
      guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfToday) else { continue }
      for hour in PartOfDay.boundaryHours {
        if let d = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day), d > now, d <= horizon {
          dates.insert(d)
        }
      }
    }
    if let next = nextDayStartsAt, next > now, next <= now.addingTimeInterval(48 * 3600) {
      dates.insert(next)
    }
    return [now] + dates.sorted()
  }
}

/// Widget taps: URLs `WidgetLaunchHandler` understands. `homeWidget` in the
/// query lets home_widget recognise the launch.
public enum WidgetLinks {
  public static let home = URL(string: "habitt://widget/home?homeWidget")!

  public static func log(_ habitId: Int64) -> URL {
    URL(string: "habitt://widget/log?habit=\(habitId)&homeWidget")!
  }

  /// Today ring: Log progress of the first counted habit not done, home when
  /// the day is perfect or empty.
  public static func ring(_ block: DayBlock) -> URL {
    guard !block.perfect, let next = block.firstNotDone else { return home }
    return log(next.id)
  }
}

// MARK: - Raw JSON

private struct RawSnapshot: Decodable {
  var v: Int?
  var dayKey: String?
  var nextDayStartsAt: String?
  var hasHabits: Bool?
  var theme: RawTheme?
  var strings: RawStrings?
  var today: RawBlock?
  var tomorrow: RawBlock?
  var watchAcks: [String]?
}

private struct RawVersion: Decodable {
  var v: Int?
}

private struct RawTheme: Decodable {
  struct Mode: Decodable { var accent: String? }
  var light: Mode?
  var dark: Mode?
}

private struct RawStrings: Decodable {
  var dayStreak: String?
  var daysStreak: String?
  var day: String?
  var days: String?
  var dayComplete: String?
  var dayCompleteBody: String?
  var nothingToday: String?
  var noHabits: String?
}

/// The same `strings` block, every key.
private struct RawStringsMap: Decodable {
  var strings: [String: String]?
}

fileprivate struct RawBlock: Decodable {
  var habits: [RawHabit]?
  var ring: [Int64]?
  var done: Int?
  var total: Int?
  var perfect: Bool?
  var streak: RawStreak?
  var upNext: [String: RawSection?]?
}

fileprivate struct RawHabit: Decodable {
  var id: Int64?
  var emoji: String?
  var name: String?
  var category: Int?
  var optional: Bool?
  var progress: Double?
  var progressText: String?
  var state: String?
  var completed: Bool?
  var log: RawLog?
}

fileprivate struct RawLog: Decodable {
  var type: String?
  var target: Int?
  var value: Int?
  var unit: String?
  var step: Int?
  var healthLinked: Bool?
  var watchLoggable: Bool?
}

fileprivate struct RawStreak: Decodable {
  var count: Int?
  var health: String?
  var perfectToday: Bool?
  var line: String?
  var week: [RawWeekDay]?
}

fileprivate struct RawWeekDay: Decodable {
  var label: String?
  var s: String?
  var p: Double?
}

fileprivate struct RawSection: Decodable {
  var label: String?
  var icon: String?
  var habits: [Int64]?
}
