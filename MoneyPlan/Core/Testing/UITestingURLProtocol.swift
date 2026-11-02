import Foundation

/// In-process finance API stub for UI tests (mirrors web `e2e/fixtures/finance-api-mock.ts`).
final class UITestingURLProtocol: URLProtocol, @unchecked Sendable {
    private struct State {
        var expenses: [[String: Any]]
        var incomes: [[String: Any]]
        var recurringExpenses: [[String: Any]]
        var recurringIncomes: [[String: Any]]
    }

    private static let lock = NSLock()
    private static var installed = false
    private static var state = State(
        expenses: [defaultExpense()],
        incomes: [defaultIncome()],
        recurringExpenses: [defaultRecurringExpense()],
        recurringIncomes: [defaultRecurringIncome()]
    )

    static func install() {
        lock.lock()
        defer { lock.unlock() }
        guard !installed else { return }
        installed = true
        URLProtocol.registerClass(UITestingURLProtocol.self)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        return url.path.contains("/v1/")
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        let method = (request.httpMethod ?? "GET").uppercased()
        let path = url.path
        // URLSession often places the body in `httpBodyStream`, not `httpBody`.
        let body = Self.decodeJSONObject(from: Self.requestBodyData(request)) as? [String: Any]

        let responseBody: Any
        var status = 200

        Self.lock.lock()
        defer { Self.lock.unlock() }

        if path.hasSuffix("/v1/accounts") {
            responseBody = ["data": [["id": 1, "name": "Cash", "isDefault": true, "initialBalance": 0, "currentBalance": 0]]]
        } else if path.hasSuffix("/v1/categories") {
            responseBody = ["data": [["id": 1, "name": "Food", "isDefault": true], ["id": 2, "name": "Transport", "isDefault": true]]]
        } else if path.hasSuffix("/v1/recurring-expenses") {
            responseBody = ["data": Self.state.recurringExpenses]
        } else if path.hasSuffix("/v1/recurring-incomes") {
            responseBody = ["data": Self.state.recurringIncomes]
        } else if path.hasSuffix("/v1/incomes") || path.contains("/v1/incomes?") {
            responseBody = ["data": Self.state.incomes]
        } else if path.contains("/v1/expenses") && !path.contains("recurring") && method == "GET" {
            responseBody = ["data": Self.state.expenses]
        } else if let id = pathId(path, prefix: "/v1/expenses/"), method == "PUT" {
            Self.state.expenses = Self.state.expenses.map { row in
                guard (row["id"] as? Int) == id else { return row }
                return mergeExpense(row, body: body)
            }
            responseBody = ["data": Self.state.expenses.first { ($0["id"] as? Int) == id } as Any]
        } else if let id = pathId(path, prefix: "/v1/expenses/"), method == "DELETE" {
            Self.state.expenses.removeAll { ($0["id"] as? Int) == id }
            status = 204
            responseBody = NSNull()
        } else if let id = pathId(path, prefix: "/v1/incomes/"), method == "PUT" {
            Self.state.incomes = Self.state.incomes.map { row in
                guard (row["id"] as? Int) == id else { return row }
                return mergeIncome(row, body: body)
            }
            responseBody = ["data": Self.state.incomes.first { ($0["id"] as? Int) == id } as Any]
        } else if let id = pathId(path, prefix: "/v1/incomes/"), method == "DELETE" {
            Self.state.incomes.removeAll { ($0["id"] as? Int) == id }
            status = 204
            responseBody = NSNull()
        } else if let id = pathId(path, prefix: "/v1/recurring-expenses/"), method == "PUT" {
            Self.state.recurringExpenses = Self.state.recurringExpenses.map { row in
                guard (row["id"] as? Int) == id else { return row }
                return mergeRecurringExpense(row, body: body)
            }
            responseBody = ["data": Self.state.recurringExpenses.first { ($0["id"] as? Int) == id } as Any]
        } else if let id = pathId(path, prefix: "/v1/recurring-expenses/"), method == "DELETE" {
            Self.state.recurringExpenses.removeAll { ($0["id"] as? Int) == id }
            status = 204
            responseBody = NSNull()
        } else if let id = pathId(path, prefix: "/v1/recurring-incomes/"), method == "PUT" {
            Self.state.recurringIncomes = Self.state.recurringIncomes.map { row in
                guard (row["id"] as? Int) == id else { return row }
                return mergeRecurringIncome(row, body: body)
            }
            responseBody = ["data": Self.state.recurringIncomes.first { ($0["id"] as? Int) == id } as Any]
        } else if let id = pathId(path, prefix: "/v1/recurring-incomes/"), method == "DELETE" {
            Self.state.recurringIncomes.removeAll { ($0["id"] as? Int) == id }
            status = 204
            responseBody = NSNull()
        } else if path.contains("/v1/stats") {
            responseBody = ["data": ["categories": []]]
        } else if path.contains("/v1/ai/") {
            responseBody = ["data": ["reply": "OK"]]
        } else {
            responseBody = ["data": []]
        }

        let http = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: [
            "Content-Type": "application/json",
        ])!

        client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
        if status != 204, !(responseBody is NSNull) {
            let data = (try? JSONSerialization.data(withJSONObject: responseBody)) ?? Data()
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    // MARK: - Request body

    private static func requestBodyData(_ request: URLRequest) -> Data? {
        if let body = request.httpBody, !body.isEmpty {
            return body
        }
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read <= 0 { break }
            data.append(buffer, count: read)
        }
        return data.isEmpty ? nil : data
    }

    private static func decodeJSONObject(from data: Data?) -> Any? {
        guard let data, !data.isEmpty else { return nil }
        return try? JSONSerialization.jsonObject(with: data)
    }

    // MARK: - Seed helpers

    private static func today() -> String {
        let c = Calendar.current
        let now = Date()
        return String(format: "%04d-%02d-%02d", c.component(.year, from: now), c.component(.month, from: now), c.component(.day, from: now))
    }

    private static func defaultExpense() -> [String: Any] {
        [
            "id": 101,
            "date": today(),
            "amount": 42.5,
            "categoryId": 1,
            "categoryName": "Food",
            "accountId": 1,
            "accountName": "Cash",
            "note": "Lunch",
            "manualSort": NSNull(),
            "recurringExpenseId": NSNull(),
        ]
    }

    private static func defaultIncome() -> [String: Any] {
        [
            "id": 501,
            "date": today(),
            "amount": 3000,
            "accountId": 1,
            "accountName": "Cash",
            "note": "Salary",
            "recurringIncomeId": NSNull(),
        ]
    }

    private static func defaultRecurringExpense() -> [String: Any] {
        let d = today()
        return [
            "id": 301,
            "amount": 99,
            "categoryId": 1,
            "categoryName": "Food",
            "accountId": 1,
            "accountName": "Cash",
            "note": "Netflix",
            "frequency": "monthly",
            "startDate": d,
            "nextDate": d,
            "active": true,
        ]
    }

    private static func defaultRecurringIncome() -> [String: Any] {
        let d = today()
        return [
            "id": 601,
            "amount": 3000,
            "accountId": 1,
            "accountName": "Cash",
            "note": "Monthly salary",
            "frequency": "monthly",
            "startDate": d,
            "nextDate": d,
            "active": true,
        ]
    }

    private func pathId(_ path: String, prefix: String) -> Int? {
        guard let range = path.range(of: prefix) else { return nil }
        let rest = path[range.upperBound...]
        return Int(rest.split(separator: "/").first.map(String.init) ?? "")
    }

    private func mergeExpense(_ row: [String: Any], body: [String: Any]?) -> [String: Any] {
        var next = row
        if let amount = body?["amount"] as? Double { next["amount"] = amount }
        if let amount = body?["amount"] as? Int { next["amount"] = Double(amount) }
        if let note = body?["note"] as? String { next["note"] = note }
        if let date = body?["date"] as? String { next["date"] = date }
        if let categoryId = body?["categoryId"] as? Int { next["categoryId"] = categoryId }
        if let accountId = body?["accountId"] as? Int { next["accountId"] = accountId }
        return next
    }

    private func mergeIncome(_ row: [String: Any], body: [String: Any]?) -> [String: Any] {
        var next = row
        if let amount = body?["amount"] as? Double { next["amount"] = amount }
        if let amount = body?["amount"] as? Int { next["amount"] = Double(amount) }
        if let note = body?["note"] as? String { next["note"] = note }
        if let date = body?["date"] as? String { next["date"] = date }
        if let accountId = body?["accountId"] as? Int { next["accountId"] = accountId }
        return next
    }

    private func mergeRecurringExpense(_ row: [String: Any], body: [String: Any]?) -> [String: Any] {
        var next = row
        if let amount = body?["amount"] as? Double { next["amount"] = amount }
        if let amount = body?["amount"] as? Int { next["amount"] = Double(amount) }
        if let note = body?["note"] as? String { next["note"] = note }
        if let frequency = body?["frequency"] as? String { next["frequency"] = frequency }
        if let startDate = body?["startDate"] as? String { next["startDate"] = startDate }
        return next
    }

    private func mergeRecurringIncome(_ row: [String: Any], body: [String: Any]?) -> [String: Any] {
        mergeRecurringExpense(row, body: body)
    }
}
