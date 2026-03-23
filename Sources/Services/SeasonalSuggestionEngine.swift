import SwiftUI

// MARK: - Seasonal Suggestion

struct SeasonalSuggestion: Identifiable {
    let id: String
    let title: String
    let detail: String
    let icon: String
    let color: Color
    let season: Season
}

enum Season: String {
    case winter, spring, summer, fall
}

// MARK: - Seasonal Suggestion Engine

struct SeasonalSuggestionEngine {

    @MainActor
    static func suggestions(for vehicles: [Vehicle]) -> [SeasonalSuggestion] {
        guard !vehicles.isEmpty else { return [] }

        let month = Calendar.current.component(.month, from: Date())
        let currentSeason = seasonFor(month: month)
        var suggestions: [SeasonalSuggestion] = []

        switch currentSeason {
        case .winter:
            suggestions.append(SeasonalSuggestion(
                id: "winter_tires",
                title: "Winter Tire Check",
                detail: "Ensure tires have adequate tread depth for cold weather. Consider winter tires.",
                icon: "snowflake",
                color: .catEngine,
                season: .winter
            ))
            suggestions.append(SeasonalSuggestion(
                id: "winter_battery",
                title: "Battery Health",
                detail: "Cold weather strains batteries. Test yours before temperatures drop further.",
                icon: "battery.75percent",
                color: .catElectrical,
                season: .winter
            ))
            suggestions.append(SeasonalSuggestion(
                id: "winter_coolant",
                title: "Antifreeze Level",
                detail: "Check coolant mixture is rated for your area's lowest temperatures.",
                icon: "thermometer.snowflake",
                color: .catEngine,
                season: .winter
            ))

        case .spring:
            suggestions.append(SeasonalSuggestion(
                id: "spring_wipers",
                title: "Replace Wiper Blades",
                detail: "Winter wear degrades wipers. Spring rain demands clear visibility.",
                icon: "windshield.front.and.wiper",
                color: .catInspection,
                season: .spring
            ))
            suggestions.append(SeasonalSuggestion(
                id: "spring_alignment",
                title: "Wheel Alignment",
                detail: "Potholes from winter may have shifted alignment. Check for uneven tire wear.",
                icon: "arrow.left.arrow.right",
                color: .catTires,
                season: .spring
            ))
            suggestions.append(SeasonalSuggestion(
                id: "spring_ac",
                title: "A/C System Check",
                detail: "Test your air conditioning before summer heat arrives.",
                icon: "snowflake",
                color: .catInspection,
                season: .spring
            ))

        case .summer:
            suggestions.append(SeasonalSuggestion(
                id: "summer_coolant",
                title: "Coolant System",
                detail: "High heat strains cooling systems. Check coolant levels and hoses.",
                icon: "thermometer.sun.fill",
                color: .wrenchRed,
                season: .summer
            ))
            suggestions.append(SeasonalSuggestion(
                id: "summer_tires",
                title: "Tire Pressure",
                detail: "Heat increases tire pressure. Check and adjust to manufacturer specs.",
                icon: "tire.fill",
                color: .catTires,
                season: .summer
            ))
            suggestions.append(SeasonalSuggestion(
                id: "summer_oil",
                title: "Oil Viscosity",
                detail: "Hot conditions may benefit from the correct viscosity oil grade.",
                icon: "drop.fill",
                color: .catEngine,
                season: .summer
            ))

        case .fall:
            suggestions.append(SeasonalSuggestion(
                id: "fall_brakes",
                title: "Brake Inspection",
                detail: "Ensure brakes are ready for wet fall roads and upcoming winter.",
                icon: "exclamationmark.octagon.fill",
                color: .catTires,
                season: .fall
            ))
            suggestions.append(SeasonalSuggestion(
                id: "fall_lights",
                title: "Check All Lights",
                detail: "Shorter days mean more driving in darkness. Verify all lights work.",
                icon: "headlight.high.beam.fill",
                color: .catElectrical,
                season: .fall
            ))
            suggestions.append(SeasonalSuggestion(
                id: "fall_heater",
                title: "Heater & Defroster",
                detail: "Test heating system before cold weather arrives.",
                icon: "fan.fill",
                color: .catInspection,
                season: .fall
            ))
        }

        // Return top 2 most relevant
        return Array(suggestions.prefix(2))
    }

    private static func seasonFor(month: Int) -> Season {
        switch month {
        case 12, 1, 2: .winter
        case 3, 4, 5: .spring
        case 6, 7, 8: .summer
        case 9, 10, 11: .fall
        default: .spring
        }
    }
}
