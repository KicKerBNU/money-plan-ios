import FirebaseCore
import Foundation

enum FirebaseConfiguration {
    enum Status: Equatable {
        case configured
        case missingPlist
        case invalidPlist(reason: String)
    }

    private(set) static var status: Status = .missingPlist

    static var isConfigured: Bool {
        if case .configured = status { return true }
        return FirebaseApp.app() != nil
    }

    @discardableResult
    static func configure() -> Status {
        if FirebaseApp.app() != nil {
            status = .configured
            return status
        }

        guard let plistPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") else {
            status = .missingPlist
            return status
        }

        guard let plist = NSDictionary(contentsOfFile: plistPath) as? [String: Any] else {
            status = .invalidPlist(reason: "GoogleService-Info.plist could not be read.")
            return status
        }

        if let appId = plist["GOOGLE_APP_ID"] as? String {
            let trimmed = appId.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed.contains("YOUR_") || !trimmed.contains(":ios:") {
                status = .invalidPlist(
                    reason: "GOOGLE_APP_ID is still a placeholder. Download a real GoogleService-Info.plist from Firebase Console."
                )
                return status
            }
        } else {
            status = .invalidPlist(reason: "GOOGLE_APP_ID is missing from GoogleService-Info.plist.")
            return status
        }

        if let clientId = plist["CLIENT_ID"] as? String, clientId.contains("YOUR_") {
            status = .invalidPlist(
                reason: "CLIENT_ID is still a placeholder. Download a real GoogleService-Info.plist from Firebase Console."
            )
            return status
        }

        FirebaseApp.configure()
        status = .configured
        AnalyticsService.configure()
        return status
    }

    static var reversedClientID: String? {
        guard let plistPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: plistPath) as? [String: Any],
              let value = plist["REVERSED_CLIENT_ID"] as? String,
              !value.contains("YOUR_")
        else { return nil }
        return value
    }
}
