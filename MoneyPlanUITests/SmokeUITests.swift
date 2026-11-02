import XCTest

final class SmokeUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
        try await AuthEmulatorSeed.ensureUser()
    }

    func testLoginScreenShowsEmailFormAndProviders() {
        let app = XCUIApplication()
        app.launchForUITesting()

        XCTAssertTrue(app.uiElement("login-page").waitForExistence(timeout: 10))
        XCTAssertTrue(app.textFields["login-email"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.secureTextFields["login-password"].exists)
        XCTAssertTrue(app.buttons["login-submit"].exists)
        XCTAssertTrue(app.buttons["login-google"].exists)
        XCTAssertFalse(app.buttons["settings-menu-trigger"].exists)
    }

    func testInvalidLoginShowsError() {
        let app = XCUIApplication()
        app.launchForUITesting()

        XCTAssertTrue(app.uiElement("login-page").waitForExistence(timeout: 10))
        let email = app.textFields["login-email"]
        let password = app.secureTextFields["login-password"]
        email.tap()
        email.typeText("e2e-invalid@example.com")
        password.tap()
        password.typeText("wrong-password-123")
        app.buttons["login-submit"].tap()

        XCTAssertNotNil(
            app.waitForAny("login-error", timeout: 10),
            "expected login-error after invalid credentials"
        )
        XCTAssertTrue(app.uiElement("login-page").exists)
    }

    func testSuccessfulLoginReachesExpenses() async throws {
        let app = XCUIApplication()
        app.launchForUITesting()
        app.loginAsE2EUser()
        XCTAssertTrue(app.buttons["settings-menu-trigger"].exists)
    }
}
