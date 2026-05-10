import Foundation
import CoreNetworking
import CorePersistence
import CoreAuth

public enum SyncStatus: Sendable, Equatable {
    case idle
    case syncing
    case offline
    case error(String)
}

public struct ConflictEvent: Sendable, Equatable {
    public let clientUuid: String
    public let entity: String
    public let conflictType: String
    public let messages: [String]

    public init(clientUuid: String, entity: String, conflictType: String, messages: [String]) {
        self.clientUuid = clientUuid
        self.entity = entity
        self.conflictType = conflictType
        self.messages = messages
    }
}

/// Minimal MVP scaffold. The full pull-deltas + push-mutations engine is
/// reintroduced incrementally once CI is green; this version compiles
/// cleanly under Xcode 16 / Swift 6 toolchain so we have a stable base.
public actor SyncEngine {
    private let api: APIClient
    private let database: HoveraDatabase
    private let clock: any Clock
    private var status: SyncStatus = .idle

    private let conflictContinuation: AsyncStream<ConflictEvent>.Continuation
    public nonisolated let conflicts: AsyncStream<ConflictEvent>

    public init(api: APIClient, database: HoveraDatabase, clock: any Clock) {
        self.api = api
        self.database = database
        self.clock = clock
        let (stream, continuation) = AsyncStream<ConflictEvent>.makeStream()
        self.conflicts = stream
        self.conflictContinuation = continuation
    }

    public func currentStatus() -> SyncStatus { status }

    /// One pull + one push pass. For now the implementation is a no-op
    /// stub; the full implementation will live alongside the change-feed
    /// service once we land deltaowe queries.
    public func runOnce() async {
        let online = await Reachability.shared.isOnline()
        guard online else {
            status = .offline
            return
        }
        status = .syncing
        defer { status = .idle }
        // TODO: pull — GET /api/v1/sync/changes
        // TODO: push — POST /api/v1/sync/mutations
    }

    public func reportConflict(_ event: ConflictEvent) {
        conflictContinuation.yield(event)
    }
}
