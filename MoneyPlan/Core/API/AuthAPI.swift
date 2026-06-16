import Foundation

enum AuthAPI {
    private static let client = APIClient.shared

    static func deleteCurrentUser() async throws {
        let _: EmptyResponse = try await client.fetch(
            "/v1/me",
            method: "DELETE",
            options: APIFetchOptions(
                silentSuccess: false,
                successMessage: String(localized: "auth.deleteAccount.success")
            )
        )
    }
}
