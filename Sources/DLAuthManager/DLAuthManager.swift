import Foundation
import Combine

// MARK: - DLAuthManager Configuration
public struct DLAuthConfig: Sendable {
    public let baseURL: URL
    public let apiPaths: DLAuthAPIPaths

    public init(baseURL: URL, apiPaths: DLAuthAPIPaths = DLAuthAPIPaths()) {
        self.baseURL = baseURL
        self.apiPaths = apiPaths
    }
}

// MARK: - API Paths Configuration
public struct DLAuthAPIPaths: Sendable {
    public let signUp: String
    public let signIn: String
    public let signOut: String
    public let user: String
    public let resendOTP: String
    public let verifyOTP: String
    public let forgotPassword: String
    public let resetPassword: String
    public let updatePassword: String
    public let refreshSession: String

    public init(
        signUp: String = "/auth/signup",
        signIn: String = "/auth/signin",
        signOut: String = "/auth/signout",
        user: String = "/auth/user",
        resendOTP: String = "/auth/otp/resend",
        verifyOTP: String = "/auth/otp/verify",
        forgotPassword: String = "/auth/password/forgot",
        resetPassword: String = "/auth/password/reset",
        updatePassword: String = "/auth/password/update",
        refreshSession: String = "/auth/token/refresh"
    ) {
        self.signUp = signUp
        self.signIn = signIn
        self.signOut = signOut
        self.user = user
        self.resendOTP = resendOTP
        self.verifyOTP = verifyOTP
        self.forgotPassword = forgotPassword
        self.resetPassword = resetPassword
        self.updatePassword = updatePassword
        self.refreshSession = refreshSession
    }
}

// MARK: - DLAuthManager
@MainActor
public final class DLAuthManager: ObservableObject {
    private let config: DLAuthConfig
    private let networkClient: NetworkClient
    private let storage: KeychainStorage
    private let authStateSubject = PassthroughSubject<DLAuthState, Never>()

    @Published public private(set) var currentSession: DLSession?
    @Published public private(set) var currentUser: DLUser?

    public var authStatePublisher: AnyPublisher<DLAuthState, Never> {
        authStateSubject.eraseToAnyPublisher()
    }

    public init(url: URL, apiPaths: DLAuthAPIPaths = DLAuthAPIPaths()) {
        self.config = DLAuthConfig(baseURL: url, apiPaths: apiPaths)
        self.networkClient = NetworkClient(baseURL: url)
        self.storage = KeychainStorage()
        
        Task {
            await loadSession()
        }
    }

    public convenience init(config: DLAuthConfig) {
        self.init(url: config.baseURL, apiPaths: config.apiPaths)
    }

    // MARK: - Session Management

    private func loadSession() async {
        do {
            if let session = try storage.loadSession() {
                currentSession = session
                networkClient.accessToken = session.accessToken
                currentUser = session.user
                authStateSubject.send(.signedIn(session))
            } else {
                authStateSubject.send(.signedOut)
            }
        } catch {
            authStateSubject.send(.signedOut)
        }
    }

    private func saveSession(_ session: DLSession) async throws {
        try storage.saveSession(session)
        currentSession = session
        networkClient.accessToken = session.accessToken
        currentUser = session.user
        authStateSubject.send(.signedIn(session))
    }

    private func clearSession() async throws {
        try storage.deleteSession()
        currentSession = nil
        networkClient.accessToken = nil
        currentUser = nil
        authStateSubject.send(.signedOut)
    }

    // MARK: - Sign Up

    public func signUp(email: String, password: String, metadata: [String: AnyCodable]? = nil) async throws -> DLAuthResponse {
        struct SignUpRequest: Encodable {
            let email: String
            let password: String
            let metadata: [String: AnyCodable]?
        }

        let request = SignUpRequest(email: email, password: password, metadata: metadata)
        let response: DLAuthResponse = try await networkClient.request(
            path: config.apiPaths.signUp,
            method: .post,
            body: request
        )

        if let session = response.session {
            try await saveSession(session)
        }

        return response
    }

    // MARK: - Sign In

    public enum SignInIdentifierType {
        case email
        case username
    }

    public func signIn(identifier: String, password: String, type: SignInIdentifierType = .email) async throws -> DLAuthResponse {
        struct SignInRequest: Encodable, Sendable {
            let email: String?
            let username: String?
            let password: String
        }

        let request: SignInRequest
        switch type {
        case .email:
            request = SignInRequest(email: identifier, username: nil, password: password)
        case .username:
            request = SignInRequest(email: nil, username: identifier, password: password)
        }

        let response: DLAuthResponse = try await networkClient.request(
            path: config.apiPaths.signIn,
            method: .post,
            body: request
        )

        if let session = response.session {
            try await saveSession(session)
        }

        return response
    }

    // MARK: - Sign In with Custom Credentials

    public func signIn<T: Encodable & Sendable>(credentials: T) async throws -> DLAuthResponse {
        let response: DLAuthResponse = try await networkClient.request(
            path: config.apiPaths.signIn,
            method: .post,
            body: credentials
        )

        if let session = response.session {
            try await saveSession(session)
        }

        return response
    }

    // MARK: - Sign Out

    public func signOut() async throws {
        guard currentSession != nil else {
            throw DLAuthError.noSession
        }

        do {
            try await networkClient.requestWithoutResponse(
                path: config.apiPaths.signOut,
                method: .post,
                requiresAuth: true
            )
        } catch {
            // Continue with local sign out even if server request fails
        }

        try await clearSession()
    }

    // MARK: - Get Current User

    public func getCurrentUser() async throws -> DLUser {
        guard currentSession != nil else {
            throw DLAuthError.noSession
        }

        let user: DLUser = try await networkClient.request(
            path: config.apiPaths.user,
            method: .get,
            requiresAuth: true
        )

        currentUser = user
        return user
    }

    // MARK: - Resend OTP

    public func resendOTP(email: String, type: DLOTPType = .email) async throws {
        struct ResendOTPRequest: Encodable {
            let email: String
            let type: DLOTPType
        }

        let request = ResendOTPRequest(email: email, type: type)
        try await networkClient.requestWithoutResponse(
            path: config.apiPaths.resendOTP,
            method: .post,
            body: request
        )
    }

    // MARK: - Verify OTP

    public func verifyOTP(email: String, token: String, type: DLOTPType = .email) async throws -> DLAuthResponse {
        struct VerifyOTPRequest: Encodable {
            let email: String
            let token: String
            let type: DLOTPType
        }

        let request = VerifyOTPRequest(email: email, token: token, type: type)
        let response: DLAuthResponse = try await networkClient.request(
            path: config.apiPaths.verifyOTP,
            method: .post,
            body: request
        )

        if let session = response.session {
            try await saveSession(session)
        }

        return response
    }

    // MARK: - Forgot Password

    public func forgotPassword(email: String) async throws {
        struct ForgotPasswordRequest: Encodable {
            let email: String
        }

        let request = ForgotPasswordRequest(email: email)
        try await networkClient.requestWithoutResponse(
            path: config.apiPaths.forgotPassword,
            method: .post,
            body: request
        )
    }

    // MARK: - Reset Password

    public func resetPassword(token: String, newPassword: String) async throws -> DLAuthResponse {
        struct ResetPasswordRequest: Encodable {
            let token: String
            let newPassword: String
        }

        let request = ResetPasswordRequest(token: token, newPassword: newPassword)
        let response: DLAuthResponse = try await networkClient.request(
            path: config.apiPaths.resetPassword,
            method: .post,
            body: request
        )

        if let session = response.session {
            try await saveSession(session)
        }

        return response
    }

    // MARK: - Update Password

    public func updatePassword(newPassword: String) async throws -> DLAuthResponse {
        guard currentSession != nil else {
            throw DLAuthError.noSession
        }

        struct UpdatePasswordRequest: Encodable {
            let newPassword: String
        }

        let request = UpdatePasswordRequest(newPassword: newPassword)
        let response: DLAuthResponse = try await networkClient.request(
            path: config.apiPaths.updatePassword,
            method: .put,
            body: request,
            requiresAuth: true
        )

        if let session = response.session {
            try await saveSession(session)
        }

        return response
    }

    // MARK: - Refresh Session

    public func refreshSession() async throws -> DLSession {
        guard let currentSession = currentSession, let refreshToken = currentSession.refreshToken else {
            throw DLAuthError.noSession
        }

        struct RefreshTokenRequest: Encodable {
            let refreshToken: String
        }

        let request = RefreshTokenRequest(refreshToken: refreshToken)
        let session: DLSession = try await networkClient.request(
            path: config.apiPaths.refreshSession,
            method: .post,
            body: request
        )

        try await saveSession(session)
        return session
    }

    // MARK: - Auth State Change Listener

    public func onAuthStateChange(_ handler: @escaping (DLAuthState) -> Void) -> AnyCancellable {
        authStateSubject.sink { state in
            handler(state)
        }
    }

    // MARK: - Check Session Validity

    public func isSessionValid() -> Bool {
        guard let session = currentSession else {
            return false
        }

        if let expiresAt = session.expiresAt {
            return expiresAt > Date()
        }

        return true
    }

    // MARK: - Get Access Token

    public func getAccessToken() -> String? {
        currentSession?.accessToken
    }
}
