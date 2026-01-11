import Foundation

// MARK: - User Model
public struct DLUser: Codable, Sendable {
    public let id: String
    public let email: String?
    public let phone: String?
    public let emailConfirmedAt: Date?
    public let phoneConfirmedAt: Date?
    public let createdAt: Date?
    public let updatedAt: Date?
    public let metadata: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case phone
        case emailConfirmedAt = "email_confirmed_at"
        case phoneConfirmedAt = "phone_confirmed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case metadata
    }

    public init(
        id: String,
        email: String? = nil,
        phone: String? = nil,
        emailConfirmedAt: Date? = nil,
        phoneConfirmedAt: Date? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        metadata: [String: AnyCodable]? = nil
    ) {
        self.id = id
        self.email = email
        self.phone = phone
        self.emailConfirmedAt = emailConfirmedAt
        self.phoneConfirmedAt = phoneConfirmedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.metadata = metadata
    }
}

// MARK: - Session Model
public struct DLSession: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String?
    public let expiresIn: Int?
    public let expiresAt: Date?
    public let tokenType: String?
    public let user: DLUser?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case token
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case expiresAt = "expires_at"
        case tokenType = "token_type"
        case user
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Standard format: supports both "token" and "access_token"
        if let token = try? container.decode(String.self, forKey: .token) {
            accessToken = token
        } else if let token = try? container.decode(String.self, forKey: .accessToken) {
            accessToken = token
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "No access token found. Expected 'token' or 'access_token' field"
                )
            )
        }

        refreshToken = try? container.decode(String.self, forKey: .refreshToken)
        expiresIn = try? container.decode(Int.self, forKey: .expiresIn)
        expiresAt = try? container.decode(Date.self, forKey: .expiresAt)
        tokenType = try? container.decode(String.self, forKey: .tokenType)
        user = try? container.decode(DLUser.self, forKey: .user)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accessToken, forKey: .accessToken)
        try container.encodeIfPresent(refreshToken, forKey: .refreshToken)
        try container.encodeIfPresent(expiresIn, forKey: .expiresIn)
        try container.encodeIfPresent(expiresAt, forKey: .expiresAt)
        try container.encodeIfPresent(tokenType, forKey: .tokenType)
        try container.encodeIfPresent(user, forKey: .user)
    }

    public init(
        accessToken: String,
        refreshToken: String? = nil,
        expiresIn: Int? = nil,
        expiresAt: Date? = nil,
        tokenType: String? = nil,
        user: DLUser? = nil
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.expiresAt = expiresAt
        self.tokenType = tokenType
        self.user = user
    }

    // Helper to check if session is not expired
    public var notExpired: Bool {
        guard let expiresAt = expiresAt else {
            return true  // If no expiry date, consider it valid
        }
        return expiresAt > Date()
    }
}

// MARK: - Auth Response
public struct DLAuthResponse: Codable, Sendable {
    public let user: DLUser?
    public let session: DLSession?

    enum CodingKeys: String, CodingKey {
        case user
        case session
        case token
        case refreshToken = "refresh_token"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Standard Better Auth format: nested user object with token fields at root
        user = try? container.decode(DLUser.self, forKey: .user)

        // Check if session exists as nested object
        if let nestedSession = try? container.decode(DLSession.self, forKey: .session) {
            session = nestedSession
        } else {
            // Build session from root-level token fields
            let accessToken = (try? container.decode(String.self, forKey: .token))
            let refreshToken = try? container.decode(String.self, forKey: .refreshToken)

            if let accessToken = accessToken {
                session = DLSession(
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                    user: user
                )
            } else {
                session = nil
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(user, forKey: .user)
        try container.encodeIfPresent(session, forKey: .session)
    }

    public init(user: DLUser? = nil, session: DLSession? = nil) {
        self.user = user
        self.session = session
    }
}

// MARK: - OTP Type
public enum DLOTPType: String, Codable, Sendable {
    case signup = "signup"
    case email = "email"
    case sms = "sms"
    case phoneChange = "phone_change"
    case emailChange = "email_change"
    case recovery = "recovery"
}

// MARK: - Auth State
public enum DLAuthState: Sendable {
    case initialSession  // Initial state on app load
    case signedIn        // User signed in successfully
    case signedOut       // User signed out
    case unknown         // Unknown state
}

// MARK: - AnyCodable for flexible metadata
public struct AnyCodable: Codable, @unchecked Sendable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Unsupported type"
            ))
        }
    }
}
