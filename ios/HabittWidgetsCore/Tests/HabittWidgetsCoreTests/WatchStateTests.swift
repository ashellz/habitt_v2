import XCTest

@testable import HabittWidgetsCore

final class WatchStateTests: XCTestCase {
  private var calendar: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "Europe/Sarajevo")!
    return c
  }()

  private let day = "2026-11-25"

  private func habit(
    _ id: Int64, kind: HabitLog.Kind?, target: Int = 0, value: Int = 0, unit: String = "",
    state: WidgetHabit.State = .todo, optional: Bool = false
  ) -> WidgetHabit {
    WidgetHabit(
      id: id, emoji: "📖", name: "H\(id)", optional: optional,
      progress: target > 0 ? min(Double(value) / Double(target), 1) : (state == .done ? 1 : 0),
      progressText: "", state: state,
      log: HabitLog(kind: kind, target: target, value: value, unit: unit, step: kind == .duration ? 60 : 1,
        watchLoggable: kind == .amount || kind == .duration))
  }

  private func block(_ habits: [WidgetHabit]) -> DayBlock {
    let counted = habits.filter { !$0.optional }
    return DayBlock(
      habits: habits, ring: counted.map(\.id), done: counted.filter(\.isDone).count, total: counted.count,
      perfect: false,
      streak: StreakInfo(count: 0, health: .dormant, perfectToday: false, line: "", week: []),
      upNext: [:])
  }

  private func action(_ type: WatchAction.Kind, _ habitId: Int64, value: Int? = nil, id: String = UUID().uuidString)
    -> WatchAction
  {
    WatchAction(id: id, type: type, habitId: habitId, day: day, value: value, calendar: calendar)
  }

  func testCompleteSimpleHabit() {
    let b = WatchOverlay.apply(block([habit(1, kind: nil)]), day: day, outbox: [action(.complete, 1)])
    XCTAssertEqual(b.habits[0].state, .done)
    XCTAssertTrue(b.habits[0].completed)
    XCTAssertEqual(b.done, 1)
    XCTAssertTrue(b.perfect)
  }

  func testUncompleteResetsValue() {
    let read = habit(1, kind: .amount, target: 10, value: 10, unit: "pages", state: .done)
    let b = WatchOverlay.apply(block([read]), day: day, outbox: [action(.uncomplete, 1)])
    XCTAssertEqual(b.habits[0].state, .todo)
    XCTAssertEqual(b.habits[0].log.value, 0)
    XCTAssertEqual(b.habits[0].progressText, "10 pages")
    XCTAssertEqual(b.done, 0)
  }

  func testSetAmountPartialAndReachingTarget() {
    let read = habit(1, kind: .amount, target: 10, value: 3, unit: "pages")
    let partial = WatchOverlay.apply(block([read]), day: day, outbox: [action(.setAmount, 1, value: 8)])
    XCTAssertEqual(partial.habits[0].state, .partial)
    XCTAssertEqual(partial.habits[0].progress, 0.8, accuracy: 0.0001)
    XCTAssertEqual(partial.habits[0].progressText, "8 / 10 pages")

    let done = WatchOverlay.apply(
      block([read]), day: day, outbox: [action(.setAmount, 1, value: 8), action(.setAmount, 1, value: 10)])
    XCTAssertEqual(done.habits[0].state, .done)
    XCTAssertTrue(done.habits[0].completed)
    XCTAssertEqual(done.habits[0].progressText, "10 pages")
  }

  func testSetDurationText() {
    let meditate = habit(1, kind: .duration, target: 600, value: 0)
    let b = WatchOverlay.apply(block([meditate]), day: day, outbox: [action(.setDuration, 1, value: 360)])
    XCTAssertEqual(b.habits[0].progressText, "6m / 10m")
    XCTAssertEqual(WatchOverlay.durationString(3900), "1h5m")
    XCTAssertEqual(WatchOverlay.durationString(0), "0m")
  }

  func testOptionalHabitIsNotCounted() {
    let b = WatchOverlay.apply(
      block([habit(1, kind: nil), habit(2, kind: nil, optional: true)]), day: day,
      outbox: [action(.complete, 2)])
    XCTAssertEqual(b.done, 0)
    XCTAssertEqual(b.total, 1)
    XCTAssertEqual(b.habits[1].state, .done)
  }

  func testActionsForAnotherDayAreIgnored() {
    var other = action(.complete, 1)
    other.day = "2026-11-24"
    let b = WatchOverlay.apply(block([habit(1, kind: nil)]), day: day, outbox: [other])
    XCTAssertEqual(b.habits[0].state, .todo)
  }

  func testPruneDropsAckedAndOtherDays() throws {
    let json = """
      { "v": 1, "dayKey": "2026-11-25", "nextDayStartsAt": "2026-11-26T00:00:00.000",
        "today": {}, "tomorrow": {}, "watchAcks": ["done-1"] }
      """
    let s = try XCTUnwrap(WidgetSnapshot.decode(json, calendar: calendar))
    var old = action(.complete, 3, id: "old")
    old.day = "2026-11-24"
    let outbox = [action(.complete, 1, id: "done-1"), action(.complete, 2, id: "pending"), old]
    let shown = s.shownDayKey(at: WidgetSnapshot.parseLocalDateTime("2026-11-25T10:00:00", calendar: calendar)!,
      calendar: calendar)
    XCTAssertEqual(shown, "2026-11-25")
    XCTAssertEqual(WatchOverlay.prune(outbox, snapshot: s, shownDay: shown).map(\.id), ["pending"])
  }

  func testShownDayRollsOver() throws {
    let json = """
      { "v": 1, "dayKey": "2026-11-25", "nextDayStartsAt": "2026-11-26T00:00:00.000", "today": {}, "tomorrow": {} }
      """
    let s = try XCTUnwrap(WidgetSnapshot.decode(json, calendar: calendar))
    let late = WidgetSnapshot.parseLocalDateTime("2026-11-26T00:30:00", calendar: calendar)!
    XCTAssertEqual(s.shownDayKey(at: late, calendar: calendar), "2026-11-26")
  }

  func testActionMessage() throws {
    let at = WidgetSnapshot.parseLocalDateTime("2026-11-25T08:31:02", calendar: calendar)!
    let a = WatchAction(id: "x", type: .setAmount, habitId: 1_795_574_050_137_094, day: day, value: 8, at: at,
      calendar: calendar)
    let m = try XCTUnwrap(a.message["watchAction"] as? [String: Any])
    XCTAssertEqual(m["v"] as? Int, 1)
    XCTAssertEqual(m["type"] as? String, "setAmount")
    XCTAssertEqual(m["habitId"] as? Int64, 1_795_574_050_137_094)
    XCTAssertEqual(m["value"] as? Int, 8)
    XCTAssertEqual(m["at"] as? String, "2026-11-25T08:31:02.000")
    XCTAssertNil(WatchAction(type: .complete, habitId: 1, day: day).message["watchAction"].flatMap {
      ($0 as? [String: Any])?["value"]
    })
  }
}
