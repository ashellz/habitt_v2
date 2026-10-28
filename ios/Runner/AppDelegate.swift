import Flutter
import UIKit
import UserNotifications
#if canImport(AlarmKit)
import AlarmKit
import SwiftUI
#endif
import awesome_notifications
import shared_preferences_foundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // UIScene lifecycle (required when building with the iOS 27 SDK — without
    // it UIKit traps at launch). Plugins register in
    // didInitializeImplicitFlutterEngine below, once FlutterSceneDelegate has
    // created the engine. awesome_notifications >= 0.12.1 (IosAwnCore 0.12.1)
    // claims the UNUserNotificationCenter delegate itself at registration and
    // resolves the initial action on first activation, so taps / action
    // buttons still reach Dart under UIScene.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    // Before any plugin schedules a notification: keep every action-button
    // category registered (see NotificationCategoryMerger).
    NotificationCategoryMerger.install()

    // Register the plugins the awesome_notifications BACKGROUND isolate needs
    // (action handling for the "Complete" button). Register only these — using
    // GeneratedPluginRegistrant here crashes the isolate because heavyweight
    // plugins (Firebase / RevenueCat / google_sign_in) don't support it. The
    // handler needs awesome_notifications (to dispatch) + shared_preferences
    // (the pending-completion queue's storage).
    SwiftAwesomeNotificationsPlugin.setPluginRegistrantCallback { registry in
      if let registrar = registry.registrar(forPlugin: "AwesomeNotificationsPlugin") {
        SwiftAwesomeNotificationsPlugin.register(with: registrar)
      }
      if let registrar = registry.registrar(forPlugin: "SharedPreferencesPlugin") {
        SharedPreferencesPlugin.register(with: registrar)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "HabitAlarmKit") {
      HabitAlarmKitBridge.register(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "HabitNotificationStatus") {
      HabitNotificationStatusBridge.register(messenger: registrar.messenger())
    }
  }

  // awesome_notifications forwards these to its Flutter channel without
  // guaranteeing main-thread dispatch, and UNUserNotificationCenter does not
  // guarantee its delegate callbacks fire on the main thread either (most
  // visible on the iOS Simulator). Force-hop to main before letting
  // FlutterAppDelegate's plugin forwarding run, so the channel call always
  // happens on the platform thread.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if Thread.isMainThread {
      super.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
    } else {
      DispatchQueue.main.async {
        super.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
      }
    }
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if Thread.isMainThread {
      super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    } else {
      DispatchQueue.main.async {
        super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
      }
    }
  }
}

// MARK: - Notification action-button categories
//
// iOS shows a notification's buttons from the category registered under its
// categoryIdentifier when it is displayed. awesome_notifications registers
// each notification's buttons as its own category, but with
// setNotificationCategories([thatOne]), which drops every category registered
// before it. So the last notification scheduled decided the buttons of all
// pending ones: a Health-linked habit (no buttons) or a timer notification
// scheduled last left every reminder without "Complete". This swaps
// setNotificationCategories for one that adds to the categories already
// registered instead of replacing them. A category's identifier encodes its
// buttons (keys and labels), so replacing by identifier never loses buttons.

enum NotificationCategoryMerger {
  private static let lock = NSLock()
  private static var known: [String: UNNotificationCategory] = [:]
  private static var installed = false

  static func install() {
    guard !installed else { return }
    installed = true

    let cls: AnyClass = UNUserNotificationCenter.self
    guard
      let original = class_getInstanceMethod(
        cls, #selector(UNUserNotificationCenter.setNotificationCategories(_:))),
      let merging = class_getInstanceMethod(
        cls, #selector(UNUserNotificationCenter.habitt_setMergedNotificationCategories(_:)))
    else { return }
    method_exchangeImplementations(original, merging)

    // Categories persist across launches; seed them so the first notification
    // scheduled this launch doesn't drop the ones registered last time.
    let center = UNUserNotificationCenter.current()
    center.getNotificationCategories { existing in
      center.setNotificationCategories(existing)
    }
  }

  fileprivate static func merge(
    _ categories: Set<UNNotificationCategory>
  ) -> Set<UNNotificationCategory> {
    lock.lock()
    defer { lock.unlock() }
    for category in categories {
      known[category.identifier] = category
    }
    return Set(known.values)
  }
}

extension UNUserNotificationCenter {
  @objc fileprivate func habitt_setMergedNotificationCategories(
    _ categories: Set<UNNotificationCategory>
  ) {
    // Implementations are exchanged: this calls the original setter.
    habitt_setMergedNotificationCategories(NotificationCategoryMerger.merge(categories))
  }
}

// MARK: - Notification permission status
//
// awesome_notifications can't tell "never asked" from "denied" (both are just
// "not allowed"), and for a denied user its permission request waits forever
// for them to come back from Settings. Dart asks this first so it only
// requests the permission when the system prompt can still be shown.

enum HabitNotificationStatusBridge {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "habitt/notification_status", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "isDenied" else {
        result(FlutterMethodNotImplemented)
        return
      }
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        DispatchQueue.main.async { result(settings.authorizationStatus == .denied) }
      }
    }
  }
}

// MARK: - AlarmKit (iOS 26+) bridge for "alarm" habits
//
// Alarm habits ring through silent mode / Focus until stopped. AlarmKit is
// iOS 26+, so everything is gated; on older iOS (or if the user denies
// permission) Dart falls back to a normal notification. Alarm ids are the same
// integers used for the habit's notifications, mapped to a deterministic UUID
// so cancelling needs no lookup. See docs/habit_alarms.md.

#if canImport(AlarmKit)
@available(iOS 26.0, *)
struct HabitAlarmMetadata: AlarmMetadata {}
#endif

enum HabitAlarmKitBridge {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "habitt/alarmkit", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      #if canImport(AlarmKit)
      if #available(iOS 26.0, *) {
        handle(call, result)
        return
      }
      #endif
      // Not supported on this OS version: report unsupported / no-ops.
      switch call.method {
      case "isAvailable", "requestAuthorization": result(false)
      default: result(nil)
      }
    }
  }

  #if canImport(AlarmKit)
  @available(iOS 26.0, *)
  private static func alarmUUID(_ id: Int) -> UUID {
    UUID(uuidString: String(format: "00000000-0000-0000-0000-%012llx", UInt64(id))) ?? UUID()
  }

  @available(iOS 26.0, *)
  private static func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let manager = AlarmManager.shared
    let args = call.arguments as? [String: Any]
    switch call.method {
    case "isAvailable":
      result(manager.authorizationState == .authorized)
    case "requestAuthorization":
      Task {
        do {
          let state = try await manager.requestAuthorization()
          result(state == .authorized)
        } catch {
          result(false)
        }
      }
    case "schedule":
      guard let id = args?["id"] as? Int,
        let epochMs = args?["epochMs"] as? Int,
        let title = args?["title"] as? String,
        let stopLabel = args?["stopLabel"] as? String
      else {
        result(FlutterError(code: "bad_args", message: "schedule needs id, epochMs, title, stopLabel", details: nil))
        return
      }
      Task {
        do {
          let date = Date(timeIntervalSince1970: Double(epochMs) / 1000)
          let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: title),
            stopButton: AlarmButton(
              text: LocalizedStringResource(stringLiteral: stopLabel),
              textColor: .white,
              systemImageName: "stop.circle"
            )
          )
          let attributes = AlarmAttributes<HabitAlarmMetadata>(
            presentation: AlarmPresentation(alert: alert),
            tintColor: .orange
          )
          let configuration = AlarmManager.AlarmConfiguration<HabitAlarmMetadata>(
            schedule: .fixed(date),
            attributes: attributes
          )
          // Same id may already be scheduled (reschedule-all): replace it.
          try? manager.cancel(id: alarmUUID(id))
          _ = try await manager.schedule(id: alarmUUID(id), configuration: configuration)
          result(true)
        } catch {
          result(false)
        }
      }
    case "cancelAll":
      // Every AlarmKit alarm this app owns is a habit alarm.
      if let alarms = try? manager.alarms {
        for alarm in alarms { try? manager.cancel(id: alarm.id) }
      }
      result(nil)
    case "cancel":
      if let id = args?["id"] as? Int {
        try? manager.cancel(id: alarmUUID(id))
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  #endif
}
