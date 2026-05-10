import Foundation

public struct LoginRequestBody: Encodable, Sendable {
    public let email: String
    public let password: String
    public let device_name: String?

    public init(email: String, password: String, device_name: String?) {
        self.email = email
        self.password = password
        self.device_name = device_name
    }
}

public struct LoginResponse: Decodable, Sendable {
    public let token: String
    public let expires_at: Date
    public let user: APIUser
    public let memberships: [APIMembership]
}

public struct APIUser: Decodable, Sendable, Identifiable {
    public let id: String
    public let email: String
    public let name: String?
    public let locale: String?
    public let timezone: String?
}

public struct APITenant: Decodable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let slug: String?
    public let country: String?
    public let brand_color: String?
}

public struct APIMembership: Decodable, Sendable {
    public let tenant: APITenant
    public let role: String
    public let permissions: AnyCodable?
}

public struct DeviceRegistration: Encodable, Sendable {
    public let platform: String
    public let token: String
    public let locale: String
    public let app_version: String

    public init(platform: String, token: String, locale: String, app_version: String) {
        self.platform = platform
        self.token = token
        self.locale = locale
        self.app_version = app_version
    }
}

public struct DeviceRegistrationResponse: Decodable, Sendable {
    public let id: String
    public let created: Bool
}

public struct ChangeFeed: Decodable, Sendable {
    public let cursor: String
    public let has_more: Bool
    public let changes: [Change]
}

public struct Change: Decodable, Sendable {
    public let entity: String
    public let op: String
    public let id: String
    public let sync_version: Int
    public let updated_at: Date?
    public let payload: AnyCodable?
}

public struct MutationBatch: Encodable, Sendable {
    public let mutations: [Mutation]
    public init(mutations: [Mutation]) { self.mutations = mutations }
}

public struct Mutation: Codable, Sendable {
    public let client_uuid: String
    public let idempotency_key: String
    public let entity: String
    public let op: String
    public let payload: AnyCodable
    public let base_version: Int?

    public init(
        client_uuid: String,
        idempotency_key: String,
        entity: String,
        op: String,
        payload: AnyCodable,
        base_version: Int?
    ) {
        self.client_uuid = client_uuid
        self.idempotency_key = idempotency_key
        self.entity = entity
        self.op = op
        self.payload = payload
        self.base_version = base_version
    }
}

public struct MutationResults: Decodable, Sendable {
    public let results: [MutationResult]
}

public struct MutationResult: Decodable, Sendable {
    public let client_uuid: String
    public let status: String
    public let server_id: String?
    public let sync_version: Int?
    public let conflict_type: String?
    public let current_server_state: AnyCodable?
    public let errors: [String: [String]]?
}

public struct PresignRequest: Encodable, Sendable {
    public let sha256: String
    public let mime: String
    public let byte_size: Int

    public init(sha256: String, mime: String, byte_size: Int) {
        self.sha256 = sha256
        self.mime = mime
        self.byte_size = byte_size
    }
}

public struct PresignResponse: Decodable, Sendable {
    public let storage_key: String
    public let upload_url: String
    public let method: String
    public let headers: [String: String]
    public let expires_at: Date
}

/// JSON value bridge — lets us decode opaque payloads from /sync/changes
/// and round-trip them as encodable bodies for /sync/mutations.
public struct AnyCodable: Codable, @unchecked Sendable {
    public let value: JSONValue

    public init(_ value: JSONValue) { self.value = value }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.value = .null
        } else if let v = try? container.decode(Bool.self) {
            self.value = .bool(v)
        } else if let v = try? container.decode(Int.self) {
            self.value = .int(v)
        } else if let v = try? container.decode(Double.self) {
            self.value = .double(v)
        } else if let v = try? container.decode(String.self) {
            self.value = .string(v)
        } else if let v = try? container.decode([AnyCodable].self) {
            self.value = .array(v.map(\.value))
        } else if let v = try? container.decode([String: AnyCodable].self) {
            self.value = .object(v.mapValues { $0.value })
        } else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "AnyCodable: unknown JSON token"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case .null: try container.encodeNil()
        case .bool(let v): try container.encode(v)
        case .int(let v): try container.encode(v)
        case .double(let v): try container.encode(v)
        case .string(let v): try container.encode(v)
        case .array(let arr): try container.encode(arr.map(AnyCodable.init))
        case .object(let obj): try container.encode(obj.mapValues(AnyCodable.init))
        }
    }
}

public indirect enum JSONValue: Sendable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])
}
