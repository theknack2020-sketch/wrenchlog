import Foundation
import UserNotifications

/// Tracks user engagement streaks and triggers retention notifications.
/// Streak = consecutive days with at least one meaningful action (log service, fuel, update mileage, open app).
@Observable @MainActor
final class RetentionEngine {
    static let shared = RetentionEngine()

    private let defaults = UserDefaults.standard
    private let calendar = Calendar.current

    // MARK: - Streak

    /// Current consecutive-day streak
    var currentStreak: Int {
        defaults.integer(forKey: "wl_streak")
    }

    /// Longest ever streak
    var longestStreak: Int {
        defaults.integer(forKey: "wl_longest_streak")
    }

    /// Last date the user was active
    var lastActiveDate: Date? {
        defaults.object(forKey: "wl_last_active") as? Date
    }

    /// Total lifetime opens
    var totalOpens: Int {
        get { defaults.integer(forKey: "wl_total_opens") }
        set { defaults.set(newValue, forKey: "wl_total_opens") }
    }

    /// Day of onboarding journey (1-3, then 0 = done)
    var journeyDay: Int {
        let installDate = defaults.object(forKey: "wl_install_date") as? Date ?? Date()
        let daysSinceInstall = calendar.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        if daysSinceInstall < 3 { return daysSinceInstall + 1 }
        return 0
    }

    private init() {
        // Record install date on first launch
        if defaults.object(forKey: "wl_install_date") == nil {
            defaults.set(Date(), forKey: "wl_install_date")
        }
    }

    // MARK: - Record Activity

    /// Call on every app foreground / meaningful action
    func recordActivity() {
        let today = calendar.startOfDay(for: Date())

        if let last = lastActiveDate {
            let lastDay = calendar.startOfDay(for: last)

            if lastDay == today {
                // Already active today — no streak change
                return
            }

            let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysBetween == 1 {
                // Consecutive day — increment streak
                let newStreak = currentStreak + 1
                defaults.set(newStreak, forKey: "wl_streak")
                if newStreak > longestStreak {
                    defaults.set(newStreak, forKey: "wl_longest_streak")
                }
            } else if daysBetween == 2 && canUseGrace() {
                // 1 missed day — apply grace period (streak preserved, not incremented)
                defaults.set(Date(), forKey: "wl_grace_used_date")
            } else {
                // Streak broken — reset to 1
                defaults.set(1, forKey: "wl_streak")
            }
        } else {
            // First ever activity
            defaults.set(1, forKey: "wl_streak")
        }

        defaults.set(today, forKey: "wl_last_active")
        totalOpens += 1
    }

    /// Whether the streak was maintained today
    var isActiveToday: Bool {
        guard let last = lastActiveDate else { return false }
        return calendar.isDateInToday(last)
    }

    // MARK: - Grace Period

    /// Whether a streak grace (freeze) is available — max 1 per 7 days
    private func canUseGrace() -> Bool {
        guard let lastGrace = defaults.object(forKey: "wl_grace_used_date") as? Date else {
            return true // never used
        }
        let daysSinceGrace = calendar.dateComponents([.day], from: lastGrace, to: Date()).day ?? 0
        return daysSinceGrace >= 7
    }

    // MARK: - Daily Tips

    private static let tips: [String] = [
        "💡 Regular oil changes extend engine life by up to 50%",
        "🔧 Rotating tires every 5,000-8,000 miles ensures even wear",
        "🌡️ Check coolant levels before long trips — overheating is the #1 roadside issue",
        "🛞 Proper tire pressure improves fuel efficiency by up to 3%",
        "⚡ Car batteries typically last 3-5 years — test yours annually",
        "🧊 Winter: check antifreeze concentration before temperatures drop",
        "☀️ Summer: AC systems lose ~5% refrigerant per year — service annually",
        "🔍 Check brake pads every 12,000 miles — thin pads damage rotors",
        "💧 Replace wiper blades every 6-12 months for best visibility",
        "🎯 Following your maintenance schedule can increase resale value by 10-15%",
        "🚗 Air filters affect both performance and fuel economy — replace every 15-30K miles",
        "⛽ Track fuel efficiency to catch engine problems early — sudden drops signal issues",
        "🔋 Clean battery terminals prevent starting problems — use baking soda + water",
        "🏎️ Synthetic oil lasts longer but costs more — check your manual for the right choice",
        "📋 Keep all service receipts — they significantly boost resale value",
        "🔦 Check all lights monthly — a burned-out turn signal is a common ticket",
        "🧲 Transmission fluid should be changed every 30,000-60,000 miles",
        "🛡️ Rust prevention: wash the undercarriage after driving on salted roads",
        "⏱️ Timing belts typically need replacement at 60,000-100,000 miles",
        "🌊 Power steering fluid is often overlooked — check every oil change",
        "🔩 Loose gas caps trigger check-engine lights — always click until tight",
    ]

    /// Get today's tip (deterministic per day)
    var dailyTip: String {
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = dayOfYear % Self.tips.count
        return Self.tips[index]
    }

    // MARK: - Journey Messages (Day 1-3)

    var journeyMessage: String? {
        switch journeyDay {
        case 1: return "Welcome! Tap + to add a vehicle or explore your garage 🚗"
        case 2: return "Day 2: Try logging a service or fuel fill-up 🔧"
        case 3: return "Day 3: Check your maintenance health score ❤️"
        default: return nil
        }
    }

    // MARK: - Streak Messages

    var streakMessage: String? {
        guard currentStreak > 1 else { return nil }
        switch currentStreak {
        case 2: return "2-day streak! You're building a habit 🔥"
        case 3: return "3 days in a row! Your vehicles thank you 🏆"
        case 5: return "5-day streak! Maintenance pro 💪"
        case 7: return "One week streak! Incredible dedication 🌟"
        case 14: return "2-week streak! You're unstoppable 🚀"
        case 30: return "30-day streak! Legend status 👑"
        default:
            if currentStreak >= 7 && currentStreak % 7 == 0 {
                return "\(currentStreak)-day streak! Keep it going 🔥"
            }
            return nil
        }
    }

    // MARK: - Journey Push Notifications (Day 1-3)

    /// Schedule onboarding journey push notifications for days 1-3 post-install.
    /// Only schedules once — guarded by `wl_journey_notifs_scheduled`.
    func scheduleJourneyNotifications() async {
        guard !defaults.bool(forKey: "wl_journey_notifs_scheduled") else { return }

        guard let installDate = defaults.object(forKey: "wl_install_date") as? Date else { return }

        let center = UNUserNotificationCenter.current()
        let now = Date()

        let journeyItems: [(id: String, delay: TimeInterval, title: String, body: String)] = [
            ("journey-day1", 24 * 60 * 60, "🚗 Welcome to WrenchLog!",
             "Add your first vehicle to start tracking maintenance."),
            ("journey-day2", 48 * 60 * 60, "🔧 Day 2: Log Your First Service",
             "Track an oil change, tire rotation, or any maintenance you've done."),
            ("journey-day3", 72 * 60 * 60, "❤️ Day 3: Check Your Health Score",
             "See how well-maintained your vehicle is. Open your garage to check."),
        ]

        for item in journeyItems {
            let fireDate = installDate.addingTimeInterval(item.delay)
            let interval = fireDate.timeIntervalSince(now)

            // Skip if the fire date is already in the past
            guard interval > 0 else { continue }

            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = item.body
            content.sound = .default
            content.threadIdentifier = "journey"

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            try? await center.add(UNNotificationRequest(
                identifier: item.id,
                content: content,
                trigger: trigger
            ))
        }

        defaults.set(true, forKey: "wl_journey_notifs_scheduled")
    }

    // MARK: - Retention Notifications

    /// Schedule all retention notifications (call after reminders are scheduled)
    func scheduleRetentionNotifications() async {
        let center = UNUserNotificationCenter.current()

        // 0. Onboarding journey notifications (Day 1-3)
        await scheduleJourneyNotifications()

        // 1. Daily streak reminder (if user has 2+ day streak)
        if currentStreak >= 2 {
            let content = UNMutableNotificationContent()
            content.title = "🔥 \(currentStreak)-day streak"
            content.body = "Don't break your streak! Open WrenchLog to keep it going."
            content.sound = .default
            content.threadIdentifier = "retention"

            // Tomorrow at 10am
            var components = DateComponents()
            components.hour = 10
            components.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            try? await center.add(UNNotificationRequest(
                identifier: "retention-streak",
                content: content,
                trigger: trigger
            ))
        }

        // 2. Weekly summary (Sunday 6pm)
        let weeklySummary = UNMutableNotificationContent()
        weeklySummary.title = "📊 Your Weekly Summary"
        weeklySummary.body = "See how your vehicles performed this week. Tap to check your garage."
        weeklySummary.sound = .default
        weeklySummary.threadIdentifier = "retention"

        var sundayComponents = DateComponents()
        sundayComponents.weekday = 1 // Sunday
        sundayComponents.hour = 18
        sundayComponents.minute = 0
        let sundayTrigger = UNCalendarNotificationTrigger(dateMatching: sundayComponents, repeats: true)
        try? await center.add(UNNotificationRequest(
            identifier: "retention-weekly",
            content: weeklySummary,
            trigger: sundayTrigger
        ))

        // 3. Inactivity nudge (3 days without opening)
        let inactivityContent = UNMutableNotificationContent()
        inactivityContent.title = "🚗 Your vehicles miss you"
        inactivityContent.body = "It's been a few days. Check if any services are due."
        inactivityContent.sound = .default
        inactivityContent.threadIdentifier = "retention"

        let inactivityTrigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 3 * 24 * 60 * 60, // 3 days
            repeats: false
        )
        try? await center.add(UNNotificationRequest(
            identifier: "retention-inactivity",
            content: inactivityContent,
            trigger: inactivityTrigger
        ))
    }

    /// Cancel and reschedule inactivity nudge (call on every app open)
    func resetInactivityTimer() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["retention-inactivity"])

        let content = UNMutableNotificationContent()
        content.title = "🚗 Your vehicles miss you"
        content.body = "It's been a few days. Any new services to log?"
        content.sound = .default
        content.threadIdentifier = "retention"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 3 * 24 * 60 * 60,
            repeats: false
        )
        try? await center.add(UNNotificationRequest(
            identifier: "retention-inactivity",
            content: content,
            trigger: trigger
        ))
    }
}
