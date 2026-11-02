import SwiftUI
import FirebaseCore

@main
struct MoneyPlanApp: App {
    /// Must run before any `Auth.auth()` access (including `AuthService.shared`).
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var authService: AuthService
    @State private var themeManager: ThemeManager
    @State private var toastCenter: ToastCenter
    @State private var moneyPreferences: MoneyPreferences

    init() {
        // Hosted unit tests skip Firebase; UI tests launch with `-UITesting` and must configure.
        if !Self.isRunningUnitTests {
            _ = FirebaseConfiguration.configure()
            UITestingSupport.bootstrapIfNeeded()
        }
        // App.init runs on the main actor at launch; assumeIsolated satisfies Swift 6 checks.
        _authService = State(initialValue: MainActor.assumeIsolated { AuthService.shared })
        _themeManager = State(initialValue: MainActor.assumeIsolated { ThemeManager.shared })
        _toastCenter = State(initialValue: ToastCenter())
        _moneyPreferences = State(initialValue: MainActor.assumeIsolated { MoneyPreferences.shared })
    }

    var body: some Scene {
        WindowGroup {
            // Unit tests (e.g. App Store screenshot generation) host in this process;
            // skip the real UI so Firebase/login does not run during ImageRenderer tests.
            if Self.isRunningUnitTests {
                Color.clear
            } else {
                RootView()
                    .environment(authService)
                    .environment(themeManager)
                    .environment(toastCenter)
                    .environment(moneyPreferences)
                    .tint(AppColors.primary)
            }
        }
    }

    /// True only for the unit-test host process — not the UI-tested app (`-UITesting`).
    private static var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            && !ProcessInfo.processInfo.arguments.contains("-UITesting")
    }
}
