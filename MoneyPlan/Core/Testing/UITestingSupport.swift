import FirebaseAuth
import Foundation

/// Launch-argument hooks for UI tests (`-UITesting`).
///
/// - Auth: set `FIREBASE_AUTH_EMULATOR_HOST` (e.g. `127.0.0.1:9099`) so login hits the emulator.
/// - API: installs `UITestingURLProtocol` so finance calls do not need a real backend.
enum UITestingSupport {
    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-UITesting")
    }

    static func bootstrapIfNeeded() {
        guard isEnabled else { return }

        if let raw = ProcessInfo.processInfo.environment["FIREBASE_AUTH_EMULATOR_HOST"], !raw.isEmpty {
            let parts = raw.split(separator: ":")
            let host = parts.first.map(String.init) ?? "127.0.0.1"
            let port = parts.count > 1 ? Int(parts[1]) ?? 9099 : 9099
            Auth.auth().useEmulator(withHost: host, port: port)
            // Emulator does not send SMS / reCAPTCHA; disable client-side app verification.
            Auth.auth().settings?.isAppVerificationDisabledForTesting = true
        }

        // Keychain may still hold a prior session; start logged out for deterministic UI tests.
        try? Auth.auth().signOut()

        UITestingURLProtocol.install()
    }
}
