import Foundation
import Testing
@testable import WrenchLog

/// Pins the ethics contract of the App Store review ask. The single most
/// important review rule is *never interrupt, never nag* — so the ask must clear
/// three gates before it can fire: real investment (positive actions), genuine
/// tenure (sessions), and a courtesy cooldown since the last ask. That gate lives
/// in ``ReviewPromptManager/shouldRequestReview(positiveActionCount:sessionCount:lastRequest:now:calendar:)``,
/// extracted so it is testable without `AppStore.requestReview` or a live
/// UIWindowScene. A refactor that loosened any gate would turn a courtesy into
/// a nag; this suite blocks that.
struct ReviewPromptTests {
    private static let epoch = Date(timeIntervalSince1970: 1_700_000_000)
    private static let day: TimeInterval = 86400

    /// A UTC calendar so day-elapsed math is timezone-independent.
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    // MARK: - Investment gate

    @Test func doesNotAskBeforeEnoughPositiveActions() {
        // Two positive actions, plenty of sessions, never asked → still silent.
        #expect(
            ReviewPromptManager.shouldRequestReview(
                positiveActionCount: 2, sessionCount: 10, lastRequest: nil,
                now: Self.epoch, calendar: calendar
            ) == false
        )
    }

    // MARK: - Tenure gate

    @Test func doesNotAskBeforeEnoughSessions() {
        // Enough positive actions, but only the second session → never on early runs.
        #expect(
            ReviewPromptManager.shouldRequestReview(
                positiveActionCount: 10, sessionCount: 2, lastRequest: nil,
                now: Self.epoch, calendar: calendar
            ) == false
        )
    }

    // MARK: - Happy path

    @Test func asksOnceBothThresholdsAreMetAndNeverAskedBefore() {
        #expect(
            ReviewPromptManager.shouldRequestReview(
                positiveActionCount: 3, sessionCount: 3, lastRequest: nil,
                now: Self.epoch, calendar: calendar
            )
        )
    }

    // MARK: - Cooldown gate

    @Test func doesNotAskInsideCooldownWindow() {
        // Asked 30 days ago — well inside the 120-day courtesy floor.
        let last = Self.epoch.addingTimeInterval(-30 * Self.day)
        #expect(
            ReviewPromptManager.shouldRequestReview(
                positiveActionCount: 50, sessionCount: 50, lastRequest: last,
                now: Self.epoch, calendar: calendar
            ) == false
        )
    }

    @Test func asksAgainAfterCooldownElapses() {
        // Asked 121 days ago — past the courtesy floor, ask is allowed again.
        let last = Self.epoch.addingTimeInterval(-121 * Self.day)
        #expect(
            ReviewPromptManager.shouldRequestReview(
                positiveActionCount: 50, sessionCount: 50, lastRequest: last,
                now: Self.epoch, calendar: calendar
            )
        )
    }
}
