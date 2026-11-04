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

        let row = app.buttons["expense-row-101"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10), "expense-row-101 missing")

        row.press(forDuration: 1.2)
        let menuDelete = app.buttons["expense-delete"].firstMatch
        if menuDelete.waitForExistence(timeout: 2), menuDelete.isHittable {
            menuDelete.tap()
        } else {
            let start = row.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5))
            let end = row.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.5))
            start.press(forDuration: 0.05, thenDragTo: end)
            let trash = app.buttons["row-swipe-delete"].firstMatch
            let revealed = NSPredicate(format: "isHittable == true")
            _ = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: revealed, object: trash)], timeout: 3)
            XCTAssertTrue(trash.isHittable, "swipe delete was not revealed")
            trash.tap()
        }

        let confirm = app.buttons["expense-delete-confirm"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "delete confirmation missing")
        confirm.tap()

        let gone = NSPredicate(format: "exists == false")
        _ = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: gone, object: app.buttons["expense-row-101"].firstMatch)], timeout: 5)
        XCTAssertFalse(app.buttons["expense-row-101"].firstMatch.exists)
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
