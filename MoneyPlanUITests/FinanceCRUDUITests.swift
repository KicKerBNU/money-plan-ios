import XCTest

final class FinanceCRUDUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
        try await AuthEmulatorSeed.ensureUser()
    }

    func testEditExpenseUpdatesNote() {
        let app = XCUIApplication()
        app.launchForUITesting()
        app.loginAsE2EUser()

        let row = app.waitForAny("expense-row-101", timeout: 10)
        XCTAssertNotNil(row, "expense-row-101 missing")
        row?.press(forDuration: 1.0)

        let edit = app.buttons["expense-edit"].firstMatch
        if edit.waitForExistence(timeout: 3) {
            edit.tap()
        } else {
            // Fallback: tap row (opens edit sheet).
            row?.tap()
        }

        let note = app.formField("expense-form-note")
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        note.tap()
        note.clearAndType("Dinner out")
        app.buttons["expense-form-submit"].tap()

        // Sheet dismisses after save; assert the updated note on the list.
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Dinner out"))
                .firstMatch.waitForExistence(timeout: 8),
            "edited expense note not visible"
        )
    }

    func testDeleteExpenseRemovesRow() {
        let app = XCUIApplication()
        app.launchForUITesting()
        app.loginAsE2EUser()

        let row = app.waitForAny("expense-row-101", timeout: 10)
        XCTAssertNotNil(row, "expense-row-101 missing")
        row?.press(forDuration: 1.2)

        // SwiftUI context menu — prefer accessibility id, then localized label / menu item.
        let menuDelete = app.buttons["expense-delete"].firstMatch
        if menuDelete.waitForExistence(timeout: 4) {
            menuDelete.tap()
        } else if app.menuItems["Delete"].waitForExistence(timeout: 2) {
            app.menuItems["Delete"].tap()
        } else {
            app.buttons.matching(NSPredicate(format: "label ==[c] %@", "Delete")).firstMatch.tap()
        }

        let confirm = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "Delete")).firstMatch
        if confirm.waitForExistence(timeout: 5) {
            confirm.tap()
        }

        let stillThere = app.waitForAny("expense-row-101", timeout: 3)
        XCTAssertNil(stillThere)
    }

    func testEditIncomeUpdatesNote() {
        let app = XCUIApplication()
        app.launchForUITesting()
        app.loginAsE2EUser()

        app.openTab(index: 1)
        XCTAssertNotNil(app.waitForAny("income-page", timeout: 5))

        let row = app.waitForAny("income-row-501", timeout: 10)
        XCTAssertNotNil(row, "income-row-501 missing")
        row?.press(forDuration: 1.0)
        let edit = app.buttons["income-edit"].firstMatch
        if edit.waitForExistence(timeout: 3) {
            edit.tap()
        } else {
            row?.tap()
        }

        let note = app.formField("income-form-note")
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        note.tap()
        note.clearAndType("Bonus salary")
        app.buttons["income-form-submit"].firstMatch.tap()

        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Bonus salary"))
                .firstMatch.waitForExistence(timeout: 8),
            "edited income note not visible"
        )
    }
}

private extension XCUIElement {
    func clearAndType(_ text: String) {
        tap()
        let current = (value as? String) ?? ""
        if !current.isEmpty {
            // Place caret at end, then delete (works with software keyboards in Simulator).
            let end = coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5))
            end.tap()
            typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }
        typeText(text)
    }
}
