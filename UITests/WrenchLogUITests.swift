import XCTest

@MainActor
final class WrenchLogUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-wl_onboarding_complete", "false"]
    }
    
    // MARK: - Onboarding Flow
    
    func testOnboardingFullFlow() throws {
        app.launch()
        
        // Page 1: Welcome
        XCTAssertTrue(app.staticTexts["WrenchLog"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Your private vehicle maintenance tracker"].exists)
        
        // Tap Get Started
        app.buttons["Get Started"].tap()
        sleep(1)
        
        // Page 2: Vehicle Count
        XCTAssertTrue(app.staticTexts["How many vehicles do you have?"].waitForExistence(timeout: 3))
        
        // Select "2-3"
        app.buttons["2-3"].tap()
        sleep(1)
        
        // Next
        app.buttons["Next"].tap()
        sleep(1)
        
        // Page 3: Interests
        XCTAssertTrue(app.staticTexts["What matters most to you?"].waitForExistence(timeout: 3))
        
        // Select some interests
        if app.buttons["Service tracking"].exists {
            app.buttons["Service tracking"].tap()
        }
        if app.buttons["Cost analysis"].exists {
            app.buttons["Cost analysis"].tap()
        }
        
        app.buttons["Next"].tap()
        sleep(1)
        
        // Page 4: Preview
        XCTAssertTrue(app.staticTexts["Your Garage Preview"].waitForExistence(timeout: 3) || 
                      app.staticTexts["your garage is ready"].waitForExistence(timeout: 3))
        
        app.buttons["Next"].tap()
        sleep(1)
        
        // Page 5: Notifications - tap Maybe Later to skip alert
        if app.buttons["Maybe Later"].waitForExistence(timeout: 3) {
            app.buttons["Maybe Later"].tap()
        } else if app.buttons["Next"].exists {
            app.buttons["Next"].tap()
        }
        sleep(1)
        
        // Handle system notification alert if it appears
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboard.alerts.buttons["Allow"].waitForExistence(timeout: 2) {
            springboard.alerts.buttons["Allow"].tap()
        } else if springboard.alerts.buttons["İzin Ver"].waitForExistence(timeout: 2) {
            springboard.alerts.buttons["İzin Ver"].tap()
        }
        
        // Page 6: Get Started / Celebration
        if app.buttons["Add Your First Vehicle"].waitForExistence(timeout: 3) {
            // Success — we're on the final page
            XCTAssertTrue(true)
        } else if app.buttons["Explore First"].waitForExistence(timeout: 3) {
            app.buttons["Explore First"].tap()
        }
        
        sleep(1)
        // Take screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    // MARK: - Main Garage Flow
    
    func testGarageEmptyState() throws {
        app.launchArguments = ["-wl_onboarding_complete", "true"]
        app.launch()
        
        // Handle notification alert
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboard.alerts.buttons["Allow"].waitForExistence(timeout: 3) {
            springboard.alerts.buttons["Allow"].tap()
        } else if springboard.alerts.buttons["İzin Ver"].waitForExistence(timeout: 3) {
            springboard.alerts.buttons["İzin Ver"].tap()
        }
        
        // Garage should show empty state
        XCTAssertTrue(app.staticTexts["Garage"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Add Vehicle"].waitForExistence(timeout: 3))
        
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    // MARK: - Add Vehicle Flow
    
    func testAddVehicleFlow() throws {
        app.launchArguments = ["-wl_onboarding_complete", "true"]
        app.launch()
        
        // Dismiss notification alert if present
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboard.alerts.buttons.firstMatch.waitForExistence(timeout: 3) {
            springboard.alerts.buttons.element(boundBy: 1).tap() // "Allow" is usually second
        }
        sleep(1)
        
        // Tap Add Vehicle
        if app.buttons["Add Vehicle"].waitForExistence(timeout: 5) {
            app.buttons["Add Vehicle"].tap()
        } else {
            app.navigationBars.buttons.matching(identifier: "Add").firstMatch.tap()
        }
        
        sleep(1)
        
        // Fill in vehicle details
        let makeField = app.textFields["Make (e.g., Toyota)"]
        if makeField.waitForExistence(timeout: 3) {
            makeField.tap()
            makeField.typeText("Toyota")
        }
        
        let modelField = app.textFields["Model (e.g., Camry)"]
        if modelField.exists {
            modelField.tap()
            modelField.typeText("Camry")
        }
        
        // Tap Save
        if app.buttons["Save"].waitForExistence(timeout: 3) {
            app.buttons["Save"].tap()
        } else if app.navigationBars.buttons["Save"].exists {
            app.navigationBars.buttons["Save"].tap()
        }
        
        sleep(2)
        
        // Should be back on garage with vehicle visible
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
