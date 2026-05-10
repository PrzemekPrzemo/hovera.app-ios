import Foundation

public enum APIEndpoints {
    public static func login(email: String, password: String, deviceName: String?) -> Endpoint<LoginResponse> {
        let body = try? JSONEncoder().encode(LoginRequestBody(
            email: email, password: password, device_name: deviceName
        ))
        return Endpoint(method: .post, path: "/api/v1/auth/login",
                        body: body, requiresTenant: false)
    }

    public static func me() -> Endpoint<MeResponse> {
        Endpoint(method: .get, path: "/api/v1/auth/me")
    }

    public static func logout() -> Endpoint<EmptyResponse> {
        Endpoint(method: .post, path: "/api/v1/auth/logout")
    }

    public static func registerDevice(_ payload: DeviceRegistration) -> Endpoint<DeviceRegistrationResponse> {
        let body = try? JSONEncoder().encode(payload)
        return Endpoint(method: .post, path: "/api/v1/devices", body: body)
    }

    public static func syncChanges(since: String?, entities: [String], limit: Int = 200) -> Endpoint<ChangeFeed> {
        var query: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(limit)),
        ]
        if let since { query.append(URLQueryItem(name: "since", value: since)) }
        if !entities.isEmpty {
            query.append(URLQueryItem(name: "entities", value: entities.joined(separator: ",")))
        }
        return Endpoint(method: .get, path: "/api/v1/sync/changes", query: query)
    }

    public static func syncMutations(_ batch: MutationBatch) -> Endpoint<MutationResults> {
        let encoder = JSONEncoder()
        let body = try? encoder.encode(batch)
        return Endpoint(method: .post, path: "/api/v1/sync/mutations", body: body)
    }

    public static func presignHorsePhoto(_ payload: PresignRequest) -> Endpoint<PresignResponse> {
        let body = try? JSONEncoder().encode(payload)
        return Endpoint(method: .post, path: "/api/v1/uploads/horse-photos", body: body)
    }
}

public struct MeResponse: Decodable, Sendable {
    public let user: APIUser
    public let tenant: APITenant?
    public let role: String?
}

public struct EmptyResponse: Decodable, Sendable {
    public let ok: Bool?
}
