import SwiftUI

/// Tracks user actions to trigger soft paywall at the right moment.
/// Rule: Show soft paywall after the 3rd completed action (service log, fuel log, vehicle add).
/// Only shows once per session. Resets on app relaunch.
@Observable @MainActor
final class SoftPaywallTracker {
    static let shared = SoftPaywallTracker()

    /// Number of completed actions in current session
    private(set) var sessionActionCount: Int = 0

    /// Whether soft paywall has been shown this session
    private(set) var hasShownThisSession = false

    /// Total lifetime actions (persisted)
    var lifetimeActionCount: Int {
        get { UserDefaults.standard.integer(forKey: "wl_lifetime_actions") }
        set { UserDefaults.standard.set(newValue, forKey: "wl_lifetime_actions") }
    }

    /// Whether the user dismissed the paywall before (persisted — shows less aggressively)
    var hasDismissedBefore: Bool {
        get { UserDefaults.standard.bool(forKey: "wl_paywall_dismissed") }
        set { UserDefaults.standard.set(newValue, forKey: "wl_paywall_dismissed") }
    }

    private init() {}

    /// Call after each completed action (save service, save fuel, add vehicle)
    func recordAction() {
        sessionActionCount += 1
        lifetimeActionCount += 1
    }

    /// Whether it's time to show the soft paywall
    var shouldShowPaywall: Bool {
        guard !StoreManager.shared.isPro else { return false }
        guard !hasShownThisSession else { return false }

        // First time: after 3rd action
        // Returning user who dismissed: after 5th action
        let threshold = hasDismissedBefore ? 5 : 3
        return sessionActionCount >= threshold
    }

    /// Mark that the paywall was shown
    func markShown() {
        hasShownThisSession = true
    }

    /// Mark that the user dismissed (not purchased)
    func markDismissed() {
        hasShownThisSession = true
        hasDismissedBefore = true
    }
}
