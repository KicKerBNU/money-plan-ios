import AuthenticationServices
import CryptoKit
import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit

@MainActor
@Observable
final class AuthService {
    static let shared = AuthService()

    private(set) var user: User?
    private(set) var isReady = false

    var isAuthenticated: Bool { user != nil }

    private var authListener: AuthStateDidChangeListenerHandle?
    /// Raw nonce kept between Apple button start and credential exchange (single attempt at a time).
    private var pendingAppleNonce: String?

    private init() {
        guard FirebaseConfiguration.isConfigured else {
            isReady = true
            return
        }
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
                self?.isReady = true
                AnalyticsService.syncUserID()
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func createAccount(email: String, password: String) async throws {
        try await Auth.auth().createUser(withEmail: email, password: password)
    }

    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func signInWithGoogle() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthServiceError.missingClientID
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
        else {
            throw AuthServiceError.missingRootViewController
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: root)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthServiceError.missingGoogleToken
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        try await Auth.auth().signIn(with: credential)
    }

    // MARK: - Sign in with Apple

    /// Returns a fresh nonce and configures `request` per Firebase + Apple guidance.
    /// Call this from `SignInWithAppleButton.onRequest`.
    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonce()
        pendingAppleNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    /// Exchanges Apple credential for a Firebase session. Call from `SignInWithAppleButton.onCompletion`.
    func completeAppleSignIn(_ result: Result<ASAuthorization, Error>) async throws {
        switch result {
        case .failure(let error):
            // User cancel surfaces as ASAuthorizationError.canceled — swallow it silently upstream.
            throw error
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw AuthServiceError.invalidAppleCredential
            }
            guard let nonce = pendingAppleNonce else {
                throw AuthServiceError.missingAppleNonce
            }
            guard let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8) else {
                throw AuthServiceError.invalidAppleCredential
            }

            let firebaseCredential = OAuthProvider.appleCredential(
                withIDToken: idToken,
                rawNonce: nonce,
                fullName: credential.fullName
            )
            try await Auth.auth().signIn(with: firebaseCredential)
            pendingAppleNonce = nil
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
    }

    /// Permanently deletes the signed-in user's account and all stored finance data.
    func deleteAccount() async throws {
        try await AuthAPI.deleteCurrentUser()
        try? signOut()
        user = nil
    }

    func friendlyError(from error: Error) -> String {
        if let asError = error as? ASAuthorizationError, asError.code == .canceled {
            return ""
        }

        let ns = error as NSError
        let code = ns.code
        let message = ns.localizedDescription

        if message.contains("invalid-credential") || code == AuthErrorCode.invalidCredential.rawValue {
            return String(localized: "auth.login.errors.invalidCredential")
        }
        if message.contains("email-already-in-use") || code == AuthErrorCode.emailAlreadyInUse.rawValue {
            return String(localized: "auth.login.errors.emailInUse")
        }
        if message.contains("weak-password") || code == AuthErrorCode.weakPassword.rawValue {
            return String(localized: "auth.login.errors.weakPassword")
        }
        if message.contains("invalid-email") || code == AuthErrorCode.invalidEmail.rawValue {
            return String(localized: "auth.login.errors.invalidEmail")
        }
        return String(localized: "auth.login.errors.generic")
    }

    // MARK: - Nonce helpers (Firebase + Apple spec)

    private static func randomNonce(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var random: UInt8 = 0
            let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if status != errSecSuccess { continue }
            if random < charset.count {
                result.append(charset[Int(random) % charset.count])
                remaining -= 1
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

enum AuthServiceError: LocalizedError {
    case missingClientID
    case missingRootViewController
    case missingGoogleToken
    case invalidAppleCredential
    case missingAppleNonce

    var errorDescription: String? {
        String(localized: "auth.login.errors.generic")
    }
}
