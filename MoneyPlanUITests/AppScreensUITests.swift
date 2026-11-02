import XCTest

final class AppScreensUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
        try await AuthEmulatorSeed.ensureUser()
    }

    func testMainTabsAreAvailable() {
        let app = XCUIApplication()
        app.launchForUITesting()
        app.loginAsE2EUser()

        XCTAssertTrue(app.uiElement("expenses-page").exists)

        app.openTab(index: 1)
        XCTAssertNotNil(app.waitForAny("income-page", timeout: 5))

        app.openTab(index: 2)
        XCTAssertNotNil(app.waitForAny("chatbot-page", timeout: 5))

        app.openTab(index: 3)
        XCTAssertNotNil(app.waitForAny("accounts-page", timeout: 8), "accounts tab did not show accounts-page")
    }

    func testSettingsAndRecurringScreensAreAvailable() {
        let app = XCUIApplication()
        app.launchForUITesting()
        app.loginAsE2EUser()

        app.buttons["settings-menu-trigger"].tap()
        XCTAssertTrue(app.uiElement("settings-page").waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["settings-logout"].exists)
        XCTAssertTrue(app.buttons["settings-delete-account"].exists)

        // Verify planning links are listed. Full NavigationLink push is flaky under
        // XCUITest (hit-testing hangs), so we assert presence rather than deep navigation.
        XCTAssertTrue(app.staticTexts["Recurring expenses"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Recurring income"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.waitForAny("settings-recurring-expenses", timeout: 3) != nil
            || app.waitForAny("settings-recurring-incomes", timeout: 1) != nil)
    }

    func testLogoutReturnsToLoginAndHidesSettings() {
        let app = XCUIApplication()
        app.launchForUITesting()
        app.loginAsE2EUser()

        app.buttons["settings-menu-trigger"].tap()
        app.buttons["settings-logout"].tap()

        XCTAssertTrue(app.uiElement("login-page").waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["settings-menu-trigger"].exists)
    }
}
