import SwiftUI
import DLAuthManager

// MARK: - Example App Entry Point

@main
struct ExampleApp: App {
    @StateObject private var authManager: DLAuthManager

    init() {
        // Initialize with your API endpoint
        let apiURL = URL(string: "https://your-api.example.com")!
        let manager = DLAuthManager(url: apiURL)
        _authManager = StateObject(wrappedValue: manager)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
        }
    }
}

// MARK: - Root View

struct RootView: View {
    @EnvironmentObject var authManager: DLAuthManager

    var body: some View {
        Group {
            if authManager.currentSession != nil {
                MainView()
            } else {
                AuthenticationView()
            }
        }
    }
}

// MARK: - Authentication View

struct AuthenticationView: View {
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            if showSignUp {
                SignUpView(showSignUp: $showSignUp)
            } else {
                SignInView(showSignUp: $showSignUp)
            }
        }
    }
}

// MARK: - Sign In View

struct SignInView: View {
    @EnvironmentObject var authManager: DLAuthManager
    @Binding var showSignUp: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showForgotPassword = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Sign In")
                .font(.largeTitle)
                .bold()

            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task {
                        await signIn()
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || email.isEmpty || password.isEmpty)

                Button("Forgot Password?") {
                    showForgotPassword = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding()

            Divider()

            Button {
                showSignUp = true
            } label: {
                Text("Don't have an account? Sign Up")
                    .font(.subheadline)
            }
        }
        .padding()
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }

    private func signIn() async {
        isLoading = true
        errorMessage = nil

        do {
            _ = try await authManager.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Sign Up View

struct SignUpView: View {
    @EnvironmentObject var authManager: DLAuthManager
    @Binding var showSignUp: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showOTPVerification = false
    @State private var registeredEmail = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Create Account")
                    .font(.largeTitle)
                    .bold()

                VStack(spacing: 16) {
                    TextField("First Name", text: $firstName)
                        .textFieldStyle(.roundedBorder)

                    TextField("Last Name", text: $lastName)
                        .textFieldStyle(.roundedBorder)

                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)

                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task {
                            await signUp()
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Sign Up")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading || !isFormValid)
                }
                .padding()

                Divider()

                Button {
                    showSignUp = false
                } label: {
                    Text("Already have an account? Sign In")
                        .font(.subheadline)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showOTPVerification) {
            OTPVerificationView(email: registeredEmail)
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }

    private func signUp() async {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let metadata: [String: AnyCodable] = [
                "firstName": AnyCodable(firstName),
                "lastName": AnyCodable(lastName)
            ]

            _ = try await authManager.signUp(
                email: email,
                password: password,
                metadata: metadata
            )

            registeredEmail = email
            showOTPVerification = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Forgot Password View

struct ForgotPasswordView: View {
    @EnvironmentObject var authManager: DLAuthManager
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var message: String?
    @State private var isLoading = false
    @State private var isSuccess = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Reset Password")
                    .font(.title)
                    .bold()

                Text("Enter your email address and we'll send you a link to reset your password.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()

                if let message = message {
                    Text(message)
                        .foregroundColor(isSuccess ? .green : .red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task {
                        await sendResetLink()
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Send Reset Link")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || email.isEmpty)
            }
            .padding()
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
            })
        }
    }

    private func sendResetLink() async {
        isLoading = true
        message = nil

        do {
            try await authManager.forgotPassword(email: email)
            message = "Password reset link sent! Check your email."
            isSuccess = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismiss()
            }
        } catch {
            message = error.localizedDescription
            isSuccess = false
        }

        isLoading = false
    }
}

// MARK: - OTP Verification View

struct OTPVerificationView: View {
    @EnvironmentObject var authManager: DLAuthManager
    @Environment(\.dismiss) var dismiss
    let email: String
    @State private var otpCode = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Verify Email")
                    .font(.title)
                    .bold()

                Text("Enter the verification code sent to \(email)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                TextField("Verification Code", text: $otpCode)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.title2)

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task {
                        await verifyOTP()
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Verify")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || otpCode.isEmpty)

                Button {
                    Task {
                        await resendOTP()
                    }
                } label: {
                    Text("Resend Code")
                        .font(.subheadline)
                }
            }
            .padding()
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
            })
        }
    }

    private func verifyOTP() async {
        isLoading = true
        errorMessage = nil

        do {
            _ = try await authManager.verifyOTP(email: email, token: otpCode, type: .email)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func resendOTP() async {
        do {
            try await authManager.resendOTP(email: email, type: .email)
            errorMessage = "Code resent successfully"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Main View (After Login)

struct MainView: View {
    @EnvironmentObject var authManager: DLAuthManager
    @State private var showProfile = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Welcome!")
                    .font(.largeTitle)
                    .bold()

                if let user = authManager.currentUser {
                    Text("Email: \(user.email ?? "N/A")")
                        .font(.subheadline)
                }

                Button("View Profile") {
                    showProfile = true
                }
                .buttonStyle(.bordered)

                Button("Settings") {
                    showSettings = true
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Sign Out") {
                    Task {
                        try? await authManager.signOut()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding()
            .navigationTitle("Home")
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

// MARK: - Profile View

struct ProfileView: View {
    @EnvironmentObject var authManager: DLAuthManager
    @Environment(\.dismiss) var dismiss
    @State private var user: DLUser?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if let user = user {
                    List {
                        Section("User Information") {
                            LabeledContent("User ID", value: user.id)
                            LabeledContent("Email", value: user.email ?? "N/A")

                            if let confirmedAt = user.emailConfirmedAt {
                                LabeledContent("Email Confirmed", value: confirmedAt.formatted())
                            }

                            if let createdAt = user.createdAt {
                                LabeledContent("Member Since", value: createdAt.formatted())
                            }
                        }

                        if let metadata = user.metadata {
                            Section("Metadata") {
                                ForEach(Array(metadata.keys.sorted()), id: \.self) { key in
                                    LabeledContent(key, value: "\(metadata[key]?.value ?? "N/A")")
                                }
                            }
                        }
                    }
                } else {
                    Text("Failed to load user")
                }
            }
            .navigationTitle("Profile")
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
            })
            .task {
                await loadUser()
            }
        }
    }

    private func loadUser() async {
        do {
            user = try await authManager.getCurrentUser()
        } catch {
            print("Error loading user: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var authManager: DLAuthManager
    @Environment(\.dismiss) var dismiss
    @State private var showChangePassword = false

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    Button("Change Password") {
                        showChangePassword = true
                    }

                    Button("Refresh Session") {
                        Task {
                            await refreshSession()
                        }
                    }
                }

                Section("Session Info") {
                    if let session = authManager.currentSession {
                        LabeledContent("Token Type", value: session.tokenType ?? "N/A")

                        if let expiresAt = session.expiresAt {
                            LabeledContent("Expires", value: expiresAt.formatted())
                        }

                        LabeledContent("Valid", value: authManager.isSessionValid() ? "Yes" : "No")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
            })
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordView()
            }
        }
    }

    private func refreshSession() async {
        do {
            _ = try await authManager.refreshSession()
        } catch {
            print("Error refreshing session: \(error)")
        }
    }
}

// MARK: - Change Password View

struct ChangePasswordView: View {
    @EnvironmentObject var authManager: DLAuthManager
    @Environment(\.dismiss) var dismiss
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Change Password")
                    .font(.title)
                    .bold()

                SecureField("New Password", text: $newPassword)
                    .textFieldStyle(.roundedBorder)

                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task {
                        await changePassword()
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Update Password")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || !isFormValid)
            }
            .padding()
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
            })
        }
    }

    private var isFormValid: Bool {
        !newPassword.isEmpty &&
        !confirmPassword.isEmpty &&
        newPassword == confirmPassword &&
        newPassword.count >= 6
    }

    private func changePassword() async {
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await authManager.updatePassword(newPassword: newPassword)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
