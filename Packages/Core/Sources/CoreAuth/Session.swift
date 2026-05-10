import Foundation
import Combine

public enum MembershipRole: Sendable, Hashable {
    case client, instructor, groom, manager
    case unknown(String)

    public init(raw: String) {
        switch raw.lowercased() {
        case "client", "owner": self = .client
        case "instructor": self = .instructor
        case "groom", "staff": self = .groom
        case "manager", "admin": self = .manager
        default: self = .unknown(raw)
        }
    }
}

public enum SessionState: Sendable, Equatable {
    case loading
    case unauthenticated
    case needsTenant
    case ready(MembershipRole)
}

/// Single source of truth for the auth/tenant lifecycle. Owned by the
/// app target; feature views read it via @EnvironmentObject and call
/// `signIn(email:password:)` / `pickTenant(_:)` / `signOut()`.
@MainActor
public final class Session: ObservableObject {
    public static let shared = Session()

    @Published public private(set) var state: SessionState = .loading
    @Published public private(set) var memberships: [Membership] = []
    @Published public private(set) var activeTenantId: String?
    @Published public private(set) var lastError: String?

    public struct Membership: Identifiable, Sendable, Hashable {
        public let id: String           // tenant id
        public let tenantName: String
        public let brandColorHex: String?
        public let role: MembershipRole
    }

    public init() {}

    /// Hydrate from Keychain on launch.
    public func bootstrap() async {
        let token = await KeychainStore.shared.token()
        let tenantId = await KeychainStore.shared.activeTenantId()
        switch (token, tenantId) {
        case (nil, _): state = .unauthenticated
        case (_, nil): state = .needsTenant
        case (_, _):
            // We trust cached membership info; SyncEngine will refresh it.
            // If memberships happen to be empty (cold install), bounce to picker.
            if memberships.isEmpty {
                state = .needsTenant
            } else if let m = memberships.first(where: { $0.id == tenantId }) {
                state = .ready(m.role)
            } else {
                state = .needsTenant
            }
        }
    }

    public func signIn(
        email: String,
        password: String,
        loginAction: @Sendable (String, String) async throws -> (token: String, memberships: [Membership])
    ) async {
        do {
            state = .loading
            let (token, fetched) = try await loginAction(email, password)
            await KeychainStore.shared.setToken(token)
            self.memberships = fetched
            if fetched.count == 1 {
                await pickTenant(fetched[0])
            } else {
                state = .needsTenant
            }
        } catch {
            lastError = String(describing: error)
            state = .unauthenticated
        }
    }

    public func pickTenant(_ membership: Membership) async {
        await KeychainStore.shared.setActiveTenantId(membership.id)
        activeTenantId = membership.id
        state = .ready(membership.role)
    }

    public func registerDeviceToken(_ token: String, platform: String) async {
        // Wired up from AppDelegate after APNs registration. The actual
        // POST /api/v1/devices call lives in SharedFeature so it can use
        // the APIClient (CoreAuth must not depend on CoreNetworking).
        UserDefaults.standard.set(token, forKey: "hovera.pending_device_token")
        UserDefaults.standard.set(platform, forKey: "hovera.pending_device_platform")
    }

    public func signOut() async {
        await KeychainStore.shared.wipe()
        memberships = []
        activeTenantId = nil
        state = .unauthenticated
    }
}
