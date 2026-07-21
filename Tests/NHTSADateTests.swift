import Foundation
import Testing
@testable import WrenchLog

/// Pins the NHTSA `ReportReceivedDate` format assumption. The live
/// `recallsByVehicle` API returns day-first strings ("25/03/2021"); a
/// well-meaning "fix" flipping the parser to US month-first ordering would
/// silently mis-sort every recall list. This suite makes that regression loud.
struct NHTSADateTests {
    @Test func parsesDayFirstDate() {
        let date = NHTSAService.parseNHTSADate("25/03/2021")
        // DateFormatter parses in the current timezone; compare components in
        // the same timezone to stay environment-independent.
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        #expect(comps.year == 2021)
        #expect(comps.month == 3)
        #expect(comps.day == 25)
    }

    @Test func pinsDayFirstOrderingOnAmbiguousDate() {
        // "03/04/2021" must read as 3 April, never March 4.
        let date = NHTSAService.parseNHTSADate("03/04/2021")
        let comps = Calendar.current.dateComponents([.month, .day], from: date)
        #expect(comps.month == 4)
        #expect(comps.day == 3)
    }

    @Test func garbageFallsBackToDistantPast() {
        #expect(NHTSAService.parseNHTSADate("") == .distantPast)
        #expect(NHTSAService.parseNHTSADate("not-a-date") == .distantPast)
        #expect(NHTSAService.parseNHTSADate("2021-03-25") == .distantPast)
    }
}
