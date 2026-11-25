import SwiftUI

/// Habitt on Apple Watch: today's habits from the iPhone app, to complete,
/// un-complete or log. See docs/watch_app.md.
@main
struct HabittWatchApp: App {
  @StateObject private var store = WatchStore()

  var body: some Scene {
    WindowGroup {
      RootView()
        .environmentObject(store)
        .preferredColorScheme(.dark)
    }
  }
}
