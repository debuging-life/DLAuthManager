import Foundation

// MARK: - Server Error Response
public struct DLServerError: Sendable, LocalizedError {
    public let statusCode: Int
    public let error: String?
    public let message: String?
    public let code: String?
    public let data: Data?

    // Decoded response body if available
    private let responseBody: [String: AnyCodable]?

    public init(statusCode: Int, data: Data?) {
        self.statusCode = statusCode
        self.data = data

        // Try to decode the response
        if let data = data {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            // Try to decode as structured error
            if let structured = try? decoder.decode([String: AnyCodable].self, from: data) {
                self.responseBody = structured
                self.error = structured["error"]?.value as? String
                self.message = structured["message"]?.value as? String
                self.code = structured["code"]?.value as? String
            } else {
                self.responseBody = nil
                self.error = nil
                self.message = nil
                self.code = nil
            }
        } else {
            self.responseBody = nil
            self.error = nil
            self.message = nil
            self.code = nil
        }
    }

    // Access any field from response body
    public subscript(key: String) -> Any? {
        return responseBody?[key]?.value
    }

    // Get all response data
    public var allFields: [String: Any]? {
        return responseBody?.mapValues { $0.value }
    }

    public var errorDescription: String? {
        return message ?? error ?? "Server error (\(statusCode))"
    }
}

// MARK: - Auth Error
public enum DLAuthError: LocalizedError, Sendable {
    // Network & Configuration Errors
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case timeout

    // Encoding/Decoding Errors
    case encodingError(Error)
    case decodingError(Error)

    // Session Errors
    case noSession

    // Server Error - Contains full response
    case serverError(DLServerError)

    // Custom
    case custom(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL configuration"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .timeout:
            return "Request timed out"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .noSession:
            return "No active session found"
        case .serverError(let serverError):
            return serverError.errorDescription
        case .custom(let message):
            return message
        }
    }

    // Helper to get server error if available
    public var serverError: DLServerError? {
        if case .serverError(let error) = self {
            return error
        }
        return nil
    }
}
