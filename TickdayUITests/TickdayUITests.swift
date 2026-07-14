import XCTest

@MainActor
final class TickdayUITests: XCTestCase {
    func testNavigateMainSections() {
        let app = launchApp()
        for title in ["Today", "Countdowns", "Tasks", "Settings"] {
            XCTAssertTrue(app.staticTexts[title].firstMatch.waitForExistence(timeout: 3))
            app.staticTexts[title].firstMatch.click()
        }
    }

    func testOpenCountdownEditor() {
        let app = launchApp()
        app.staticTexts["Countdowns"].firstMatch.click()
        app.buttons["New Countdown"].click()
        XCTAssertTrue(app.textFields["countdown.title"].waitForExistence(timeout: 2))
    }

    func testOpenTaskEditorAndNavigateDates() {
        let app = launchApp()
        app.staticTexts["Tasks"].firstMatch.click()
        app.buttons["Next day"].click()
        app.buttons["Today"].click()
        app.buttons["New Task"].click()
        XCTAssertTrue(app.textFields["task.title"].waitForExistence(timeout: 2))
    }

    func testDeepLinkRoutesToTasks() {
        let app = launchApp()
        app.open(URL(string: "tickday://tasks")!)
        XCTAssertTrue(app.navigationBars["Tasks"].waitForExistence(timeout: 3))
    }

    private func launchApp() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        return app
    }
}
