import XCTest
@testable import MoneyPlan

final class DateUtilsTests: XCTestCase {
    func testLocalISODateRoundTrip() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let date = calendar.date(from: DateComponents(year: 2026, month: 11, day: 2))!

        let iso = DateUtils.localISODate(from: date)
        XCTAssertEqual(iso, "2026-11-02")
        XCTAssertEqual(DateUtils.parseLocalISODate(iso).map { DateUtils.localISODate(from: $0) }, iso)
    }

    func testParseRejectsMalformedISO() {
        XCTAssertNil(DateUtils.parseLocalISODate("11/02/2026"))
        XCTAssertNil(DateUtils.parseLocalISODate("2026-11"))
    }
}
