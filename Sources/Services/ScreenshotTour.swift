#if DEBUG
    import Foundation

    /// Store-shots pipeline contract: routes the app to an exact screen via
    /// launch arguments so marketing screenshots can be captured without UI
    /// automation. ⚠️ DEBUG-ONLY — never included in Release builds.
    ///
    /// Launch args:
    ///  - `-uiState <key>` — one of ``State``'s raw values.
    ///  - `-demoData` — seeds deterministic demo content (alias of the legacy
    ///    `-wl_seed_screenshots`, both remain supported for UITests).
    ///  - `-heroIndex <N>` — which vehicle a vehicle-scoped panel shows, so no
    ///    two panels ever show the same hero content.
    enum ScreenshotTour {
        enum State: String, Identifiable, Hashable {
            case garage
            case vehicleDetail = "vehicle-detail"
            /// Vehicle detail auto-scrolled to the NHTSA recalls section.
            case recalls
            case addService = "add-service"
            case addFuel = "add-fuel"
            case fuelChart = "fuel-chart"
            case costAnalytics = "cost-analytics"
            case insights
            case timeline
            case settings
            case paywall

            var id: String { rawValue }
        }

        static var state: State? {
            let args = ProcessInfo.processInfo.arguments
            guard let i = args.firstIndex(of: "-uiState"), args.indices.contains(i + 1)
            else { return nil }
            return State(rawValue: args[i + 1])
        }

        static var wantsDemoData: Bool {
            let args = ProcessInfo.processInfo.arguments
            return args.contains("-demoData") || args.contains("-wl_seed_screenshots")
        }

        static var heroIndex: Int {
            let args = ProcessInfo.processInfo.arguments
            guard let i = args.firstIndex(of: "-heroIndex"), args.indices.contains(i + 1)
            else { return 0 }
            return Int(args[i + 1]) ?? 0
        }
    }
#endif
