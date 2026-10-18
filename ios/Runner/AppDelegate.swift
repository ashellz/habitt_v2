import Flutter
import UIKit
import UserNotifications
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
