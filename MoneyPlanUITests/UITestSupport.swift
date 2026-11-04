import XCTest

enum UITestCredentials {
    static let email = ProcessInfo.processInfo.environment["E2E_EMAIL"] ?? "e2e@money-plan.test"
    static let password = ProcessInfo.processInfo.environment["E2E_PASSWORD"] ?? "e2e-password-123"
    static let authEmulator = ProcessInfo.processInfo.environment["FIREBASE_AUTH_EMULATOR_HOST"] ?? "127.0.0.1:9099"
}

extension XCUIApplication {
    /// Stable page markers from `UITestPageAnchor` (UIView) → Other.
    func uiElement(_ identifier: String) -> XCUIElement {
        otherElements[identifier].firstMatch
    }

    /// Poll common element types (avoids slow `descendants(matching: .any)`).
    /// Prefers interactive types (cells/buttons/other) over StaticText — tapping a
    /// StaticText NavigationLink label often hangs on "interrupting elements".
    @discardableResult
    func waitForAny(_ identifier: String, timeout: TimeInterval) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let candidates = [
                cells[identifier].firstMatch,
                buttons[identifier].firstMatch,
                otherElements[identifier].firstMatch,
                textFields[identifier].firstMatch,
                textViews[identifier].firstMatch,
                navigationBars[identifier].firstMatch,
                staticTexts[identifier].firstMatch,
            ]
            if let match = candidates.first(where: { $0.exists && $0.isHittable }) {
                return match
            }
            if let match = candidates.first(where: \.exists) {
                return match
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.15))
        }
        return nil
    }

    /// Taps a settings `List` row by visible English label (cell, not StaticText).
    func tapSettingsRow(labeled label: String) {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", label)
        let cell = cells.containing(predicate).firstMatch
        if cell.waitForExistence(timeout: 5) {
            cell.tap()
            return
        }
        let button = buttons.matching(predicate).firstMatch
        if button.waitForExistence(timeout: 3) {
            button.tap()
            return
        }
        XCTFail("settings row labeled \(label) not tappable")
    }

    /// Single-line fields are TextFields; `TextField(..., axis: .vertical)` is a TextView.
    func formField(_ identifier: String) -> XCUIElement {
        let textField = textFields[identifier].firstMatch
        if textField.exists { return textField }
        return textViews[identifier].firstMatch
    }

    func launchForUITesting() {
        launchArguments += ["-UITesting"]
        launchEnvironment["FIREBASE_AUTH_EMULATOR_HOST"] = UITestCredentials.authEmulator
        // Avoid iOS AutoFill / strong-password prompts stealing hits during UI tests.
        launchArguments += ["-AppleLanguages", "(en)"]
        launchArguments += ["-AppleLocale", "en_US"]
        launch()
    }

    /// Dismiss Save Password / keyboard / other transient system chrome.
    /// Only taps a control that is on screen. An off-screen "Not Now" still
    /// exists after the password prompt closes, and `tap()` then fails with a
    /// hit point of {-1, -1}.
    func dismissTransientUI() {
        let dismissLabels = ["Not Now", "Never", "No Thanks", "Dismiss", "Close", "Not now"]
        for label in dismissLabels {
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            if tapIfHittable(springboard.buttons[label]) { return }
            if tapIfHittable(buttons[label]) { return }
        }
        if keyboards.firstMatch.exists {
            // Decimal/email keyboards — tap elsewhere to dismiss when possible.
            coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
        }
    }

    @discardableResult
    private func tapIfHittable(_ element: XCUIElement) -> Bool {
        guard element.exists, element.isHittable else { return false }
        element.tap()
        return true
    }

    func loginAsE2EUser() {
        XCTAssertTrue(uiElement("login-page").waitForExistence(timeout: 10))

        let email = textFields["login-email"].firstMatch
        let password = secureTextFields["login-password"].firstMatch
        XCTAssertTrue(email.waitForExistence(timeout: 5), "login-email field missing")
        XCTAssertTrue(password.waitForExistence(timeout: 5), "login-password field missing")

        email.tap()
        email.typeText(UITestCredentials.email)
        password.tap()
        password.typeText(UITestCredentials.password)
        buttons["login-submit"].firstMatch.tap()
        dismissTransientUI()
        XCTAssertTrue(uiElement("expenses-page").waitForExistence(timeout: 20))
        dismissTransientUI()
    }

    /// Opens Settings from the gear in the navigation bar and waits until that page is up.
    func openSettings() {
        dismissTransientUI()
        let trigger = buttons["settings-menu-trigger"].firstMatch
        XCTAssertTrue(trigger.waitForExistence(timeout: 5), "settings-menu-trigger missing")
        let hittable = NSPredicate(format: "isHittable == true")
        _ = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: hittable, object: trigger)], timeout: 5)
        XCTAssertTrue(trigger.isHittable, "settings-menu-trigger is not on screen")
        trigger.tap()
        XCTAssertTrue(uiElement("settings-page").waitForExistence(timeout: 8), "settings-page did not open")
    }

    func openTab(index: Int) {
        let tab = tabBars.buttons.element(boundBy: index)
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "tab \(index) missing")
        tab.tap()
        dismissTransientUI()
    }
}

enum AuthEmulatorSeed {
    static let projectId = "money-plan-23efb"

    /// Clears emulator accounts and creates the shared e2e user (same as web global-setup).
    static func ensureUser() async throws {
        let origin = "http://\(UITestCredentials.authEmulator)"
        let clearURL = URL(string: "\(origin)/emulator/v1/projects/\(projectId)/accounts")!
        var clear = URLRequest(url: clearURL)
        clear.httpMethod = "DELETE"
        _ = try await URLSession.shared.data(for: clear)

        let signUpURL = URL(string: "\(origin)/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key")!
        var signUp = URLRequest(url: signUpURL)
        signUp.httpMethod = "POST"
        signUp.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "email": UITestCredentials.email,
            "password": UITestCredentials.password,
            "returnSecureToken": true,
        ]
        signUp.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await URLSession.shared.data(for: signUp)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200 ... 299).contains(status) else {
            throw NSError(domain: "AuthEmulatorSeed", code: status)
        }
    }
}
