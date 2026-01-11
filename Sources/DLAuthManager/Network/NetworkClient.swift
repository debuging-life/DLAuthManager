import Foundation

// MARK: - HTTP Method
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - Network Client
final class NetworkClient: @unchecked Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let lock = NSLock()
    private var _accessToken: String?

    var accessToken: String? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _accessToken
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _accessToken = newValue
        }
    }

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func request<T: Decodable>(
        path: String,
        method: HTTPMethod,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil,
        headers: [String: String]? = nil,
        requiresAuth: Bool = false
    ) async throws -> T {
        let (data, _) = try await performRequest(
            path: path,
            method: method,
            body: body,
            queryItems: queryItems,
            headers: headers,
            requiresAuth: requiresAuth
        )

        return try decodeResponse(data: data)
    }

    func requestWithoutResponse(
        path: String,
        method: HTTPMethod,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil,
        headers: [String: String]? = nil,
        requiresAuth: Bool = false
    ) async throws {
        _ = try await performRequest(
            path: path,
            method: method,
            body: body,
            queryItems: queryItems,
            headers: headers,
            requiresAuth: requiresAuth
        )
    }

    // MARK: - Helper Methods

    private func buildURL(path: String, queryItems: [URLQueryItem]?) throws -> URL {
        var urlComponents = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: true
        )
        urlComponents?.queryItems = queryItems

        guard let url = urlComponents?.url else {
            throw DLAuthError.invalidURL
        }

        return url
    }

    private func buildRequest(
        url: URL,
        method: HTTPMethod,
        body: Encodable?,
        headers: [String: String]?,
        requiresAuth: Bool
    ) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add authorization header if required
        if requiresAuth, let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Add custom headers
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Encode body if present
        if let body = body {
            request.httpBody = try encodeBody(body)
        }

        return request
    }

    private func encodeBody(_ body: Encodable) throws -> Data {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.keyEncodingStrategy = .convertToSnakeCase
            return try encoder.encode(body)
        } catch {
            throw DLAuthError.encodingError(error)
        }
    }

    private func performRequest(
        path: String,
        method: HTTPMethod,
        body: Encodable?,
        queryItems: [URLQueryItem]?,
        headers: [String: String]?,
        requiresAuth: Bool
    ) async throws -> (Data, HTTPURLResponse) {
        // Build URL
        let url = try buildURL(path: path, queryItems: queryItems)

        // Build request
        let request = try buildRequest(
            url: url,
            method: method,
            body: body,
            headers: headers,
            requiresAuth: requiresAuth
        )

        // Perform network request
        let (data, response) = try await session.data(for: request)

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DLAuthError.invalidResponse
        }

        // Check status code
        guard (200...299).contains(httpResponse.statusCode) else {
            let serverError = DLServerError(statusCode: httpResponse.statusCode, data: data)
            throw DLAuthError.serverError(serverError)
        }

        return (data, httpResponse)
    }

    private func decodeResponse<T: Decodable>(data: Data) throws -> T {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch {
            throw DLAuthError.decodingError(error)
        }
    }
}
