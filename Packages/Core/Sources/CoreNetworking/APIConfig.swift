import Foundation

public struct APIConfig: Sendable {
    public let baseURL: URL
    public let userAgent: String

    public init(baseURL: URL, userAgent: String = "hovera-ios/1.0") {
        self.baseURL = baseURL
        self.userAgent = userAgent
    }

    public static let `default` = APIConfig(
        baseURL: URL(string: ProcessInfo.processInfo.environment["HOVERA_API_BASE_URL"]
            ?? "https://api.hovera.app")!
    )
}
