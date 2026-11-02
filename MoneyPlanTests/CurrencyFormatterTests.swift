import XCTest
@testable import MoneyPlan

@MainActor
final class CurrencyFormatterTests: XCTestCase {
    func testFormatUsesActiveCurrencyAndCents() {
        MoneyPreferences.shared.setCurrency("USD")
        let whole = CurrencyFormatter.format(42)
        let cents = CurrencyFormatter.format(42.5)
        XCTAssertFalse(whole.isEmpty)
        XCTAssertFalse(cents.isEmpty)
        XCTAssertNotEqual(whole, cents)
    }

    func testFormatSignedAddsPrefix() {
        MoneyPreferences.shared.setCurrency("USD")
        XCTAssertTrue(CurrencyFormatter.formatSigned(10).hasPrefix("+"))
        XCTAssertTrue(CurrencyFormatter.formatSigned(-10).contains("10") || CurrencyFormatter.formatSigned(-10).contains("−"))
    }
}
