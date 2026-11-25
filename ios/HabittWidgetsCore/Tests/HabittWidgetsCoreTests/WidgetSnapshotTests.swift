import XCTest

@testable import HabittWidgetsCore

final class WidgetSnapshotTests: XCTestCase {
  private var calendar: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "Europe/Sarajevo")!
    return c
  }()

  private func date(_ s: String) -> Date {
    WidgetSnapshot.parseLocalDateTime(s, calendar: calendar)!
  }

  private let shower: Int64 = 1_795_574_050_137_094
  private let read: Int64 = 1_795_574_050_999_001

  private var json: String {
    """
    {
      "v": 1,
      "generatedAt": "2026-11-24T08:30:00.000",
      "dayKey": "2026-11-24",
      "nextDayStartsAt": "2026-11-25T00:00:00.000",
      "hasHabits": true,
      "theme": { "light": { "accent": "#955FD8" }, "dark": { "accent": "#BA86FF" } },
      "strings": {
        "dayStreak": "day streak", "daysStreak": "days streak", "day": "day", "days": "days",
        "dayComplete": "Day complete", "dayCompleteBody": "All 2 habits done.",
        "nothingToday": "Nothing scheduled today", "noHabits": "No habits"
      },
      "today": {
        "habits": [
          { "id": \(shower), "emoji": "🚿", "name": "Shower", "category": 2, "optional": false,
            "progress": 0.8, "progressText": "8m / 10m", "state": "partial", "canLog": true },
          { "id": \(read), "emoji": "📖", "name": "Read", "category": 4, "optional": false,
            "progress": 1, "progressText": "", "state": "done", "canLog": true }
        ],
        "ring": [\(shower), \(read)],
        "done": 1, "total": 2, "perfect": false,
        "streak": { "count": 12, "health": "fading", "perfectToday": false, "line": "Keep it up!",
          "week": [{ "label": "W", "s": "perfect", "p": 1.0 }, { "label": "T", "s": "today", "p": 0.5 }] },
        "upNext": {
          "morning": { "label": "Morning", "icon": "morning", "habits": [\(shower)] },
          "afternoon": { "label": "Any time", "icon": "anyTime", "habits": [\(shower)] },
          "evening": null
        }
      },
      "tomorrow": {
        "habits": [], "ring": [], "done": 0, "total": 0, "perfect": false,
        "streak": { "count": 0, "health": "dormant", "perfectToday": false, "line": "Start", "week": [] },
        "upNext": { "morning": null, "afternoon": null, "evening": null }
      }
    }
    """
  }

  func testDecodesFullSnapshot() throws {
    let s = try XCTUnwrap(WidgetSnapshot.decode(json, calendar: calendar))
    XCTAssertEqual(s.dayKey, "2026-11-24")
    XCTAssertEqual(s.nextDayStartsAt, date("2026-11-25T00:00:00.000"))
    XCTAssertEqual(s.accentLight, 0x955FD8)
    XCTAssertEqual(s.accentDark, 0xBA86FF)
    XCTAssertTrue(s.hasHabits)
    XCTAssertEqual(s.strings.streakLabel(1), "day streak")
    XCTAssertEqual(s.strings.streakLabel(12), "days streak")
    XCTAssertEqual(s.today.habits.count, 2)
    XCTAssertEqual(s.today.habits[0].state, .partial)
    XCTAssertEqual(s.today.habits[0].progress, 0.8)
    XCTAssertEqual(s.today.habits[1].progress, 1)
    XCTAssertEqual(s.today.streak.health, .fading)
    XCTAssertEqual(s.today.streak.week.map(\.status), [.perfect, .today])
    XCTAssertEqual(s.today.upNext[.afternoon]?.icon, "anyTime")
    XCTAssertNil(s.today.upNext[.evening])
    XCTAssertEqual(s.tomorrow.streak.health, .dormant)
  }

  func testSixteenDigitIdsStayExact() throws {
    let s = try XCTUnwrap(WidgetSnapshot.decode(json, calendar: calendar))
    XCTAssertEqual(s.today.ring, [shower, read])
    XCTAssertEqual(s.today.habits[0].id, 1_795_574_050_137_094)
    XCTAssertEqual(WidgetLinks.log(shower).absoluteString, "habitt://widget/log?habit=1795574050137094&homeWidget")
  }

  func testRejectsMissingOtherVersionOrMalformed() {
    XCTAssertNil(WidgetSnapshot.decode(nil))
    XCTAssertNil(WidgetSnapshot.decode(""))
    XCTAssertNil(WidgetSnapshot.decode("{not json"))
    XCTAssertNil(WidgetSnapshot.decode(json.replacingOccurrences(of: "\"v\": 1", with: "\"v\": 2"), calendar: calendar))
  }

  func testOlderSnapshotFallsBack() throws {
    let old = """
      { "v": 1, "dayKey": "2026-11-24", "nextDayStartsAt": "2026-11-25",
        "strings": { "dayStreak": "dan streak", "daysStreak": "dana streak" },
        "theme": { "light": { "accent": "nope" } },
        "today": { "habits": [{ "id": 1, "state": "weird" }] }, "tomorrow": {} }
      """
    let s = try XCTUnwrap(WidgetSnapshot.decode(old, calendar: calendar))
    XCTAssertEqual(s.strings.day, "dan")
    XCTAssertEqual(s.strings.days, "dana")
    XCTAssertEqual(s.strings.noHabits, WidgetSnapshot.defaultNoHabits)
    XCTAssertEqual(s.accentLight, WidgetSnapshot.defaultAccentLight)
    XCTAssertEqual(s.accentDark, WidgetSnapshot.defaultAccentDark)
    XCTAssertTrue(s.hasHabits)
    XCTAssertEqual(s.today.habits.first?.state, .todo)
    XCTAssertEqual(s.today.streak.health, .dormant)
    XCTAssertEqual(s.nextDayStartsAt, date("2026-11-25T00:00:00.000"))
  }

  func testTodayOrTomorrowByClock() throws {
    let s = try XCTUnwrap(WidgetSnapshot.decode(json, calendar: calendar))
    XCTAssertEqual(s.block(at: date("2026-11-24T23:59:59.000")), s.today)
    XCTAssertEqual(s.block(at: date("2026-11-25T00:00:00.000")), s.tomorrow)
    XCTAssertEqual(s.block(at: date("2026-11-26T10:00:00.000")), s.tomorrow)
  }

  func testPartsOfDay() {
    let cases: [(String, PartOfDay)] = [
      ("03:59", .evening), ("04:00", .morning), ("11:59", .morning), ("12:00", .afternoon),
      ("18:59", .afternoon), ("19:00", .evening), ("00:00", .evening),
    ]
    for (time, part) in cases {
      XCTAssertEqual(PartOfDay.at(date("2026-11-24T\(time):00.000"), calendar: calendar), part, time)
    }
  }

  func testUpNextSectionByClock() throws {
    let s = try XCTUnwrap(WidgetSnapshot.decode(json, calendar: calendar))
    XCTAssertEqual(s.today.upNext(at: date("2026-11-24T08:00:00.000"), calendar: calendar)?.label, "Morning")
    XCTAssertEqual(s.today.upNext(at: date("2026-11-24T13:00:00.000"), calendar: calendar)?.label, "Any time")
    XCTAssertNil(s.today.upNext(at: date("2026-11-24T20:00:00.000"), calendar: calendar))
  }

  func testRingTapTarget() throws {
    let s = try XCTUnwrap(WidgetSnapshot.decode(json, calendar: calendar))
    XCTAssertEqual(WidgetLinks.ring(s.today), WidgetLinks.log(shower))
    var perfect = s.today
    perfect.perfect = true
    XCTAssertEqual(WidgetLinks.ring(perfect), WidgetLinks.home)
    XCTAssertEqual(WidgetLinks.ring(s.tomorrow), WidgetLinks.home)
    XCTAssertEqual(WidgetLinks.home.absoluteString, "habitt://widget/home?homeWidget")
  }

  func testDayProgressForThePlainRing() throws {
    let s = try XCTUnwrap(WidgetSnapshot.decode(json, calendar: calendar))
    XCTAssertEqual(s.today.dayProgress, 0.9, accuracy: 0.0001)
    XCTAssertEqual(s.tomorrow.dayProgress, 0)
  }

  func testTimelineEntriesMorning() {
    let now = date("2026-11-24T08:30:00.000")
    let dates = WidgetTimeline.entryDates(
      now: now, nextDayStartsAt: date("2026-11-25T00:00:00.000"), calendar: calendar)
    XCTAssertEqual(
      dates,
      [
        now, date("2026-11-24T12:00:00.000"), date("2026-11-24T19:00:00.000"),
        date("2026-11-25T00:00:00.000"), date("2026-11-25T04:00:00.000"),
      ])
  }

  func testTimelineEntriesLateEveningAndPastDayStart() {
    let now = date("2026-11-24T23:30:00.000")
    let dates = WidgetTimeline.entryDates(
      now: now, nextDayStartsAt: date("2026-11-24T22:00:00.000"), calendar: calendar)
    XCTAssertEqual(
      dates,
      [now, date("2026-11-25T04:00:00.000"), date("2026-11-25T12:00:00.000"), date("2026-11-25T19:00:00.000")])
  }

  func testTimelineEntriesNonMidnightDayStart() {
    let now = date("2026-11-24T20:00:00.000")
    let dates = WidgetTimeline.entryDates(
      now: now, nextDayStartsAt: date("2026-11-25T03:00:00.000"), calendar: calendar)
    XCTAssertEqual(
      dates,
      [
        now, date("2026-11-25T03:00:00.000"), date("2026-11-25T04:00:00.000"),
        date("2026-11-25T12:00:00.000"), date("2026-11-25T19:00:00.000"),
      ])
  }

  func testTimelineAcrossDaylightSavingChange() {
    var c = calendar
    c.timeZone = TimeZone(identifier: "Europe/Sarajevo")!
    let now = WidgetSnapshot.parseLocalDateTime("2026-03-29T01:00:00.000", calendar: c)!
    let dates = WidgetTimeline.entryDates(now: now, nextDayStartsAt: nil, calendar: c)
    let hours = dates.dropFirst().map { c.component(.hour, from: $0) }
    XCTAssertEqual(hours, [4, 12, 19])
  }

  func testGallerySample() {
    let strings = WidgetSnapshot.Strings(
      dayStreak: "day streak", daysStreak: "days streak", day: "day", days: "days",
      dayComplete: "", dayCompleteBody: "", nothingToday: "", noHabits: "")
    let s = WidgetSnapshot.sample(
      strings: strings, names: ["Brush teeth", "Shower", "Drink water", "Read", "Mindfulness"],
      partLabels: [.morning: "Morning", .afternoon: "Afternoon", .evening: "Evening"],
      line: "Well done, you!", weekLabels: ["T", "W", "T", "F", "S", "S", "M"])
    XCTAssertTrue(s.hasHabits)
    XCTAssertEqual(s.today.streak.count, 12)
    XCTAssertEqual(s.today.streak.week.count, 7)
    XCTAssertEqual(s.today.ringHabits.map(\.name).first, "Brush teeth")
    XCTAssertEqual(s.today.done, 1)
    XCTAssertEqual(s.today.total, 5)
    XCTAssertEqual(s.today.upNext(at: date("2026-11-24T20:00:00.000"), calendar: calendar)?.label, "Evening")
    XCTAssertEqual(s.today.rows(s.today.upNext[.morning]!).map(\.id), [1, 2, 3])
    XCTAssertEqual(s.block(at: Date()), s.today)
  }

  func testPlaceholder() {
    let strings = WidgetSnapshot.Strings(
      dayStreak: "day streak", daysStreak: "days streak", day: "day", days: "days",
      dayComplete: "", dayCompleteBody: "", nothingToday: "None", noHabits: "None")
    let p = WidgetSnapshot.placeholder(
      strings: strings, startStreak: "Start", weekLabels: ["T", "W", "T", "F", "S", "S", "M"], dayKey: "2026-11-24")
    XCTAssertFalse(p.hasHabits)
    XCTAssertEqual(p.today.streak.count, 0)
    XCTAssertEqual(p.today.streak.health, .dormant)
    XCTAssertEqual(p.today.streak.week.last?.status, .today)
    XCTAssertEqual(p.today.streak.week.first?.status, WeekDay.Status.none)
    XCTAssertEqual(p.block(at: Date()), p.today)
    XCTAssertEqual(WidgetLinks.ring(p.today), WidgetLinks.home)
  }
}
