import Foundation
import Combine

/// Global observer for Flutter navigation transitions
/// When Flutter notifies that a transition is in progress, glass effects should be temporarily disabled
@available(iOS 13.0, *)
public class CNTransitionObserver: ObservableObject {
    public static let shared = CNTransitionObserver()

    /// Published property that views can observe
    @Published public var isTransitioning: Bool = false

    /// Notification name for transition state changes
    public static let transitionStateChangedNotification = Notification.Name("CNTransitionStateChanged")

    private init() {}

    /// Call this when Flutter navigation transition starts
    public func beginTransition() {
        DispatchQueue.main.async {
            self.isTransitioning = true
            NotificationCenter.default.post(name: Self.transitionStateChangedNotification, object: nil, userInfo: ["isTransitioning": true])
        }
    }

    /// Call this when Flutter navigation transition ends
    public func endTransition() {
        DispatchQueue.main.async {
            self.isTransitioning = false
            NotificationCenter.default.post(name: Self.transitionStateChangedNotification, object: nil, userInfo: ["isTransitioning": false])
        }
    }
}
