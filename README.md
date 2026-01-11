# DLAuthManager

A powerful, flexible authentication SDK for SwiftUI applications, similar to Supabase Auth. DLAuthManager provides a complete authentication solution that works with any REST API backend.

## Features

- Complete authentication flow (sign up, sign in, sign out)
- OTP verification (email/SMS)
- Password management (forgot, reset, update)
- Session management with automatic token refresh
- Secure token storage using Keychain
- Simple auth state change listeners
- SwiftUI integration with `@ObservableObject`
- Fully customizable API endpoints
- Type-safe API with modern Swift concurrency

## Installation

### Swift Package Manager

Add DLAuthManager to your project using Xcode:

1. File > Add Packages
2. Enter the repository URL
3. Select the version you want to use

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/DLAuthManager.git", from: "1.0.0")
]
```

## Quick Start

### Basic Setup

```swift
import SwiftUI
import DLAuthManager

@main
struct MyApp: App {
    @StateObject private var authManager: DLAuthManager

    init() {
        // Initialize with your API endpoint
        let apiURL = URL(string: "https://api.example.com")!
        let manager = DLAuthManager(url: apiURL)
        _authManager = StateObject(wrappedValue: manager)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}
```

### Custom API Paths

If your API uses different endpoint paths, you can customize them:

```swift
let customPaths = DLAuthAPIPaths(
    signUp: "/api/v1/register",
    signIn: "/api/v1/login",
    signOut: "/api/v1/logout",
    user: "/api/v1/me",
    resendOTP: "/api/v1/otp/resend",
    verifyOTP: "/api/v1/otp/verify",
    forgotPassword: "/api/v1/password/forgot",
    resetPassword: "/api/v1/password/reset",
    updatePassword: "/api/v1/password/change",
    refreshSession: "/api/v1/token/refresh"
)

let apiURL = URL(string: "https://api.example.com")!
let authManager = DLAuthManager(url: apiURL, apiPaths: customPaths)
```

## Usage Examples

### Sign Up

```swift
struct SignUpView: View {
    @EnvironmentObject var authManager: DLAuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button("Sign Up") {
                Task {
                    await signUp()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func signUp() async {
        do {
            let metadata: [String: AnyCodable] = [
                "firstName": AnyCodable("John"),
                "lastName": AnyCodable("Doe")
            ]

            let response = try await authManager.signUp(
                email: email,
                password: password,
                metadata: metadata
            )

            print("Signed up successfully: \(response.user?.email ?? "")")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

### Sign In

**Option 1: Sign in with Email (Default)**

```swift
// Simple sign in with email
try await authManager.signIn(identifier: "user@example.com", password: "password123")
```

**Option 2: Sign in with Username**

```swift
// Sign in with username
try await authManager.signIn(identifier: "john_doe", password: "password123", type: .username)
```

**Option 3: Sign in with Custom Credentials (Advanced)**

```swift
// For custom authentication flows
struct CustomSignIn: Encodable, Sendable {
    let phone: String
    let password: String
    let deviceId: String
}

let credentials = CustomSignIn(phone: "+1234567890", password: "pass", deviceId: "device-123")
try await authManager.signIn(credentials: credentials)
```

**Complete SwiftUI Example**

```swift
struct SignInView: View {
    @EnvironmentObject var authManager: DLAuthManager
    @State private var identifier = ""
    @State private var password = ""
    @State private var useUsername = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            TextField(useUsername ? "Username" : "Email", text: $identifier)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            Toggle("Sign in with username", isOn: $useUsername)
                .font(.caption)

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button("Sign In") {
                Task {
                    await signIn()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func signIn() async {
        do {
            let type: DLAuthManager.SignInIdentifierType = useUsername ? .username : .email
            let response = try await authManager.signIn(
                identifier: identifier,
                password: password,
                type: type
            )
            print("Signed in successfully: \(response.user?.email ?? "")")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

### Sign Out

```swift
Button("Sign Out") {
    Task {
        do {
            try await authManager.signOut()
            print("Signed out successfully")
        } catch {
            print("Error signing out: \(error)")
        }
    }
}
```

### Get Current User

```swift
struct ProfileView: View {
    @EnvironmentObject var authManager: DLAuthManager
    @State private var user: DLUser?

    var body: some View {
        VStack {
            if let user = user {
                Text("Email: \(user.email ?? "N/A")")
                Text("User ID: \(user.id)")
            } else {
                Text("Loading...")
            }
        }
        .task {
            await loadUser()
        }
    }

    private func loadUser() async {
        do {
            user = try await authManager.getCurrentUser()
        } catch {
            print("Error loading user: \(error)")
        }
    }
}
```

### OTP Verification

```swift
// Resend OTP
try await authManager.resendOTP(email: "user@example.com", type: .email)

// Verify OTP
let response = try await authManager.verifyOTP(
    email: "user@example.com",
    token: "123456",
    type: .email
)
```

### Password Management

```swift
// Forgot Password
try await authManager.forgotPassword(email: "user@example.com")

// Reset Password with Token
let response = try await authManager.resetPassword(
    token: "reset_token_from_email",
    newPassword: "newSecurePassword123"
)

// Update Password (when logged in)
let response = try await authManager.updatePassword(newPassword: "newPassword123")
```

### Session Management

```swift
// Refresh Session
let newSession = try await authManager.refreshSession()

// Check if session is valid
if authManager.isSessionValid() {
    print("Session is valid")
} else {
    print("Session expired")
}

// Get access token
if let token = authManager.getAccessToken() {
    print("Access token: \(token)")
}
```

### Auth State Listener

Listen to authentication state changes with a simple callback:

```swift
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    private let authManager: DLAuthManager

    init(authManager: DLAuthManager) {
        self.authManager = authManager
        setupAuthListener()
    }

    private func setupAuthListener() {
        authManager.onAuthStateChange { [weak self] state, session in
            switch state {
            case .initialSession:
                // Fired immediately when listener is attached
                // Check if session exists and is valid
                if let session = session, session.notExpired {
                    print("Session restored: \(session.user?.email ?? "unknown")")
                    self?.isAuthenticated = true
                } else {
                    print("No valid session on load")
                    self?.isAuthenticated = false
                }

            case .signedIn:
                print("User signed in: \(session?.user?.email ?? "unknown")")
                self?.isAuthenticated = true

            case .signedOut:
                print("User signed out")
                self?.isAuthenticated = false

            case .unknown:
                print("Auth state unknown")
                self?.isAuthenticated = false
            }
        }
    }
}
```

**Note**: Only one handler can be active at a time. Setting a new handler will replace the previous one.

### Making Authenticated API Requests

DLAuthManager automatically handles authentication for your API calls. No need to manually add Bearer tokens!

```swift
struct Story: Codable {
    let id: String
    let title: String
    let content: String
}

struct UserStoriesView: View {
    @EnvironmentObject var authManager: DLAuthManager
    @State private var stories: [Story] = []

    var body: some View {
        List(stories, id: \.id) { story in
            VStack(alignment: .leading) {
                Text(story.title).font(.headline)
                Text(story.content).font(.caption)
            }
        }
        .task {
            await loadStories()
        }
    }

    private func loadStories() async {
        do {
            // DLAuthManager automatically adds the Bearer token!
            let response: [Story] = try await authManager.get(path: "/api/user/stories")
            stories = response
        } catch {
            print("Error loading stories: \(error)")
        }
    }
}
```

**Available HTTP Methods:**

```swift
// GET request - List all stories
let stories: [Story] = try await authManager.get(path: "/api/stories")

// GET request - Single story by ID (using path parameter)
let storyId = "123"
let story: Story = try await authManager.get(path: "/api/stories/\(storyId)")

// GET with query parameters (filtering, pagination, etc.)
let queryItems = [
    URLQueryItem(name: "page", value: "1"),
    URLQueryItem(name: "limit", value: "20"),
    URLQueryItem(name: "category", value: "tech")
]
let stories: [Story] = try await authManager.get(
    path: "/api/stories",
    queryItems: queryItems
)
// Makes request to: /api/stories?page=1&limit=20&category=tech

// GET with optional query parameters
func searchStories(authorId: String? = nil, tag: String? = nil) async throws -> [Story] {
    var queryItems: [URLQueryItem] = []

    if let authorId = authorId {
        queryItems.append(URLQueryItem(name: "author_id", value: authorId))
    }

    if let tag = tag {
        queryItems.append(URLQueryItem(name: "tag", value: tag))
    }

    return try await authManager.get(
        path: "/api/stories/search",
        queryItems: queryItems.isEmpty ? nil : queryItems
    )
}

// POST request - Create new story
struct CreateStoryRequest: Codable, Sendable {
    let title: String
    let content: String
}

let newStory = CreateStoryRequest(title: "My Story", content: "Content...")
let createdStory: Story = try await authManager.post(
    path: "/api/stories",
    body: newStory
)

// PUT request - Update entire story
struct UpdateStoryRequest: Codable, Sendable {
    let title: String
    let content: String
    let author: String
}

let updateData = UpdateStoryRequest(title: "Updated", content: "New content", author: "John")
let updatedStory: Story = try await authManager.put(
    path: "/api/stories/123",
    body: updateData
)

// PATCH request - Partial update
struct PatchStoryRequest: Codable, Sendable {
    let title: String?
    let content: String?
}

let partialUpdate = PatchStoryRequest(title: "New Title", content: nil)
let patchedStory: Story = try await authManager.patch(
    path: "/api/stories/123",
    body: partialUpdate
)

// DELETE request
struct DeleteResponse: Codable, Sendable {
    let success: Bool
    let message: String?
}

let result: DeleteResponse = try await authManager.delete(path: "/api/stories/123")
```

**Key Benefits:**
- ✅ Automatic Bearer token authentication
- ✅ Uses the same base URL from initialization
- ✅ Automatic JSON encoding/decoding
- ✅ Snake case conversion (Swift camelCase ↔️ API snake_case)
- ✅ ISO8601 date handling

**Complete Example - Fetching Single Resource:**

```swift
struct StoryDetailView: View {
    let storyId: String
    @EnvironmentObject var authManager: DLAuthManager
    @State private var story: Story?
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
            } else if let error = error {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else if let story = story {
                VStack(alignment: .leading, spacing: 16) {
                    Text(story.title)
                        .font(.title)
                    Text(story.content)
                }
                .padding()
            }
        }
        .task {
            await loadStory()
        }
    }

    private func loadStory() async {
        isLoading = true
        error = nil

        do {
            // Fetch single story by ID
            story = try await authManager.get(path: "/api/stories/\(storyId)")
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}
```

### Using Published Properties

DLAuthManager provides `@Published` properties for reactive UI updates:

```swift
struct ContentView: View {
    @EnvironmentObject var authManager: DLAuthManager

    var body: some View {
        Group {
            if authManager.currentSession != nil {
                Text("Welcome, \(authManager.currentUser?.email ?? "User")!")
            } else {
                Text("Please sign in")
            }
        }
    }
}
```

## API Reference

### Initialization

```swift
// Basic initialization
let apiURL = URL(string: "https://api.example.com")!
let authManager = DLAuthManager(url: apiURL)

// With custom API paths
let customPaths = DLAuthAPIPaths(signUp: "/api/register", signIn: "/api/login", ...)
let authManager = DLAuthManager(url: apiURL, apiPaths: customPaths)

// With configuration object
let config = DLAuthConfig(baseURL: apiURL, apiPaths: customPaths)
let authManager = DLAuthManager(config: config)
```

### Authentication Methods

#### signUp(email:password:metadata:)
Create a new user account.

```swift
func signUp(
    email: String,
    password: String,
    metadata: [String: AnyCodable]? = nil
) async throws -> DLAuthResponse
```

#### signIn(identifier:password:type:)
Sign in an existing user with email or username.

```swift
func signIn(
    identifier: String,
    password: String,
    type: SignInIdentifierType = .email
) async throws -> DLAuthResponse

// SignInIdentifierType options:
// - .email (default)
// - .username
```

#### signIn(credentials:)
Sign in with custom credentials (advanced).

```swift
func signIn<T: Encodable & Sendable>(
    credentials: T
) async throws -> DLAuthResponse
```

#### signOut()
Sign out the current user.

```swift
func signOut() async throws
```

#### getCurrentUser()
Get the current authenticated user.

```swift
func getCurrentUser() async throws -> DLUser
```

#### resendOTP(email:type:)
Resend OTP verification code.

```swift
func resendOTP(
    email: String,
    type: DLOTPType = .email
) async throws
```

#### verifyOTP(email:token:type:)
Verify OTP code.

```swift
func verifyOTP(
    email: String,
    token: String,
    type: DLOTPType = .email
) async throws -> DLAuthResponse
```

#### forgotPassword(email:)
Request password reset.

```swift
func forgotPassword(email: String) async throws
```

#### resetPassword(token:newPassword:)
Reset password with token.

```swift
func resetPassword(
    token: String,
    newPassword: String
) async throws -> DLAuthResponse
```

#### updatePassword(newPassword:)
Update password for authenticated user.

```swift
func updatePassword(newPassword: String) async throws -> DLAuthResponse
```

#### refreshSession()
Refresh the current session.

```swift
func refreshSession() async throws -> DLSession
```

#### onAuthStateChange(_:)
Set a handler to listen for authentication state changes.

```swift
func onAuthStateChange(
    _ handler: @escaping (DLAuthState, DLSession?) -> Void
)
```

**Note**: Only one handler can be active at a time. Setting a new handler will replace the previous one.

#### removeAuthStateHandler()
Remove the auth state change handler.

```swift
func removeAuthStateHandler()
```

### Authenticated API Request Methods

#### get(path:queryItems:headers:)
Make an authenticated GET request.

```swift
func get<T: Decodable>(
    path: String,
    queryItems: [URLQueryItem]? = nil,
    headers: [String: String]? = nil
) async throws -> T
```

#### post(path:body:queryItems:headers:)
Make an authenticated POST request.

```swift
func post<T: Decodable>(
    path: String,
    body: Encodable? = nil,
    queryItems: [URLQueryItem]? = nil,
    headers: [String: String]? = nil
) async throws -> T
```

#### put(path:body:queryItems:headers:)
Make an authenticated PUT request.

```swift
func put<T: Decodable>(
    path: String,
    body: Encodable? = nil,
    queryItems: [URLQueryItem]? = nil,
    headers: [String: String]? = nil
) async throws -> T
```

#### patch(path:body:queryItems:headers:)
Make an authenticated PATCH request.

```swift
func patch<T: Decodable>(
    path: String,
    body: Encodable? = nil,
    queryItems: [URLQueryItem]? = nil,
    headers: [String: String]? = nil
) async throws -> T
```

#### delete(path:queryItems:headers:)
Make an authenticated DELETE request.

```swift
func delete<T: Decodable>(
    path: String,
    queryItems: [URLQueryItem]? = nil,
    headers: [String: String]? = nil
) async throws -> T
```

**Note**: All authenticated API methods automatically include the Bearer token in the Authorization header. They use the base URL specified during DLAuthManager initialization.

## Models

### DLUser
```swift
public struct DLUser: Codable {
    public let id: String
    public let email: String?
    public let phone: String?
    public let emailConfirmedAt: Date?
    public let phoneConfirmedAt: Date?
    public let createdAt: Date?
    public let updatedAt: Date?
    public let metadata: [String: AnyCodable]?
}
```

### DLSession
```swift
public struct DLSession: Codable {
    public let accessToken: String
    public let refreshToken: String?
    public let expiresIn: Int?
    public let expiresAt: Date?
    public let tokenType: String?
    public let user: DLUser?

    // Helper property
    public var notExpired: Bool  // Returns true if session is not expired
}
```

### DLAuthResponse
```swift
public struct DLAuthResponse: Codable {
    public let user: DLUser?
    public let session: DLSession?
}
```

### DLAuthState
```swift
public enum DLAuthState {
    case initialSession  // Fired immediately when listener is attached
    case signedIn        // User signed in successfully
    case signedOut       // User signed out
    case unknown         // Unknown state
}
```

**Note**: When using `onAuthStateChange`, the handler receives two parameters: `(DLAuthState, DLSession?)`. The `.initialSession` state is fired immediately when you attach a listener, with the session passed as the second parameter. This is useful for handling app restarts or hard refreshes where you need to check if a valid session exists.

**Usage Example**:
```swift
authManager.onAuthStateChange { state, session in
    switch state {
    case .initialSession:
        if let session = session, session.notExpired {
            // Valid session exists - user is authenticated
        } else {
            // No valid session - show login
        }
    case .signedIn:
        // User just signed in
    case .signedOut:
        // User signed out
    case .unknown:
        // Unknown state
    }
}
```

### DLOTPType
```swift
public enum DLOTPType: String {
    case signup
    case email
    case sms
    case phoneChange = "phone_change"
    case emailChange = "email_change"
    case recovery
}
```

## Expected API Response Format

Your REST API should return responses in the following format:

### Sign Up / Sign In Response
```json
{
    "user": {
        "id": "user-uuid",
        "email": "user@example.com",
        "email_confirmed_at": "2024-01-01T00:00:00Z",
        "created_at": "2024-01-01T00:00:00Z",
        "metadata": {
            "firstName": "John",
            "lastName": "Doe"
        }
    },
    "session": {
        "access_token": "jwt-token",
        "refresh_token": "refresh-token",
        "expires_in": 3600,
        "token_type": "Bearer"
    }
}
```

### Get User Response
```json
{
    "id": "user-uuid",
    "email": "user@example.com",
    "email_confirmed_at": "2024-01-01T00:00:00Z",
    "created_at": "2024-01-01T00:00:00Z"
}
```

## Error Handling

DLAuthManager provides comprehensive error handling:

```swift
do {
    try await authManager.signIn(email: email, password: password)
} catch let error as DLAuthError {
    switch error {
    case .invalidCredentials:
        print("Invalid email or password")
    case .networkError(let underlyingError):
        print("Network error: \(underlyingError)")
    case .serverError(let statusCode, let message):
        print("Server error \(statusCode): \(message ?? "")")
    case .noSession:
        print("No active session")
    default:
        print("Error: \(error.localizedDescription)")
    }
} catch {
    print("Unexpected error: \(error)")
}
```

## Security

- Tokens are securely stored in the iOS Keychain
- All network requests use HTTPS
- Passwords are never stored locally
- Automatic session expiry checking
- Secure token refresh mechanism

## Requirements

- iOS 15.0+
- macOS 12.0+
- Swift 5.9+
- Xcode 14.0+

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
