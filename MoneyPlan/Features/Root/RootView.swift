import SwiftUI

struct RootView: View {
    @Environment(AuthService.self) private var auth
    @Environment(ThemeManager.self) private var theme

    var body: some View {
        Group {
            if !FirebaseConfiguration.isConfigured {
                FirebaseSetupView(status: FirebaseConfiguration.status)
            } else if !auth.isReady {
                LoadingStateView()
            } else if auth.isAuthenticated {
                MainTabView()
                    // Authenticated chrome follows the user's preference (System/Light/Dark).
                    .preferredColorScheme(theme.colorScheme)
            } else {
                LoginView()
                    // Login is always light — keeps the brand surface consistent and
                    // avoids the dark-on-dark contrast issues we hit earlier.
                    .preferredColorScheme(.light)
            }
        }
        .overlay { ToastOverlay() }
    }
}
