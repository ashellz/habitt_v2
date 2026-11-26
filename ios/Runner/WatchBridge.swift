import Flutter
import Foundation
import UIKit
import WatchConnectivity

// The iPhone side of the Apple Watch app (docs/watch_app.md).
//
// Phone → watch: Dart calls `habitt/watch#pushSnapshot(json)` whenever it
// writes the widget snapshot; it becomes the WCSession application context
// (latest wins) and, when the watch app is open, a direct message too.
//
// Watch → phone: actions arrive as messages or user-info transfers. Each one
// is appended to a durable queue in UserDefaults FIRST, then Dart is told
// (`actionsAvailable`) if it is running. Dart reads and removes entries only
// through this bridge (`peekActions` / `removeActions`), on the main thread,
// so an append can never be lost to a concurrent removal. When the app isn't
// running, the actions wait for the next launch.

final class WatchBridge: NSObject, WCSessionDelegate {
  static let shared = WatchBridge()

  static let queueKey = "habitt_watch_pending_actions"
  static let lastSnapshotKey = "habitt_watch_last_snapshot"
  /// Older entries are dropped beyond this many (a watch can't produce more).
  static let maxQueue = 500

  private var channel: FlutterMethodChannel?
  private let defaults = UserDefaults.standard
  /// Keeps the app running while Dart applies a watch action that woke it in
  /// the background, so the snapshot (widgets, watch) is written before iOS
  /// suspends it again. Ended by `drainDone`, or after `backgroundGrace`.
  private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
  private static let backgroundGrace: TimeInterval = 20

  /// Starts WCSession. Call from `didFinishLaunching`, so actions that woke
  /// the app in the background are received even before Flutter is up.
  func activate() {
    guard WCSession.isSupported() else { return }
    let session = WCSession.default
    session.delegate = self
    session.activate()
  }

  /// Wires the `habitt/watch` channel once the Flutter engine exists.
  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "habitt/watch", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return result(nil) }
      switch call.method {
      case "pushSnapshot":
        if let json = call.arguments as? String { self.push(json) }
        result(nil)
      case "peekActions":
        result(self.queueJSON())
      case "removeActions":
        self.remove(ids: Set((call.arguments as? [String]) ?? []))
        result(nil)
      case "drainDone":
        self.endBackgroundTask()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
    // anything that arrived before Dart listened is drained on start anyway
  }

  // MARK: Phone → watch

  private func push(_ json: String) {
    defaults.set(json, forKey: Self.lastSnapshotKey)
    sendSnapshot(json)
  }

  private func sendSnapshot(_ json: String) {
    guard WCSession.isSupported() else { return }
    let session = WCSession.default
    guard session.activationState == .activated, session.isPaired, session.isWatchAppInstalled else { return }
    do {
      try session.updateApplicationContext(["snapshot": json])
    } catch {
      NSLog("[WATCH] updateApplicationContext failed: \(error)")
    }
    if session.isReachable {
      session.sendMessage(["snapshot": json], replyHandler: nil, errorHandler: nil)
    }
  }

  private func resendLastSnapshot() {
    if let json = defaults.string(forKey: Self.lastSnapshotKey) { sendSnapshot(json) }
  }

  // MARK: Watch → phone

  private func receive(_ payload: [String: Any]) {
    guard let action = payload["watchAction"] as? [String: Any],
      let id = action["id"] as? String,
      JSONSerialization.isValidJSONObject(action)
    else { return }
    onMain {
      var queue = self.queue()
      if queue.contains(where: { ($0["id"] as? String) == id }) { return }
      queue.append(action)
      if queue.count > Self.maxQueue { queue.removeFirst(queue.count - Self.maxQueue) }
      self.save(queue)
      if self.channel != nil {
        self.beginBackgroundTask()
        self.channel?.invokeMethod("actionsAvailable", arguments: nil)
      }
    }
  }

  private func beginBackgroundTask() {
    guard backgroundTask == .invalid else { return }
    backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "habitt.watchAction") { [weak self] in
      self?.endBackgroundTask()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + Self.backgroundGrace) { [weak self] in
      self?.endBackgroundTask()
    }
  }

  private func endBackgroundTask() {
    guard backgroundTask != .invalid else { return }
    UIApplication.shared.endBackgroundTask(backgroundTask)
    backgroundTask = .invalid
  }

  private func queue() -> [[String: Any]] {
    guard let raw = defaults.string(forKey: Self.queueKey), let data = raw.data(using: .utf8),
      let list = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    else { return [] }
    return list
  }

  private func save(_ queue: [[String: Any]]) {
    if queue.isEmpty {
      defaults.removeObject(forKey: Self.queueKey)
      return
    }
    guard let data = try? JSONSerialization.data(withJSONObject: queue),
      let raw = String(data: data, encoding: .utf8)
    else { return }
    defaults.set(raw, forKey: Self.queueKey)
  }

  private func queueJSON() -> String {
    defaults.string(forKey: Self.queueKey) ?? "[]"
  }

  private func remove(ids: Set<String>) {
    guard !ids.isEmpty else { return }
    save(queue().filter { !ids.contains(($0["id"] as? String) ?? "") })
  }

  private func onMain(_ work: @escaping () -> Void) {
    if Thread.isMainThread { work() } else { DispatchQueue.main.async(execute: work) }
  }

  // MARK: WCSessionDelegate

  func session(
    _ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?
  ) {
    if activationState == .activated { onMain { self.resendLastSnapshot() } }
  }

  func sessionDidBecomeInactive(_ session: WCSession) {}

  func sessionDidDeactivate(_ session: WCSession) {
    // switching to another paired watch: reactivate for the new one
    session.activate()
  }

  func sessionWatchStateDidChange(_ session: WCSession) {
    // e.g. the watch app was just installed: give it the latest snapshot
    onMain { self.resendLastSnapshot() }
  }

  func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    receive(message)
  }

  func session(
    _ session: WCSession, didReceiveMessage message: [String: Any],
    replyHandler: @escaping ([String: Any]) -> Void
  ) {
    receive(message)
    replyHandler(["queued": true])
  }

  func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
    receive(userInfo)
  }
}
