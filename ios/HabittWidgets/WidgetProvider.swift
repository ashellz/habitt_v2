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

  static func placeholder(now: Date) -> WidgetSnapshot {
    let s = { (key: String) in NSLocalizedString(key, comment: "") }
    let noHabits = s("youHaventAddedAnyHabitsYet")
    return WidgetSnapshot.placeholder(
      strings: .init(
        dayStreak: s("dayStreakLabel"), daysStreak: s("daysStreakLabel"),
        day: s("day"), days: s("days"),
        dayComplete: "", dayCompleteBody: "",
        nothingToday: noHabits, noHabits: noHabits
      ),
      startStreak: s("widgetStartStreak"),
      weekLabels: weekLabels(endingAt: now),
      dayKey: ""
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

  func placeholder(in context: Context) -> HabittEntry {
    HabittEntry(date: Date(), snapshot: WidgetStore.current(now: Date()))
  }

  func getSnapshot(in context: Context, completion: @escaping (HabittEntry) -> Void) {
    completion(placeholder(in: context))
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
