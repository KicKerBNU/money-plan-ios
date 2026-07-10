import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @Environment(AuthService.self) private var auth
    @Environment(ToastCenter.self) private var toast

    @State private var mode: AuthMode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isSubmitting = false
    @State private var isPasswordVisible = false
    @State private var showResetSheet = false
    @FocusState private var focusedField: Field?

    enum AuthMode: Hashable { case signIn, signUp }
    enum Field: Hashable { case email, password }

    /// Matches Sign in with Apple HIG sizing; keep Google button visually equivalent.
    private static let socialButtonHeight: CGFloat = 50
    private static let socialButtonCornerRadius: CGFloat = 12

    private static let appName: String = {
        let bundle = Bundle.main
        return bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "Money Plan"
    }()

    private var primaryDisabled: Bool {
        isSubmitting || email.trimmingCharacters(in: .whitespaces).isEmpty || password.count < 6
    }

    var body: some View {
        VStack(spacing: 24) {
            hero

            formSection

            Spacer(minLength: 0)

            socialSection
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .frame(maxWidth: 480)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundGradient.ignoresSafeArea())
        .sheet(isPresented: $showResetSheet) {
            PasswordResetSheet(prefilledEmail: email) { resetEmail in
                Task { await submitPasswordReset(email: resetEmail) }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 10) {
            Image("MarketingAppIcon")
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fill)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: AppColors.primary.opacity(0.3), radius: 14, x: 0, y: 8)
                .accessibilityLabel(Self.appName)

            Text(Self.appName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(1.2)
                .textCase(.uppercase)

            Text(mode == .signIn ? "auth.login.title" : "auth.login.createTitle")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)

            Text("auth.login.description")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Form

    private var formSection: some View {
        VStack(spacing: 14) {
            Picker("auth.login.modeLabel", selection: $mode) {
                Text("auth.login.modeSignIn").tag(AuthMode.signIn)
                Text("auth.login.modeSignUp").tag(AuthMode.signUp)
            }
            .pickerStyle(.segmented)
            .onChange(of: mode) { _, _ in
                errorMessage = ""
                password = ""
                focusedField = nil
            }

            formCard

            if mode == .signIn {
                HStack {
                    Spacer()
                    Button("auth.login.forgotPassword") {
                        showResetSheet = true
                    }
                    .font(.footnote.weight(.medium))
                }
            }

            Button {
                Task { await submitEmail() }
            } label: {
                HStack(spacing: 10) {
                    if isSubmitting {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    }
                    Text(mode == .signIn ? "auth.login.emailSubmit" : "auth.login.createSubmit")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(AppColors.primary)
            .disabled(primaryDisabled)
        }
        .animation(.snappy(duration: 0.2), value: mode)
        .animation(.snappy(duration: 0.2), value: errorMessage)
    }

    private var formCard: some View {
        VStack(spacing: 0) {
            fieldRow(icon: "envelope", label: "auth.login.emailLabel") {
                TextField("auth.login.emailPlaceholder", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .focused($focusedField, equals: .email)
                    .onSubmit { focusedField = .password }
            }

            Divider().padding(.leading, 52)

            fieldRow(icon: "lock", label: "auth.login.passwordLabel") {
                HStack(spacing: 8) {
                    Group {
                        if isPasswordVisible {
                            TextField("auth.login.passwordPlaceholder", text: $password)
                                .textContentType(mode == .signIn ? .password : .newPassword)
                        } else {
                            SecureField("auth.login.passwordPlaceholder", text: $password)
                                .textContentType(mode == .signIn ? .password : .newPassword)
                        }
                    }
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .focused($focusedField, equals: .password)
                    .onSubmit {
                        guard !primaryDisabled else { return }
                        Task { await submitEmail() }
                    }

                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isPasswordVisible
                                        ? "auth.login.hidePassword"
                                        : "auth.login.showPassword")
                }
            }

            if !errorMessage.isEmpty {
                Divider().padding(.leading, 52)
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(errorMessage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.footnote)
                .foregroundStyle(AppColors.danger)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppColors.danger.opacity(0.08))
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.black.opacity(0.08))
        )
    }

    @ViewBuilder
    private func fieldRow<Content: View>(
        icon: String,
        label: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.4)
                content()
                    .font(.body)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Social

    private var socialSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                line
                Text("auth.login.or")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.6)
                line
            }

            // Apple HIG: use the system button; whiteOutline pairs with the bordered Google button on this light screen.
            SignInWithAppleButton(
                mode == .signIn ? .signIn : .signUp,
                onRequest: { request in
                    auth.prepareAppleRequest(request)
                    errorMessage = ""
                },
                onCompletion: { result in
                    Task { await completeAppleSignIn(result) }
                }
            )
            .signInWithAppleButtonStyle(.whiteOutline)
            .frame(maxWidth: .infinity)
            .frame(height: Self.socialButtonHeight)
            .disabled(isSubmitting)
            .opacity(isSubmitting ? 0.55 : 1)

            googleSignInButton
        }
    }

    private var googleSignInButton: some View {
        Button {
            Task { await submitGoogle() }
        } label: {
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                        .font(.body.weight(.semibold))
                    Text("auth.login.googleButton")
                    .font(.body.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: Self.socialButtonHeight)
            .foregroundStyle(.primary)
            .background(Color.white, in: RoundedRectangle(cornerRadius: Self.socialButtonCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Self.socialButtonCornerRadius, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isSubmitting)
        .opacity(isSubmitting ? 0.55 : 1)
        .accessibilityLabel("auth.login.googleButton")
    }

    private var line: some View {
        Rectangle()
            .fill(Color.black.opacity(0.12))
            .frame(height: 1)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.96, green: 0.99, blue: 0.98),
                Color(red: 0.93, green: 0.98, blue: 0.96),
                Color.white
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Actions

    private func submitEmail() async {
        focusedField = nil
        errorMessage = ""
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            if mode == .signIn {
                try await auth.signIn(email: email, password: password)
            } else {
                try await auth.createAccount(email: email, password: password)
            }
        } catch {
            errorMessage = auth.friendlyError(from: error)
        }
    }

    private func submitGoogle() async {
        errorMessage = ""
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await auth.signInWithGoogle()
        } catch {
            let msg = auth.friendlyError(from: error)
            if !msg.isEmpty { errorMessage = msg }
        }
    }

    private func completeAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        errorMessage = ""
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await auth.completeAppleSignIn(result)
        } catch {
            let msg = auth.friendlyError(from: error)
            if !msg.isEmpty { errorMessage = msg }
        }
    }

    private func submitPasswordReset(email resetEmail: String) async {
        do {
            try await auth.sendPasswordReset(email: resetEmail)
            toast.show(.success, String(localized: "auth.login.resetSent"))
            showResetSheet = false
        } catch {
            let msg = auth.friendlyError(from: error)
            if !msg.isEmpty { toast.show(.error, msg) }
        }
    }
}

// MARK: - Password reset sheet

private struct PasswordResetSheet: View {
    let prefilledEmail: String
    let onSubmit: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("auth.login.emailPlaceholder", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focused)
                        .submitLabel(.send)
                        .onSubmit(submit)
                } header: {
                    Text("auth.login.resetTitle")
                } footer: {
                    Text("auth.login.resetDescription")
                }
            }
            .navigationTitle("auth.login.resetTitle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("auth.login.resetSubmit", action: submit)
                        .disabled(email.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                email = prefilledEmail
                focused = true
            }
        }
    }

    private func submit() {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onSubmit(trimmed)
    }
}
