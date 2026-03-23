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

    @MainActor
    static func earnedBadges(for vehicles: [Vehicle]) -> [MilestoneBadge] {
        var badges: [MilestoneBadge] = []
        let totalServices = vehicles.reduce(0) { $0 + $1.serviceRecords.count }
        let totalFuelLogs = vehicles.reduce(0) { $0 + $1.fuelLogs.count }

        // Service milestones
        badges.append(MilestoneBadge(
            id: "svc_1",
            title: "First Service",
            icon: "wrench.fill",
            color: .catEngine,
            detail: "Logged your first service",
            isEarned: totalServices >= 1
        ))

        badges.append(MilestoneBadge(
            id: "svc_10",
            title: "Dedicated",
            icon: "star.fill",
            color: .wrenchAmber,
            detail: "10 services logged",
            isEarned: totalServices >= 10
        ))

        badges.append(MilestoneBadge(
            id: "svc_25",
            title: "Diligent",
            icon: "medal.fill",
            color: .catTires,
            detail: "25 services logged",
            isEarned: totalServices >= 25
        ))

        badges.append(MilestoneBadge(
            id: "svc_50",
            title: "Mechanic",
            icon: "trophy.fill",
            color: .wrenchAmberLight,
            detail: "50 services logged",
            isEarned: totalServices >= 50
        ))

        // Fuel milestones
        badges.append(MilestoneBadge(
            id: "fuel_1",
            title: "First Fill-Up",
            icon: "fuelpump.fill",
            color: .catFuel,
            detail: "Logged your first fuel",
            isEarned: totalFuelLogs >= 1
        ))

        badges.append(MilestoneBadge(
            id: "fuel_20",
            title: "Road Warrior",
            icon: "car.side.fill",
            color: .catFuelPremium,
            detail: "20 fill-ups tracked",
            isEarned: totalFuelLogs >= 20
        ))

        // Multi-vehicle
        if vehicles.count >= 2 {
            badges.append(MilestoneBadge(
                id: "multi_vehicle",
                title: "Fleet Owner",
                icon: "car.2.fill",
                color: .catElectrical,
                detail: "Managing \(vehicles.count) vehicles",
                isEarned: true
            ))
        }

        // Only return earned badges
        return badges.filter { $0.isEarned }
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
