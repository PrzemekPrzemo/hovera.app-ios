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

/// Minimal core. Pull / push live in `SyncEngine+Pull.swift` and
/// `SyncEngine+Push.swift` so a compile error there doesn't take down
/// the whole module (and so each piece can be debugged in isolation).
public actor SyncEngine {
    let api: APIClient
    let database: HoveraDatabase
    let clock: any SyncClock
    var status: SyncStatus = .idle
    let conflictContinuation: AsyncStream<ConflictEvent>.Continuation
    public nonisolated let conflicts: AsyncStream<ConflictEvent>

    public init(api: APIClient, database: HoveraDatabase, clock: any SyncClock) {
        self.api = api
        self.database = database
        self.clock = clock
        let (stream, continuation) = AsyncStream<ConflictEvent>.makeStream()
        self.conflicts = stream
        self.conflictContinuation = continuation
    }

    public func currentStatus() -> SyncStatus { status }

    public func runOnce() async {
        let online = await Reachability.shared.isOnline()
        guard online else {
            status = .offline
            return
        }
        status = .syncing
        do {
            try await pullChanges()
            try await pushMutations()
            status = .idle
        } catch {
            status = .error(String(describing: error))
        }
    }

    public func reportConflict(_ event: ConflictEvent) {
        conflictContinuation.yield(event)
    }
}
