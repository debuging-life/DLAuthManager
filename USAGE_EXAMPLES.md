# DLAuthManager Usage Examples

## Basic Initialization

```swift
import DLAuthManager

// Simple initialization - no try/catch needed!
let apiURL = URL(string: "https://api.example.com")!
let authManager = DLAuthManager(url: apiURL)
```

## SwiftUI App Setup

```swift
import SwiftUI
import DLAuthManager

@main
struct MyApp: App {
    @StateObject private var authManager: DLAuthManager

    init() {
        let apiURL = URL(string: "https://api.example.com")!
        _authManager = StateObject(wrappedValue: DLAuthManager(url: apiURL))
    }

    var body: some Scene {
        WindowGroup {
            if authManager.currentSession != nil {
                HomeView()
            } else {
                LoginView()
            }
        }
        .environmentObject(authManager)
    }
}
```

## Custom API Paths

```swift
let customPaths = DLAuthAPIPaths(
    signUp: "/api/v1/register",
    signIn: "/api/v1/login",
    signOut: "/api/v1/logout",
    user: "/api/v1/me"
)

let apiURL = URL(string: "https://api.example.com")!
let authManager = DLAuthManager(url: apiURL, apiPaths: customPaths)
```

## Using Configuration Object

```swift
let apiURL = URL(string: "https://api.example.com")!
let config = DLAuthConfig(baseURL: apiURL, apiPaths: customPaths)
let authManager = DLAuthManager(config: config)
```

## Authentication Examples

### Sign Up

```swift
Task {
    do {
        let metadata: [String: AnyCodable] = [
            "firstName": AnyCodable("John"),
            "lastName": AnyCodable("Doe"),
            "age": AnyCodable(25)
        ]

        let response = try await authManager.signUp(
            email: "user@example.com",
            password: "securePassword123",
            metadata: metadata
        )

        print("User signed up: \(response.user?.email ?? "")")
    } catch {
        print("Sign up error: \(error.localizedDescription)")
    }
}
```

### Sign In

```swift
Task {
    do {
        let response = try await authManager.signIn(
            email: "user@example.com",
            password: "securePassword123"
        )
        print("Signed in: \(response.user?.email ?? "")")
    } catch {
        print("Sign in error: \(error.localizedDescription)")
    }
}
```

### Sign Out

```swift
Task {
    do {
        try await authManager.signOut()
        print("Signed out successfully")
    } catch {
        print("Sign out error: \(error.localizedDescription)")
    }
}
```

### Get Current User

```swift
Task {
    do {
        let user = try await authManager.getCurrentUser()
        print("Current user: \(user.email ?? "")")
    } catch {
        print("Error: \(error.localizedDescription)")
    }
}
```

### OTP Verification Flow

```swift
// Step 1: Resend OTP
Task {
    do {
        try await authManager.resendOTP(email: "user@example.com", type: .email)
        print("OTP sent!")
    } catch {
        print("Error: \(error.localizedDescription)")
    }
}

// Step 2: Verify OTP
Task {
    do {
        let response = try await authManager.verifyOTP(
            email: "user@example.com",
            token: "123456",
            type: .email
        )
        print("Verified! Session: \(response.session?.accessToken ?? "")")
    } catch {
        print("Verification error: \(error.localizedDescription)")
    }
}
```

### Password Reset Flow

```swift
// Step 1: Request password reset
Task {
    do {
        try await authManager.forgotPassword(email: "user@example.com")
        print("Reset email sent!")
    } catch {
        print("Error: \(error.localizedDescription)")
    }
}

// Step 2: Reset password with token from email
Task {
    do {
        let response = try await authManager.resetPassword(
            token: "reset-token-from-email",
            newPassword: "newSecurePassword123"
        )
        print("Password reset! User: \(response.user?.email ?? "")")
    } catch {
        print("Reset error: \(error.localizedDescription)")
    }
}
```

### Update Password (When Logged In)

```swift
Task {
    do {
        let response = try await authManager.updatePassword(
            newPassword: "myNewPassword123"
        )
        print("Password updated!")
    } catch {
        print("Update error: \(error.localizedDescription)")
    }
}
```

### Refresh Session

```swift
Task {
    do {
        let newSession = try await authManager.refreshSession()
        print("Session refreshed! New token: \(newSession.accessToken)")
    } catch {
        print("Refresh error: \(error.localizedDescription)")
    }
}
```

## Auth State Listener

### Using Combine

```swift
import Combine

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    private var cancellables = Set<AnyCancellable>()
    private let authManager: DLAuthManager

    init(authManager: DLAuthManager) {
        self.authManager = authManager
        setupAuthListener()
    }

    private func setupAuthListener() {
        authManager.onAuthStateChange { [weak self] state in
            switch state {
            case .signedIn(let session):
                print("Signed in: \(session.user?.email ?? "")")
                self?.isAuthenticated = true

            case .signedOut:
                print("Signed out")
                self?.isAuthenticated = false

            case .unknown:
                print("Unknown state")
                self?.isAuthenticated = false
            }
        }
        .store(in: &cancellables)
    }
}
```

### Using SwiftUI

```swift
struct ContentView: View {
    @EnvironmentObject var authManager: DLAuthManager
    @State private var authState: String = "Unknown"

    var body: some View {
        VStack {
            Text("Auth State: \(authState)")
                .font(.headline)

            if let user = authManager.currentUser {
                Text("Logged in as: \(user.email ?? "")")
            }
        }
        .onAppear {
            _ = authManager.onAuthStateChange { state in
                switch state {
                case .signedIn:
                    authState = "Signed In"
                case .signedOut:
                    authState = "Signed Out"
                case .unknown:
                    authState = "Unknown"
                }
            }
        }
    }
}
```

## SwiftUI Login View Example

```swift
struct LoginView: View {
    @EnvironmentObject var authManager: DLAuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button {
                Task { await signIn() }
            } label: {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Sign In")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading || email.isEmpty || password.isEmpty)
        }
        .padding()
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
```

## Accessing Session Info

```swift
// Check if session is valid
if authManager.isSessionValid() {
    print("Session is still valid")
}

// Get access token
if let token = authManager.getAccessToken() {
    print("Access token: \(token)")
}

// Access session details
if let session = authManager.currentSession {
    print("Token type: \(session.tokenType ?? "Bearer")")
    print("Expires at: \(session.expiresAt?.formatted() ?? "Unknown")")
}

// Access current user
if let user = authManager.currentUser {
    print("User ID: \(user.id)")
    print("Email: \(user.email ?? "")")
    print("Created: \(user.createdAt?.formatted() ?? "")")
}
```

## Error Handling

### Comprehensive Error Handling

```swift
Task {
    do {
        try await authManager.signIn(email: email, password: password)
    } catch let error as DLAuthError {
        switch error {
        // Authentication Errors
        case .invalidCredentials(let message):
            showError(message ?? "Invalid email or password")
        case .emailAlreadyExists(let message):
            showError(message ?? "This email is already registered")
        case .userNotFound(let message):
            showError(message ?? "No account found with this email")
        case .weakPassword(let message):
            showError(message ?? "Please use a stronger password")
        case .invalidEmail(let message):
            showError(message ?? "Please enter a valid email address")

        // Session Errors
        case .noSession:
            showError("Please sign in to continue")
        case .sessionExpired(let message):
            showError(message ?? "Your session has expired. Please sign in again")
        case .tokenExpired(let message):
            showError(message ?? "Your session has expired")
        case .sessionRevoked(let message):
            showError(message ?? "You've been logged out")

        // OTP Errors
        case .invalidOTP(let message):
            showError(message ?? "Invalid verification code")
        case .otpExpired(let message):
            showError(message ?? "Verification code has expired")
        case .tooManyAttempts(let message):
            showError(message ?? "Too many attempts. Please try again later")

        // Network Errors
        case .networkError(let underlyingError):
            showError("Network error: \(underlyingError.localizedDescription)")
        case .timeout:
            showError("Request timed out. Please check your connection")

        // Server Errors with full details
        case .badRequest(let statusCode, let errorCode, let message, let details):
            print("Bad Request (\(statusCode)): \(message ?? "")")
            if let details = details {
                print("Details: \(details)")
            }
            showError(message ?? "Invalid request")

        case .forbidden(_, _, let message, _):
            showError(message ?? "Access forbidden")

        case .serverError(let statusCode, let errorCode, let message, _):
            print("Server Error \(statusCode): \(errorCode ?? "") - \(message ?? "")")
            showError(message ?? "Server error occurred")

        // Default
        default:
            showError(error.errorDescription ?? "An unexpected error occurred")
        }
    } catch {
        print("Unexpected error: \(error)")
        showError("An unexpected error occurred")
    }
}

func showError(_ message: String) {
    // Show error to user
    print("Error: \(message)")
}
```

### Simple Error Handling (Recommended for ViewModels)

```swift
// In your ViewModel
func signIn(email: String, password: String) async {
    self.loading = true
    defer { self.loading = false }

    do {
        try await authManager.signIn(email: email, password: password)
        // Success - navigate or update UI
    } catch let error as DLAuthError {
        // All errors have user-friendly messages via errorDescription
        self.errorMessage = error.errorDescription

        // Optional: Handle specific cases
        if case .sessionRevoked = error {
            // Show special alert for being logged out from another device
        }
    } catch {
        self.errorMessage = "An unexpected error occurred"
    }
}
```

### Accessing Error Details

```swift
do {
    try await authManager.signUp(email: email, password: password)
} catch let error as DLAuthError {
    // Access structured error information
    print("Status Code: \(error.statusCode ?? 0)")
    print("Error Code: \(error.errorCode ?? "none")")
    print("Message: \(error.message ?? "none")")
    print("Details: \(error.details ?? [:])")

    // Show user-friendly message
    toast = Toast(message: error.errorDescription!, type: .error)
}
```

### SwiftUI View Example

```swift
struct LoginView: View {
    @EnvironmentObject var authManager: DLAuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button("Sign In") {
                Task { await signIn() }
            }
            .disabled(isLoading)
        }
        .padding()
    }

    private func signIn() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await authManager.signIn(email: email, password: password)
        } catch let error as DLAuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "An unexpected error occurred"
        }
    }
}
```

## Complete Example: Protected Route

```swift
struct AppRootView: View {
    @EnvironmentObject var authManager: DLAuthManager

    var body: some View {
        Group {
            if authManager.currentSession != nil && authManager.isSessionValid() {
                MainTabView()
            } else {
                AuthenticationFlow()
            }
        }
        .onAppear {
            setupAuthListener()
        }
    }

    private func setupAuthListener() {
        _ = authManager.onAuthStateChange { state in
            // Handle auth state changes
            // UI will automatically update via @Published properties
        }
    }
}
```
