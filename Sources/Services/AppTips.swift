import SwiftUI
import TipKit

struct AddFirstVehicleTip: Tip {
    var title: Text {
        Text("Add Your First Vehicle")
    }

    var message: Text? {
        Text("Tap + to add a vehicle and start tracking maintenance.")
    }

    var image: Image? {
        Image(systemName: "car.fill")
    }
}

struct LogServiceTip: Tip {
    @Parameter
    static var vehicleAdded: Bool = false

    var title: Text {
        Text("Log a Service")
    }

    var message: Text? {
        Text("Record oil changes, tire rotations, and more to track your maintenance history.")
    }

    var image: Image? {
        Image(systemName: "wrench.fill")
    }

    var rules: [Rule] {
        #Rule(Self.$vehicleAdded) { $0 == true }
    }
}

struct FuelTrackingTip: Tip {
    @Parameter
    static var servicesLogged: Int = 0

    var title: Text {
        Text("Track Fuel Efficiency")
    }

    var message: Text? {
        Text("Log fill-ups to see your fuel economy trends over time.")
    }

    var image: Image? {
        Image(systemName: "fuelpump.fill")
    }

    var rules: [Rule] {
        #Rule(Self.$servicesLogged) { $0 >= 2 }
    }
}

struct ChecklistTip: Tip {
    var title: Text {
        Text("Maintenance Checklist")
    }

    var message: Text? {
        Text("Use checklists to track quick maintenance tasks between services.")
    }

    var image: Image? {
        Image(systemName: "checklist")
    }
}
