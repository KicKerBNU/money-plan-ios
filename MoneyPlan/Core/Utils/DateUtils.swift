import Foundation

enum DateUtils {
    static func localISODate(from date: Date = Date()) -> String {
        let calendar = Calendar.current
        let y = calendar.component(.year, from: date)
        let m = calendar.component(.month, from: date)
        let d = calendar.component(.day, from: date)
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    static func parseLocalISODate(_ iso: String) -> Date? {
        let parts = iso.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    static func currentYearMonth() -> (year: Int, month: Int) {
        let now = Date()
        let calendar = Calendar.current
        return (calendar.component(.year, from: now), calendar.component(.month, from: now))
    }

    static func formatMonthYear(_ date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year())
    }

    static func formatShortDate(_ iso: String) -> String {
        guard let date = parseLocalISODate(iso) else { return iso }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    static func startOfWeekMonday(_ date: Date) -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }

    static func endOfWeekMonday(_ date: Date) -> Date {
        let start = startOfWeekMonday(date)
        return Calendar.current.date(byAdding: .day, value: 6, to: start) ?? date
    }
}

enum OverviewPreset: String, CaseIterable, Identifiable {
    case week, month, year

    var id: String { rawValue }
}

struct PeriodRange: Hashable {
    var start: String
    var end: String
}

enum OverviewPeriod {
    static func range(preset: OverviewPreset, anchor: Date) -> PeriodRange {
        let calendar = Calendar.current
        switch preset {
        case .week:
            let start = DateUtils.startOfWeekMonday(anchor)
            let end = DateUtils.endOfWeekMonday(anchor)
            return PeriodRange(start: DateUtils.localISODate(from: start), end: DateUtils.localISODate(from: end))
        case .month:
            let y = calendar.component(.year, from: anchor)
            let m = calendar.component(.month, from: anchor)
            let start = calendar.date(from: DateComponents(year: y, month: m, day: 1))!
            let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)!
            return PeriodRange(start: DateUtils.localISODate(from: start), end: DateUtils.localISODate(from: end))
        case .year:
            let y = calendar.component(.year, from: anchor)
            return PeriodRange(start: "\(y)-01-01", end: "\(y)-12-31")
        }
    }

    static func shiftAnchor(preset: OverviewPreset, anchor: Date, delta: Int) -> Date {
        let calendar = Calendar.current
        switch preset {
        case .week:
            return calendar.date(byAdding: .day, value: delta * 7, to: anchor) ?? anchor
        case .month:
            return calendar.date(byAdding: .month, value: delta, to: anchor) ?? anchor
        case .year:
            return calendar.date(byAdding: .year, value: delta, to: anchor) ?? anchor
        }
    }

    static func bucketKey(for date: String, preset: OverviewPreset) -> String {
        let normalized = normalizeTransactionDay(date)
        if preset == .year { return String(normalized.prefix(7)) }
        return normalized
    }

    static func normalizeTransactionDay(_ raw: String) -> String {
        let dateOnly = raw.contains("T") ? String(raw.prefix(10)) : raw.trimmingCharacters(in: .whitespaces)
        let pattern = /^(\d{4})-(\d{1,2})-(\d{1,2})$/
        if let match = dateOnly.firstMatch(of: pattern) {
            let y = String(match.1)
            let m = Int(match.2)!, d = Int(match.3)!
            return String(format: "%@-%02d-%02d", y, m, d)
        }
        if let parsed = DateUtils.parseLocalISODate(dateOnly) {
            return DateUtils.localISODate(from: parsed)
        }
        return dateOnly
    }

    static func listBucketKeys(preset: OverviewPreset, start: String, end: String) -> [String] {
        if preset == .year {
            let y = Int(start.prefix(4)) ?? 0
            return (1 ... 12).map { String(format: "%04d-%02d", y, $0) }
        }
        guard var current = DateUtils.parseLocalISODate(start),
              let endDate = DateUtils.parseLocalISODate(end)
        else { return [] }

        var keys: [String] = []
        let calendar = Calendar.current
        while current <= endDate {
            keys.append(DateUtils.localISODate(from: current))
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? endDate.addingTimeInterval(86400)
        }
        return keys
    }
}
