import XCTest
@testable import MoneyPlan

final class OverviewPeriodTests: XCTestCase {
    func testMonthRangeUsesCalendarMonthBounds() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let anchor = calendar.date(from: DateComponents(year: 2026, month: 11, day: 15))!

        let range = OverviewPeriod.range(preset: .month, anchor: anchor)
        XCTAssertEqual(range.start, "2026-11-01")
        XCTAssertEqual(range.end, "2026-11-30")
    }

    func testYearRangeSpansFullYear() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let anchor = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!

        let range = OverviewPeriod.range(preset: .year, anchor: anchor)
        XCTAssertEqual(range.start, "2026-01-01")
        XCTAssertEqual(range.end, "2026-12-31")
    }

    func testNormalizeTransactionDayPadsParts() {
        XCTAssertEqual(OverviewPeriod.normalizeTransactionDay("2026-3-7"), "2026-03-07")
        XCTAssertEqual(OverviewPeriod.normalizeTransactionDay("2026-11-02T12:00:00Z"), "2026-11-02")
    }

    func testYearBucketKeysAreMonths() {
        let keys = OverviewPeriod.listBucketKeys(preset: .year, start: "2026-01-01", end: "2026-12-31")
        XCTAssertEqual(keys.count, 12)
        XCTAssertEqual(keys.first, "2026-01")
        XCTAssertEqual(keys.last, "2026-12")
    }
}
