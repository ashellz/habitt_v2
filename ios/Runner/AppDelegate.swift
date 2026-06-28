import Flutter
import UIKit
import UserNotifications
import awesome_notifications
import shared_preferences_foundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Classic (pre-UIScene) registration: plugins register against the app
    // delegate, so awesome_notifications' addApplicationDelegate hooks into
    // FlutterAppDelegate's UNUserNotificationCenter forwarding and notification
    // taps / action buttons reach Dart. (UIScene is opted out in Info.plist via
    // _UIApplicationSceneManifest because awesome_notifications 0.10.1 has no
    // scene-delegate support.)
    GeneratedPluginRegistrant.register(with: self)

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
}
