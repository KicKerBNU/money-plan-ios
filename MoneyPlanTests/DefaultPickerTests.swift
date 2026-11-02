import XCTest
@testable import MoneyPlan

final class DefaultPickerTests: XCTestCase {
    func testDefaultAccountPrefersIsDefaultThenBank() {
        let cash = Account(id: 1, name: "Cash", isDefault: false, initialBalance: 0, currentBalance: 0)
        let bank = Account(id: 2, name: "Bank Accounts", isDefault: false, initialBalance: 0, currentBalance: 0)
        let marked = Account(id: 3, name: "Card", isDefault: true, initialBalance: 0, currentBalance: 0)

        XCTAssertEqual(DefaultAccountPicker.pick(from: [cash, bank, marked])?.id, 3)
        XCTAssertEqual(DefaultAccountPicker.pick(from: [cash, bank])?.id, 2)
        XCTAssertEqual(DefaultAccountPicker.pick(from: [cash])?.id, 1)
        XCTAssertNil(DefaultAccountPicker.pick(from: []))
    }

    func testDefaultCategoryPrefersFood() {
        let transport = Category(id: 1, name: "Transport", isDefault: true, icon: nil)
        let food = Category(id: 2, name: "Food", isDefault: true, icon: nil)

        XCTAssertEqual(DefaultCategoryPicker.pick(from: [transport, food])?.id, 2)
        XCTAssertEqual(DefaultCategoryPicker.pick(from: [transport])?.id, 1)
        XCTAssertNil(DefaultCategoryPicker.pick(from: []))
    }
}
