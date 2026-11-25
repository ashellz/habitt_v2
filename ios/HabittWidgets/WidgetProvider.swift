import Foundation
import WidgetKit
import os

// One timeline provider for all four widgets: reads the snapshot the app
// wrote to the App Group, and schedules an entry at every moment what the
// widgets show can change without the app (part of day boundaries, the next
// day). See docs/home_widgets.md.

struct HabittEntry: TimelineEntry {
  let date: Date
  let snapshot: WidgetSnapshot

  /// The day block for this entry's time: `tomorrow` from `nextDayStartsAt` on.
  var block: DayBlock { snapshot.block(at: date) }
}

enum WidgetStore {
  static let log = Logger(subsystem: "com.shellz.habitt.widgets", category: "timeline")

  static func load() -> WidgetSnapshot? {
    let json = UserDefaults(suiteName: WidgetSnapshot.appGroup)?.string(forKey: WidgetSnapshot.storageKey)
    return WidgetSnapshot.decode(json)
  }

  /// The snapshot, or before the app wrote its first one (installed, never
  /// opened) no habits and a 0 streak, in the device language.
  static func current(now: Date) -> WidgetSnapshot {
    load() ?? placeholder(now: now)
  }

  private static func s(_ key: String) -> String { NSLocalizedString(key, comment: "") }

  /// The snapshot strings from the extension's own Localizable.strings.
  private static var localStrings: WidgetSnapshot.Strings {
    let noHabits = s("youHaventAddedAnyHabitsYet")
    return .init(
      dayStreak: s("dayStreakLabel"), daysStreak: s("daysStreakLabel"),
      day: s("day"), days: s("days"),
      dayComplete: "", dayCompleteBody: "",
      nothingToday: noHabits, noHabits: noHabits
    )
  }

  static func placeholder(now: Date) -> WidgetSnapshot {
    WidgetSnapshot.placeholder(
      strings: localStrings,
      startStreak: s("widgetStartStreak"),
      weekLabels: weekLabels(endingAt: now),
      dayKey: ""
    )
  }

  /// The widget gallery while the user has no habits yet (or never opened
  /// the app): sample habits in the device language instead of an empty box.
  static func gallery(now: Date) -> WidgetSnapshot {
    if let stored = load(), stored.hasHabits { return stored }
    return WidgetSnapshot.sample(
      strings: localStrings,
      names: ["premadeHabitBrushTeeth", "premadeHabitShower", "premadeHabitDrinkWater", "premadeHabitRead",
              "premadeHabitMindfulness"].map(s),
      partLabels: [.morning: s("morning"), .afternoon: s("afternoon"), .evening: s("evening")],
      line: s("streakPraiseExtra2"),
      weekLabels: weekLabels(endingAt: now)
    )
  }

  /// Narrow weekday names of the 7 days ending `date`, in the language the
  /// extension's strings resolved to.
  private static func weekLabels(endingAt date: Date) -> [String] {
    let language = Bundle.main.preferredLocalizations.first ?? "en"
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: language)
    let symbols = formatter.veryShortStandaloneWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
    let calendar = Calendar.current
    return (0..<7).reversed().map { back in
      let day = calendar.date(byAdding: .day, value: -back, to: date) ?? date
      return symbols[calendar.component(.weekday, from: day) - 1]
    }
  }
}

struct HabittProvider: TimelineProvider {
  /// Names the widget in the log.
  let kind: String

  /// Shown redacted while a widget loads: the gallery sample's shapes.
  func placeholder(in context: Context) -> HabittEntry {
    HabittEntry(date: Date(), snapshot: WidgetStore.gallery(now: Date()))
  }

  func getSnapshot(in context: Context, completion: @escaping (HabittEntry) -> Void) {
    let now = Date()
    // the gallery shows sample habits until the user has their own
    let snapshot = context.isPreview ? WidgetStore.gallery(now: now) : WidgetStore.current(now: now)
    completion(HabittEntry(date: now, snapshot: snapshot))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<HabittEntry>) -> Void) {
    let now = Date()
    let stored = WidgetStore.load()
    let snapshot = stored ?? WidgetStore.placeholder(now: now)
    let calendar = Calendar.current
    let dates = WidgetTimeline.entryDates(
      now: now,
      nextDayStartsAt: stored?.nextDayStartsAt,
      calendar: calendar
    )
    let entries = dates.map { HabittEntry(date: $0, snapshot: snapshot) }
    let formatter = ISO8601DateFormatter()
    formatter.timeZone = calendar.timeZone
    let plan = entries.map { e -> String in
      let block = e.block == snapshot.today ? "today" : "tomorrow"
      let part = PartOfDay.at(e.date, calendar: calendar).rawValue
      let up = e.block.upNext(at: e.date, calendar: calendar)?.label ?? "-"
      return "\(formatter.string(from: e.date)) \(block) \(part) upNext=\(up) streak=\(e.block.streak.count)"
    }
    WidgetStore.log.notice(
      "\(kind, privacy: .public) day=\(snapshot.dayKey, privacy: .public) snapshot=\(stored != nil, privacy: .public) entries: \(plan.joined(separator: " | "), privacy: .public)"
    )
    completion(Timeline(entries: entries, policy: .atEnd))
  }
}
