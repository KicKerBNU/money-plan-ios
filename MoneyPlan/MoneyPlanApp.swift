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
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
            _ = FirebaseConfiguration.configure()
        }
        _authService = State(initialValue: AuthService.shared)
        _themeManager = State(initialValue: ThemeManager.shared)
        _toastCenter = State(initialValue: ToastCenter())
        _moneyPreferences = State(initialValue: MoneyPreferences.shared)
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

    private static var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
