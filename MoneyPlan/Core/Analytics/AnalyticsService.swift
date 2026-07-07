import FirebaseAnalytics
import FirebaseAuth
import Foundation

/// Product usage analytics via Firebase Analytics (GA4). No ads, no IDFA, no cross-app tracking.
enum AnalyticsService {
    static func configure() {
        guard FirebaseConfiguration.isConfigured else { return }
        Analytics.setAnalyticsCollectionEnabled(true)
        syncUserID()
    }

    static func syncUserID() {
        guard FirebaseConfiguration.isConfigured else { return }
        Analytics.setUserID(Auth.auth().currentUser?.uid)
    }

    static func logScreen(_ name: String) {
        guard FirebaseConfiguration.isConfigured else { return }
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: name,
            AnalyticsParameterScreenClass: name,
        ])
    }
}
