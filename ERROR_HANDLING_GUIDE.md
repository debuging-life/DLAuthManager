# DLAuthManager Error Handling Guide

## Philosophy

DLAuthManager provides **raw, complete server error information** so you can handle errors however you want in your own code. The SDK doesn't try to categorize or interpret errors for you - it just passes through the complete error response.

## Error Types

### DLAuthError

The main error enum with these cases:

```swift
public enum DLAuthError {
    case invalidURL              // Invalid URL configuration
    case invalidResponse          // Invalid server response
    case networkError(Error)      // Network connectivity issue
    case timeout                  // Request timed out
    case encodingError(Error)     // Failed to encode request
    case decodingError(Error)     // Failed to decode response
    case noSession                // No active session
    case serverError(DLServerError)  // Server returned an error (most common)
    case custom(String)           // Custom error message
}
```

### DLServerError

Contains the **complete server error response**:

```swift
public struct DLServerError {
    public let statusCode: Int          // HTTP status code (400, 401, 404, etc.)
    public let error: String?           // Error type from server
    public let message: String?         // Error message from server
    public let code: String?            // Error code from server
    public let data: Data?              // Raw response data

    // Access any field from response
    public subscript(key: String) -> Any?

    // Get all response fields
    public var allFields: [String: Any]?
}
```

## Usage Patterns

### Pattern 1: Simple Error Handling

```swift
do {
    try await authManager.signIn(email: email, password: password)
} catch let error as DLAuthError {
    if case .serverError(let serverError) = error {
        // Access full server error
        print("Status: \(serverError.statusCode)")
        print("Message: \(serverError.message ?? "")")
    }

    // Or just show the error description
    showError(error.errorDescription!)
}
```

### Pattern 2: Create Your Own Error Enum

This is the **recommended approach** - map SDK errors to your own domain-specific errors:

```swift
// Your own auth error enum
enum AuthError: LocalizedError {
    case invalidCredentials
    case emailAlreadyExists
    case weakPassword
    case userNotFound
    case networkIssue
    case serverIssue(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .emailAlreadyExists:
            return "Email already registered"
        case .weakPassword:
            return "Password must be at least 8 characters"
        case .userNotFound:
            return "No account found with this email"
        case .networkIssue:
            return "Check your internet connection"
        case .serverIssue(let message):
            return message
        case .unknown:
            return "Something went wrong"
        }
    }
}

// Service layer that maps DLAuthError to your AuthError
class AuthService {
    private let authManager: DLAuthManager

    init(authManager: DLAuthManager) {
        self.authManager = authManager
    }

    func signin(data: SigninModel) async throws {
        do {
            let response = try await authManager.signIn(email: data.email, password: data.password)
            print("Signed in:", response.user?.email ?? "")
        } catch let error as DLAuthError {
            // Map to your own error type
            throw mapToAuthError(error)
        }
    }

    private func mapToAuthError(_ error: DLAuthError) -> AuthError {
        switch error {
        case .serverError(let serverError):
            // Check status code
            switch serverError.statusCode {
            case 401:
                return .invalidCredentials
            case 404:
                return .userNotFound
            case 409:
                return .emailAlreadyExists
            default:
                break
            }

            // Or check error code from backend
            if let errorCode = serverError.error?.lowercased() {
                switch errorCode {
                case "invalid_credentials", "wrong_password":
                    return .invalidCredentials
                case "email_exists":
                    return .emailAlreadyExists
                case "weak_password":
                    return .weakPassword
                case "user_not_found":
                    return .userNotFound
                default:
                    return .serverIssue(serverError.message ?? "Server error")
                }
            }

            return .serverIssue(serverError.message ?? "Server error")

        case .networkError:
            return .networkIssue

        default:
            return .unknown
        }
    }
}
```

### Pattern 3: ViewModel Usage

```swift
class AuthViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let service: AuthService

    init(service: AuthService) {
        self.service = service
    }

    func signIn(data: SigninModel) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await service.signin(data: data)
            // Success - navigate
        } catch {
            // Your AuthError has errorDescription
            guard let authError = error as? AuthError else { return }
            errorMessage = authError.errorDescription
        }
    }
}
```

### Pattern 4: Access Custom Fields

If your backend returns custom fields, you can access them:

```swift
catch let error as DLAuthError {
    if case .serverError(let serverError) = error {
        // Access standard fields
        print("Status: \(serverError.statusCode)")
        print("Message: \(serverError.message ?? "")")

        // Access custom fields using subscript
        if let attemptsRemaining = serverError["attempts_remaining"] as? Int {
            print("Attempts remaining: \(attemptsRemaining)")
        }

        if let fieldName = serverError["field"] as? String {
            print("Invalid field: \(fieldName)")
        }

        // Or get all fields
        if let allFields = serverError.allFields {
            print("All error data:", allFields)
        }
    }
}
```

## Example Backend Response Formats

The SDK handles any JSON error format your backend returns:

### Format 1: Simple message
```json
{
  "message": "Invalid credentials"
}
```

### Format 2: Error code + message
```json
{
  "error": "invalid_credentials",
  "message": "Wrong email or password"
}
```

### Format 3: Full error with details
```json
{
  "error": "validation_error",
  "code": "AUTH_001",
  "message": "Invalid email format",
  "field": "email",
  "attempts_remaining": 3
}
```

All fields are preserved and accessible through `DLServerError`.

## Complete Example

```swift
// 1. Define your error types
enum AuthError: LocalizedError {
    case invalidCredentials
    case emailExists
    case networkIssue
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Wrong email or password"
        case .emailExists:
            return "Email already registered"
        case .networkIssue:
            return "Check your connection"
        case .serverError(let msg):
            return msg
        }
    }
}

// 2. Service layer
class AuthService {
    private let authManager: DLAuthManager

    func signin(email: String, password: String) async throws {
        do {
            try await authManager.signIn(email: email, password: password)
        } catch let error as DLAuthError {
            throw mapError(error)
        }
    }

    private func mapError(_ error: DLAuthError) -> AuthError {
        guard case .serverError(let serverError) = error else {
            if case .networkError = error {
                return .networkIssue
            }
            return .serverError(error.errorDescription ?? "Unknown error")
        }

        // Map based on your backend's error codes
        switch serverError.error?.lowercased() {
        case "invalid_credentials":
            return .invalidCredentials
        case "email_exists":
            return .emailExists
        default:
            return .serverError(serverError.message ?? "Server error")
        }
    }
}

// 3. ViewModel
class LoginViewModel: ObservableObject {
    @Published var errorMessage: String?
    private let service: AuthService

    func signIn(email: String, password: String) async {
        do {
            try await service.signin(email: email, password: password)
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Unexpected error"
        }
    }
}
```

## Best Practices

1. **Create your own error enum** - Don't use DLAuthError directly in your UI
2. **Map errors in a service layer** - Keep error mapping logic in one place
3. **Use error codes from your backend** - Map based on `serverError.error` or `serverError.code`
4. **Access custom fields when needed** - Use `serverError[" key"]` for backend-specific data
5. **Provide user-friendly messages** - Your error enum should have good `errorDescription` values

## Why This Approach?

- **Flexibility**: You decide how to categorize and handle errors
- **No assumptions**: SDK doesn't guess what your backend's errors mean
- **Complete data**: Access to full server response for debugging
- **Type safety**: Create your own error types that match your domain
- **Testability**: Easy to test error handling with your own error types

This gives you full control while keeping the SDK simple and flexible!
