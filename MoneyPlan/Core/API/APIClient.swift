import Foundation
import FirebaseAuth

enum APIClientError: LocalizedError {
    case notAuthenticated
    case unauthorized
    case server(status: Int, message: String)
    case decoding(Error)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return String(localized: "User is not authenticated")
        case .unauthorized:
            return String(localized: "Unauthorized")
        case .server(_, let message):
            return message
        case .decoding:
            return String(localized: "common.unexpectedError")
        case .network(let error):
            return error.localizedDescription
        }
    }
}

struct APIFetchOptions: Sendable {
    var silentError = false
    var silentSuccess = false
    var successMessage: String?
}

@MainActor
final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder = JSONDecoder()

    private var baseURL: URL {
        if let value = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           let url = URL(string: value) {
            return url
        }
        return URL(string: "https://money-plan-backend-production.up.railway.app")!
    }

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetch<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: Encodable? = nil,
        options: APIFetchOptions = APIFetchOptions()
    ) async throws -> T {
        let isMutation = ["POST", "PUT", "PATCH", "DELETE"].contains(method.uppercased())

        guard let user = Auth.auth().currentUser else {
            let error = APIClientError.notAuthenticated
            if !options.silentError { ToastCenter.shared.show(.error, error.localizedDescription) }
            throw error
        }

        func perform(forceRefresh: Bool) async throws -> (Data, HTTPURLResponse) {
            let token = try await user.getIDToken(forcingRefresh: forceRefresh)
            let normalized = path.hasPrefix("/") ? path : "/\(path)"
            guard let url = URL(string: normalized, relativeTo: baseURL)?.absoluteURL else {
                throw APIClientError.network(URLError(.badURL))
            }
            var request = URLRequest(url: url)
            request.httpMethod = method
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            if let body {
                request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
            }

            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw APIClientError.network(URLError(.badServerResponse))
                }
                return (data, http)
            } catch let error as APIClientError {
                throw error
            } catch {
                if !options.silentError { ToastCenter.shared.show(.error, error.localizedDescription) }
                throw APIClientError.network(error)
            }
        }

        var (data, response) = try await perform(forceRefresh: false)
        if response.statusCode == 401 {
            (data, response) = try await perform(forceRefresh: true)
        }

        if response.statusCode == 401 {
            let error = APIClientError.unauthorized
            if !options.silentError { ToastCenter.shared.show(.error, error.localizedDescription) }
            throw error
        }

        guard (200 ... 299).contains(response.statusCode) else {
            let body = (try? decoder.decode(APIErrorBody.self, from: data))
            let message = body?.message?.isEmpty == false
                ? body!.message!
                : "Request failed with status \(response.statusCode)"
            if !options.silentError { ToastCenter.shared.show(.error, message) }
            throw APIClientError.server(status: response.statusCode, message: message)
        }

        if response.statusCode == 204 {
            if isMutation, !options.silentSuccess {
                let msg = options.successMessage ?? String(localized: "toast.saveSuccess")
                ToastCenter.shared.show(.success, msg)
            }
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
            throw APIClientError.decoding(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Expected 204 with no body")))
        }

        do {
            let value = try decoder.decode(T.self, from: data)
            if isMutation, !options.silentSuccess {
                let msg = options.successMessage ?? String(localized: "toast.saveSuccess")
                ToastCenter.shared.show(.success, msg)
            }
            return value
        } catch {
            if !options.silentError { ToastCenter.shared.show(.error, String(localized: "common.unexpectedError")) }
            throw APIClientError.decoding(error)
        }
    }
}

struct EmptyResponse: Decodable, Sendable {
    init() {}
}

private struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init(_ value: Encodable) {
        encode = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}
