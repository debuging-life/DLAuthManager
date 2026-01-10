# DLAuthManager - Quick Start Guide

A SwiftUI authentication SDK similar to Supabase Auth, designed to work with any REST API backend.

## Installation

Add to your Swift Package Manager dependencies:

```swift
.package(url: "https://github.com/yourusername/DLAuthManager.git", from: "1.0.0")
```

## 5-Minute Quick Start

### 1. Initialize DLAuthManager

```swift
import SwiftUI
import DLAuthManager

@main
struct MyApp: App {
    @StateObject private var authManager: DLAuthManager

    init() {
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

### Custom API Endpoints

```swift
let customPaths = DLAuthAPIPaths(
    signUp: "/api/auth/register",
    signIn: "/api/auth/login",
    signOut: "/api/auth/logout"
)

let apiURL = URL(string: "https://api.example.com")!
let authManager = DLAuthManager(url: apiURL, apiPaths: customPaths)
```

## All Available Methods

```swift
// Sign up new user
let response = try await authManager.signUp(
    email: "user@example.com",
    password: "password123",
    metadata: ["name": AnyCodable("John Doe")]
)

// Sign in
let response = try await authManager.signIn(email: "user@example.com", password: "password123")

// Sign out
try await authManager.signOut()

// Get current user
let user = try await authManager.getCurrentUser()

// Resend OTP
try await authManager.resendOTP(email: "user@example.com", type: .email)

// Verify OTP
let response = try await authManager.verifyOTP(email: "user@example.com", token: "123456", type: .email)

// Forgot password
try await authManager.forgotPassword(email: "user@example.com")

// Reset password
let response = try await authManager.resetPassword(token: "reset_token", newPassword: "newPassword123")

// Update password
let response = try await authManager.updatePassword(newPassword: "newPassword123")

// Refresh session
let session = try await authManager.refreshSession()

// Auth state listener
let cancellable = authManager.onAuthStateChange { state in
    switch state {
    case .signedIn(let session):
        print("User signed in")
    case .signedOut:
        print("User signed out")
    case .unknown:
        print("Unknown state")
    }
}
```

Perfect! Your DLAuthManager SDK is now complete. Here's a summary of what has been created:

## What's Included

### Core Files

1. **DLAuthManager.swift** - Main authentication manager class with all methods
2. **AuthModels.swift** - Data models (DLUser, DLSession, DLAuthResponse, DLOTPType, DLAuthState, AnyCodable)
3. **AuthError.swift** - Error types for authentication
4. **NetworkClient.swift** - HTTP client for API requests
5. **KeychainStorage.swift** - Secure token storage using iOS Keychain

### Features

All the authentication methods you requested:
- `signUp(email, password, metadata)` - Create new account
- `signIn(email, password)` - Sign in user
- `signOut()` - Sign out user
- `getCurrentUser()` - Get current user
- `resendOTP(email, type)` - Resend verification code
- `verifyOTP(email, token, type)` - Verify OTP
- `forgotPassword(email)` - Request password reset
- `resetPassword(token, newPassword)` - Reset password
- `updatePassword(newPassword)` - Update password
- `refreshSession()` - Refresh access token
- `onAuthStateChange()` - Auth state listener using Combine

### Configuration

The SDK is highly configurable:
- Custom base URL for any REST API
- Optional custom API paths for all endpoints
- Works with any backend that follows standard REST patterns

### Usage

```swift
// Initialize with your API endpoint
let authManager = try DLAuthManager(url: "https://your-api.example.com")

// Or with custom paths
let customPaths = DLAuthAPIPaths(signUp: "/api/register", signIn: "/api/login", ...)
let authManager = try DLAuthManager(url: "https://your-api.example.com", apiPaths: customPaths)
```

### Documentation

- Comprehensive README.md with examples
- Complete example SwiftUI app demonstrating all features
- API reference documentation

The SDK is production-ready with secure token storage, proper error handling, and SwiftUI integration!