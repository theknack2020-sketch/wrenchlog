import SwiftUI

// MARK: - Milestone Badge

struct MilestoneBadge: Identifiable {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let detail: String
    let isEarned: Bool
}

// MARK: - Milestone Engine

struct MilestoneEngine {

    // MARK: - All Badges (earned + locked)

    @MainActor
    static func allBadges(for vehicles: [Vehicle]) -> [MilestoneBadge] {
        var badges: [MilestoneBadge] = []
        let totalServices = vehicles.reduce(0) { $0 + $1.safeServiceRecords.count }
        let totalFuelLogs = vehicles.reduce(0) { $0 + $1.safeFuelLogs.count }
        let totalCost = vehicles.flatMap(\.safeServiceRecords).reduce(0.0) { $0 + $1.cost }
            + vehicles.flatMap(\.safeFuelLogs).reduce(0.0) { $0 + $1.totalCost }
        let streak = RetentionEngine.shared.currentStreak
        let longestStreak = RetentionEngine.shared.longestStreak
        let totalOpens = RetentionEngine.shared.totalOpens
        let vehicleCount = vehicles.count

        // MARK: Service Milestones

        badges.append(MilestoneBadge(
            id: "svc_1", title: "First Service", icon: "wrench.fill",
            color: .catEngine, detail: "Logged your first service",
            isEarned: totalServices >= 1
        ))
        badges.append(MilestoneBadge(
            id: "svc_5", title: "Getting Started", icon: "wrench.and.screwdriver.fill",
            color: .catFuelRegular, detail: "5 services logged",
            isEarned: totalServices >= 5
        ))
        badges.append(MilestoneBadge(
            id: "svc_10", title: "Dedicated", icon: "star.fill",
            color: .wrenchAmber, detail: "10 services logged",
            isEarned: totalServices >= 10
        ))
        badges.append(MilestoneBadge(
            id: "svc_25", title: "Diligent", icon: "medal.fill",
            color: .catTires, detail: "25 services logged",
            isEarned: totalServices >= 25
        ))
        badges.append(MilestoneBadge(
            id: "svc_50", title: "Mechanic", icon: "trophy.fill",
            color: .wrenchAmberLight, detail: "50 services logged",
            isEarned: totalServices >= 50
        ))
        badges.append(MilestoneBadge(
            id: "svc_100", title: "Master Mechanic", icon: "crown.fill",
            color: .wrenchAmber, detail: "100 services — legendary",
            isEarned: totalServices >= 100
        ))

        // MARK: Fuel Milestones

        badges.append(MilestoneBadge(
            id: "fuel_1", title: "First Fill-Up", icon: "fuelpump.fill",
            color: .catFuel, detail: "Logged your first fuel",
            isEarned: totalFuelLogs >= 1
        ))
        badges.append(MilestoneBadge(
            id: "fuel_10", title: "Fuel Tracker", icon: "gauge.with.dots.needle.33percent",
            color: .catFuel, detail: "10 fill-ups tracked",
            isEarned: totalFuelLogs >= 10
        ))
        badges.append(MilestoneBadge(
            id: "fuel_20", title: "Road Warrior", icon: "car.side.fill",
            color: .catFuelPremium, detail: "20 fill-ups tracked",
            isEarned: totalFuelLogs >= 20
        ))
        badges.append(MilestoneBadge(
            id: "fuel_50", title: "Highway Legend", icon: "road.lanes",
            color: .catFuelDiesel, detail: "50 fill-ups tracked",
            isEarned: totalFuelLogs >= 50
        ))

        // MARK: Streak Milestones

        badges.append(MilestoneBadge(
            id: "streak_3", title: "Warming Up", icon: "flame.fill",
            color: .orange, detail: "3-day streak achieved",
            isEarned: longestStreak >= 3
        ))
        badges.append(MilestoneBadge(
            id: "streak_7", title: "One Week", icon: "flame.fill",
            color: .orange, detail: "7-day streak — dedicated",
            isEarned: longestStreak >= 7
        ))
        badges.append(MilestoneBadge(
            id: "streak_14", title: "Two Weeks", icon: "flame.circle.fill",
            color: .red, detail: "14-day streak — unstoppable",
            isEarned: longestStreak >= 14
        ))
        badges.append(MilestoneBadge(
            id: "streak_30", title: "Monthly Master", icon: "flame.circle.fill",
            color: .red, detail: "30-day streak — legend",
            isEarned: longestStreak >= 30
        ))

        // MARK: Cost Tracking Milestones

        badges.append(MilestoneBadge(
            id: "cost_100", title: "Cost Tracker", icon: "dollarsign.circle.fill",
            color: .wrenchAmber, detail: "Tracked $100+ in expenses",
            isEarned: totalCost >= 100
        ))
        badges.append(MilestoneBadge(
            id: "cost_500", title: "Budget Conscious", icon: "chart.pie.fill",
            color: .wrenchAmber, detail: "Tracked $500+ in expenses",
            isEarned: totalCost >= 500
        ))
        badges.append(MilestoneBadge(
            id: "cost_1000", title: "Big Spender", icon: "banknote.fill",
            color: .wrenchAmberLight, detail: "Tracked $1,000+ in expenses",
            isEarned: totalCost >= 1000
        ))

        // MARK: Engagement Milestones

        badges.append(MilestoneBadge(
            id: "opens_10", title: "Regular", icon: "app.badge.fill",
            color: .catElectrical, detail: "Opened the app 10 times",
            isEarned: totalOpens >= 10
        ))
        badges.append(MilestoneBadge(
            id: "opens_50", title: "Power User", icon: "bolt.circle.fill",
            color: .catElectrical, detail: "50 app opens — you're hooked",
            isEarned: totalOpens >= 50
        ))
        badges.append(MilestoneBadge(
            id: "opens_100", title: "WrenchLog Loyalist", icon: "heart.circle.fill",
            color: .catEngine, detail: "100 opens — true dedication",
            isEarned: totalOpens >= 100
        ))

        // MARK: Vehicle Milestones

        badges.append(MilestoneBadge(
            id: "vehicle_1", title: "First Ride", icon: "car.fill",
            color: .catFuelMidgrade, detail: "Added your first vehicle",
            isEarned: vehicleCount >= 1
        ))
        if vehicleCount >= 2 {
            badges.append(MilestoneBadge(
                id: "multi_vehicle", title: "Fleet Owner", icon: "car.2.fill",
                color: .catElectrical, detail: "Managing \(vehicleCount) vehicles",
                isEarned: true
            ))
        }
        if vehicleCount >= 5 {
            badges.append(MilestoneBadge(
                id: "vehicle_5", title: "Collector", icon: "building.2.fill",
                color: .catFuelE85, detail: "5 vehicles in your garage",
                isEarned: true
            ))
        }

        // MARK: Special Milestones

        let hasHealthScore100 = vehicles.contains { MaintenanceScoreEngine.score(for: $0) == 100 }
        badges.append(MilestoneBadge(
            id: "perfect_health", title: "Perfect Health", icon: "heart.text.square.fill",
            color: .wrenchGreen, detail: "100% health score on a vehicle",
            isEarned: hasHealthScore100
        ))

        return badges
    }

    /// Convenience: only earned badges (backward compat)
    @MainActor
    static func earnedBadges(for vehicles: [Vehicle]) -> [MilestoneBadge] {
        allBadges(for: vehicles).filter(\.isEarned)
    }

    /// Locked badges (for display in achievements section)
    @MainActor
    static func lockedBadges(for vehicles: [Vehicle]) -> [MilestoneBadge] {
        allBadges(for: vehicles).filter { !$0.isEarned }
    }

    /// Newly earned badge IDs since last check
    @MainActor
    static func checkNewlyEarned(for vehicles: [Vehicle]) -> [MilestoneBadge] {
        let defaults = UserDefaults.standard
        let previouslyEarned = Set(defaults.stringArray(forKey: "wl_earned_badges") ?? [])
        let currentEarned = earnedBadges(for: vehicles)
        let newBadges = currentEarned.filter { !previouslyEarned.contains($0.id) }

        // Persist updated list
        if !newBadges.isEmpty {
            let allEarnedIDs = currentEarned.map(\.id)
            defaults.set(allEarnedIDs, forKey: "wl_earned_badges")
        }

        return newBadges
    }
}

// MARK: - Milestone Badge View

struct MilestoneBadgeView: View {
    let badge: MilestoneBadge

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(badge.color.opacity(0.15))
                    .frame(width: 52, height: 52)

                Image(systemName: badge.icon)
                    .font(.title3)
                    .foregroundStyle(badge.color)
            }

            Text(badge.title)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)

            Text(badge.detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 90)
    }
}
