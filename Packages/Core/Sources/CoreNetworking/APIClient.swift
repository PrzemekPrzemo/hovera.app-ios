import Foundation
import CoreAuth

public enum HTTPMethod: String, Sendable {
    case get = "GET", post = "POST", put = "PUT", delete = "DELETE", patch = "PATCH"
}

public struct Endpoint<Response: Decodable>: Sendable {
    public let method: HTTPMethod
    public let path: String
    public let query: [URLQueryItem]
    public let body: Data?
    public let requiresTenant: Bool

    public init(
        method: HTTPMethod = .get,
        path: String,
        query: [URLQueryItem] = [],
        body: Data? = nil,
        requiresTenant: Bool = true
    ) {
        self.method = method
        self.path = path
        self.query = query
        self.body = body
        self.requiresTenant = requiresTenant
    }
}

public enum APIError: Error, Sendable {
    case unauthorized
    case forbidden
    case rateLimited(retryAfter: TimeInterval?)
    case server(status: Int, code: String?, message: String?)
    case transport(URLError)
    case decoding(Error)
    case offline
}

/// Singleton client. Adds Bearer token + X-Tenant-Id from Session and
/// decodes JSON with ISO-8601 dates.
public actor APIClient {
    public static let shared = APIClient(config: .default)

    private let config: APIConfig
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(config: APIConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        dec.keyDecodingStrategy = .useDefaultKeys
        self.decoder = dec
    }

    public func send<Response: Decodable>(_ endpoint: Endpoint<Response>) async throws -> Response {
        var components = URLComponents(url: config.baseURL.appendingPathComponent(endpoint.path),
                                       resolvingAgainstBaseURL: false)!
        if !endpoint.query.isEmpty {
            components.queryItems = endpoint.query
        }

        var request = URLRequest(url: components.url!)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(config.userAgent, forHTTPHeaderField: "User-Agent")
        if endpoint.body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        request.httpBody = endpoint.body

        if let token = await KeychainStore.shared.token() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if endpoint.requiresTenant, let tid = await KeychainStore.shared.activeTenantId() {
            request.setValue(tid, forHTTPHeaderField: "X-Tenant-Id")
        }
        request.setValue(Locale.current.identifier, forHTTPHeaderField: "Accept-Language")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            if urlError.code == .notConnectedToInternet || urlError.code == .timedOut {
                throw APIError.offline
            }
            throw APIError.transport(urlError)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.server(status: 0, code: nil, message: "Non-HTTP response")
        }

        switch http.statusCode {
        case 200...299:
            do { return try decoder.decode(Response.self, from: data) }
            catch { throw APIError.decoding(error) }
        case 401: throw APIError.unauthorized
        case 403: throw APIError.forbidden
        case 429:
            let retry = http.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init)
            throw APIError.rateLimited(retryAfter: retry)
        default:
            let errorEnvelope = try? decoder.decode(ErrorEnvelope.self, from: data)
            throw APIError.server(
                status: http.statusCode,
                code: errorEnvelope?.error.code,
                message: errorEnvelope?.error.message
            )
        }
    }
}

struct ErrorEnvelope: Decodable {
    struct Body: Decodable { let code: String; let message: String? }
    let error: Body
}
