import Foundation
import SwiftUI
import WatchConnectivity
import WatchKit

/// The watch app's state (docs/watch_app.md): the last snapshot the iPhone
/// sent, and the changes made here that the iPhone hasn't confirmed yet. All
/// habit logic stays on the phone; this only draws, overlays and sends.
@MainActor
final class WatchStore: NSObject, ObservableObject {
  @Published private(set) var snapshot: WidgetSnapshot?
  /// The iPhone sent a snapshot newer than this watch app understands.
  @Published private(set) var updateNeeded = false
  @Published private(set) var outbox: [WatchAction] = []
  /// Moves forward on activation and at the day boundary, so the shown day
  /// rolls over without the phone.
  @Published private(set) var now = Date()

  private let defaults = UserDefaults.standard
  private let calendar = Calendar.current
  private var dayTimer: Timer?

  private static let snapshotKey = "habitt_watch_snapshot"
  private static let outboxKey = "habitt_watch_outbox"
  private static let unsentKey = "habitt_watch_unsent"

  /// Actions created before the session was activated: sent on activation.
  /// Only these are resent; anything handed to WatchConnectivity is delivered
  /// by it, and resending a delivered action could undo a later phone edit.
  private var unsent: Set<String> = []

  override init() {
    super.init()
    if let json = defaults.string(forKey: Self.snapshotKey) {
      snapshot = WidgetSnapshot.decode(json, calendar: calendar)
    }
    if let data = defaults.data(forKey: Self.outboxKey),
      let saved = try? JSONDecoder().decode([WatchAction].self, from: data)
    {
      outbox = saved
    }
    unsent = Set(defaults.stringArray(forKey: Self.unsentKey) ?? [])
    if WCSession.isSupported() {
      WCSession.default.delegate = self
      WCSession.default.activate()
    }
    refreshClock()
  }

  // MARK: What the screen shows

  var accent: Color { Color(hex: snapshot?.accentDark ?? WidgetSnapshot.defaultAccentDark) }

  var shownDay: String? { snapshot?.shownDayKey(at: now, calendar: calendar) }

  /// The day block at `now`, with this watch's unconfirmed changes on top.
  var block: DayBlock? {
    guard let snapshot, let day = shownDay else { return nil }
    return WatchOverlay.apply(snapshot.block(at: now), day: day, outbox: outbox)
  }

  func label(_ key: String, _ fallback: String) -> String {
    snapshot?.strings.labels[key] ?? fallback
  }

  // MARK: Actions

  /// The check: completes a habit that isn't done, un-completes one that is.
  func toggle(_ habit: WidgetHabit) {
    guard !habit.watchReadOnly, let day = shownDay else { return }
    let completing = !habit.isDone
    send(WatchAction(type: completing ? .complete : .uncomplete, habitId: habit.id, day: day))
    if completing { WKInterfaceDevice.current().play(.success) }
  }

  /// Logs an absolute amount (count) or duration (seconds).
  func setValue(_ value: Int, for habit: WidgetHabit) {
    guard habit.log.watchLoggable, let day = shownDay else { return }
    let type: WatchAction.Kind = habit.log.kind == .duration ? .setDuration : .setAmount
    let wasDone = habit.isDone
    send(WatchAction(type: type, habitId: habit.id, day: day, value: max(value, 0)))
    if !wasDone, habit.log.target > 0, value >= habit.log.target {
      WKInterfaceDevice.current().play(.success)
    }
  }

  private func send(_ action: WatchAction) {
    outbox.append(action)
    if outbox.count > WatchOverlay.maxOutbox { outbox.removeFirst(outbox.count - WatchOverlay.maxOutbox) }
    saveOutbox()
    transmit(action)
  }

  /// A direct message when the iPhone is reachable (wakes its app), else a
  /// queued transfer the system delivers once the devices reconnect.
  private func transmit(_ action: WatchAction) {
    guard WCSession.isSupported() else { return }
    let session = WCSession.default
    let message = action.message
    guard session.activationState == .activated else {
      unsent.insert(action.id)
      saveOutbox()
      return
    }
    if session.isReachable {
      session.sendMessage(message, replyHandler: { _ in }) { _ in
        // not delivered: hand it to the guaranteed queue (the phone drops duplicates)
        session.transferUserInfo(message)
      }
    } else {
      session.transferUserInfo(message)
    }
  }

  /// Sends what the session couldn't take before it was activated.
  private func resendUnsent() {
    guard !unsent.isEmpty else { return }
    let waiting = outbox.filter { unsent.contains($0.id) }
    unsent = []
    saveOutbox()
    for action in waiting { transmit(action) }
  }

  // MARK: Snapshot

  fileprivate func receive(snapshotJSON json: String) {
    if let v = WidgetSnapshot.peekVersion(json), v > WidgetSnapshot.version {
      updateNeeded = true
      return
    }
    guard let decoded = WidgetSnapshot.decode(json, calendar: calendar) else { return }
    updateNeeded = false
    snapshot = decoded
    defaults.set(json, forKey: Self.snapshotKey)
    refreshClock()
  }

  /// Re-reads the clock, drops confirmed or stale changes and arms a timer
  /// for the next day boundary.
  func refreshClock() {
    now = Date()
    if let snapshot, let day = shownDay {
      let pruned = WatchOverlay.prune(outbox, snapshot: snapshot, shownDay: day)
      if pruned != outbox {
        outbox = pruned
        saveOutbox()
      }
    }
    dayTimer?.invalidate()
    if let next = snapshot?.nextDayStartsAt, next > now {
      dayTimer = Timer.scheduledTimer(withTimeInterval: next.timeIntervalSince(now) + 1, repeats: false) {
        [weak self] _ in
        Task { @MainActor in self?.refreshClock() }
      }
    }
  }

  private func saveOutbox() {
    if let data = try? JSONEncoder().encode(outbox) { defaults.set(data, forKey: Self.outboxKey) }
    unsent = unsent.intersection(outbox.map(\.id))
    defaults.set(Array(unsent), forKey: Self.unsentKey)
  }
}

// MARK: - WCSessionDelegate

extension WatchStore: WCSessionDelegate {
  nonisolated func session(
    _ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?
  ) {
    let json = session.receivedApplicationContext["snapshot"] as? String
    Task { @MainActor in
      if let json { self.receive(snapshotJSON: json) }
      if activationState == .activated { self.resendUnsent() }
    }
  }

  nonisolated func session(_ session: WCSession, didReceiveApplicationContext context: [String: Any]) {
    guard let json = context["snapshot"] as? String else { return }
    Task { @MainActor in self.receive(snapshotJSON: json) }
  }

  nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    guard let json = message["snapshot"] as? String else { return }
    Task { @MainActor in self.receive(snapshotJSON: json) }
  }
}

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
}

/// The watch app's own UI strings (`<lang>.lproj/Localizable.strings`,
/// generated from the ARB files by tool/gen_ios_widget_strings.dart).
func L(_ key: String) -> String { NSLocalizedString(key, comment: "") }

func L(_ key: String, _ arg: String) -> String { String(format: L(key), arg) }
