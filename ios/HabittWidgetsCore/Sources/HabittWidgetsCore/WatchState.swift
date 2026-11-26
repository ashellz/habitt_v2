import Foundation

// The Apple Watch side of the watch ↔ phone contract (docs/watch_app.md).
// Foundation only, so it is unit tested on the Mac with `swift test` and
// compiled as is into the HabittWatch app.

/// What the watch asks the phone to do. Values are absolute ("set 8"), never
/// increments, so a resend or a duplicate is harmless.
public struct WatchAction: Codable, Equatable, Identifiable {
  /// Bumped only for a breaking change to this message.
  public static let version = 1

  public enum Kind: String, Codable { case complete, uncomplete, setAmount, setDuration }

  public var v: Int
  public var id: String
  public var type: Kind
  public var habitId: Int64
  /// The `yyyy-MM-dd` key of the day block the user acted on.
  public var day: String
  /// setAmount: the count. setDuration: seconds. Absent otherwise.
  public var value: Int?
  /// Watch local time, `yyyy-MM-ddTHH:mm:ss.SSS`, for ordering on the phone.
  public var at: String

  public init(
    id: String = UUID().uuidString, type: Kind, habitId: Int64, day: String, value: Int? = nil,
    at: Date = Date(), calendar: Calendar = .current
  ) {
    self.v = Self.version
    self.id = id
    self.type = type
    self.habitId = habitId
    self.day = day
    self.value = value
    self.at = WatchDates.localTimestamp(at, calendar: calendar)
  }

  /// The message dictionary sent over WatchConnectivity.
  public var message: [String: Any] {
    var m: [String: Any] = [
      "v": v, "id": id, "type": type.rawValue, "habitId": habitId, "day": day, "at": at,
    ]
    if let value { m["value"] = value }
    return ["watchAction": m]
  }
}

public enum WatchDates {
  /// `yyyy-MM-dd` of `date` in `calendar`'s time zone.
  public static func dayKey(_ date: Date, calendar: Calendar) -> String {
    let c = calendar.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
  }

  /// Like Dart's `DateTime.toIso8601String()` of a local time.
  public static func localTimestamp(_ date: Date, calendar: Calendar) -> String {
    let c = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: date)
    return String(
      format: "%04d-%02d-%02dT%02d:%02d:%02d.%03d", c.year ?? 0, c.month ?? 0, c.day ?? 0,
      c.hour ?? 0, c.minute ?? 0, c.second ?? 0, (c.nanosecond ?? 0) / 1_000_000)
  }
}

extension WidgetSnapshot {
  /// The key of the day the watch shows at `now`: `dayKey`, or tomorrow's
  /// once `nextDayStartsAt` has passed.
  public func shownDayKey(at now: Date, calendar: Calendar) -> String {
    now >= nextDayStartsAt ? WatchDates.dayKey(nextDayStartsAt, calendar: calendar) : dayKey
  }
}

/// The watch's own changes on top of the phone's snapshot, until the phone
/// confirms them.
public enum WatchOverlay {
  /// How many unconfirmed actions the watch keeps at most.
  public static let maxOutbox = 100

  /// Drops actions the phone acknowledged and actions for a day the watch
  /// no longer shows.
  public static func prune(_ outbox: [WatchAction], snapshot: WidgetSnapshot, shownDay: String) -> [WatchAction] {
    let acked = Set(snapshot.watchAcks)
    let kept = outbox.filter { !acked.contains($0.id) && $0.day == shownDay }
    return Array(kept.suffix(maxOutbox))
  }

  /// `block` with the latest outbox action of each habit applied, and the
  /// day's done/total/perfect recounted.
  public static func apply(_ block: DayBlock, day: String, outbox: [WatchAction]) -> DayBlock {
    var latest: [Int64: WatchAction] = [:]
    for a in outbox where a.day == day { latest[a.habitId] = a }
    guard !latest.isEmpty else { return block }

    var out = block
    out.habits = block.habits.map { h in
      guard let a = latest[h.id] else { return h }
      return applying(a, to: h)
    }
    let counted = out.ringHabits
    out.done = counted.filter(\.isDone).count
    out.total = counted.count
    out.perfect = !counted.isEmpty && out.done == counted.count
    return out
  }

  /// What `action` does to `habit`, mirroring the app: completing sets the
  /// value to the target, un-completing resets it to 0, a value at or over
  /// the target completes.
  public static func applying(_ action: WatchAction, to habit: WidgetHabit) -> WidgetHabit {
    var h = habit
    let target = h.log.target
    switch action.type {
    case .complete:
      h.completed = true
      if h.log.kind != nil { h.log.value = target }
    case .uncomplete:
      h.completed = false
      h.log.value = 0
    case .setAmount, .setDuration:
      let value = max(action.value ?? 0, 0)
      h.log.value = value
      h.completed = target > 0 && value >= target
    }
    if h.completed {
      h.state = .done
      h.progress = 1
    } else {
      h.progress = target > 0 ? min(Double(h.log.value) / Double(target), 1) : 0
      h.state = h.progress > 0 ? .partial : .todo
    }
    h.progressText = progressText(h)
    return h
  }

  /// The habit card's progress line for the overlaid value ("3 / 10 pages",
  /// "6m / 10m"); the snapshot's own text is stale once the value changed.
  public static func progressText(_ h: WidgetHabit) -> String {
    let log = h.log
    switch log.kind {
    case .amount:
      let unit = log.unit.isEmpty ? "" : " \(log.unit)"
      if h.completed { return "\(log.value)\(unit)" }
      if log.value > 0 { return "\(log.value) / \(log.target)\(unit)" }
      return "\(log.target)\(unit)"
    case .duration:
      if h.completed || log.value >= log.target { return durationString(log.value) }
      if log.value > 0 { return "\(durationString(log.value)) / \(durationString(log.target))" }
      return durationString(log.target)
    default:
      return h.progressText
    }
  }

  /// Same as the app's `getDurationString`: "1h5m", "10m", "30s", "0m".
  public static func durationString(_ seconds: Int) -> String {
    let h = seconds / 3600, m = (seconds % 3600) / 60, s = seconds % 60
    var parts: [String] = []
    if h > 0 { parts.append("\(h)h") }
    if m > 0 { parts.append("\(m)m") }
    if s > 0 { parts.append("\(s)s") }
    return parts.isEmpty ? "0m" : parts.joined()
  }
}
