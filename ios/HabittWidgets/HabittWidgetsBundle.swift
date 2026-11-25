import SwiftUI
import WidgetKit

// The read-only home screen widgets (docs/home_widgets.md). Their kinds must
// match HomeWidgetKinds.ios on the Dart side, which reloads them whenever the
// snapshot changes.

@main
struct HabittWidgetsBundle: WidgetBundle {
  var body: some Widget {
    StreakWidget()
    StreakWeekWidget()
    TodayRingWidget()
    UpNextWidget()
  }
}
