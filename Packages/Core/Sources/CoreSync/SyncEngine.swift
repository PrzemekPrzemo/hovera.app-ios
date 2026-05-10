import Foundation
import CoreNetworking
import CorePersistence
import CoreAuth
import GRDB

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

/// Drives the offline-first sync loop. `runOnce()` performs at most one
/// pull (GET /api/v1/sync/changes paginated until has_more=false) and one
/// push (POST /api/v1/sync/mutations draining the local mutation_queue
/// with exponential backoff on transient failures).
///
/// Swift 6 isolation rules: every value crossing into a @Sendable closure
/// (GRDB transaction blocks, Task bodies) is read into a local `let`
/// first — we never capture `self.X` from inside @Sendable.
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

    /// Enqueue a local mutation for the next push pass. Returns the
    /// generated client_uuid so callers can correlate with conflict events.
    public func enqueueMutation(
        entity: String,
        op: String,
        payloadJson: String,
        baseVersion: Int? = nil
    ) async throws -> String {
        let clientUuid = UUID().uuidString
        let device = await DeviceIdentifier.current()
        let idempotency = "\(device):\(clientUuid):\(op)"
        let createdAt = clock.now()

        try await database.queue.write { db in
            var record = PendingMutation(
                client_uuid: clientUuid,
                idempotency_key: idempotency,
                entity: entity,
                op: op,
                payload_json: payloadJson,
                base_version: baseVersion,
                attempts: 0,
                next_retry_at: nil,
                created_at: createdAt
            )
            try record.insert(db)
        }
        return clientUuid
    }

    // MARK: - Pull

    private func pullChanges() async throws {
        var since: String? = try await readCursor()
        var pages = 0
        while pages < 50 {  // safety cap: 50 pages × 200 rows = 10k per runOnce
            pages += 1
            let endpoint = APIEndpoints.syncChanges(since: since, entities: [], limit: 200)
            let feed = try await api.send(endpoint)
            try await applyChanges(feed.changes)
            try await writeCursor(feed.cursor)
            since = feed.cursor
            if !feed.has_more { break }
        }
    }

    private func applyChanges(_ changes: [Change]) async throws {
        try await database.queue.write { db in
            let encoder = JSONEncoder()
            for change in changes {
                let table = change.entity
                guard SyncableEntities.all.contains(table) else { continue }
                if change.op == "delete" {
                    try EntityStore.tombstone(
                        in: db, table: table, id: change.id,
                        syncVersion: change.sync_version, updatedAt: change.updated_at
                    )
                } else {
                    let payloadJson: String
                    if let payload = change.payload,
                       let data = try? encoder.encode(payload),
                       let s = String(data: data, encoding: .utf8) {
                        payloadJson = s
                    } else {
                        payloadJson = "{}"
                    }
                    try EntityStore.upsert(in: db, table: table, change: ChangeRow(
                        id: change.id, syncVersion: change.sync_version,
                        updatedAt: change.updated_at, payloadJson: payloadJson
                    ))
                }
            }
        }
    }

    // MARK: - Push

    private func pushMutations() async throws {
        let now = clock.now()
        let due: [PendingMutation] = try await database.queue.read { db in
            // Raw SQL filter sidesteps Swift 6 operator-resolution ambiguity
            // around `Column(...) == nil || Column(...) <= now`.
            try PendingMutation
                .filter(sql: "next_retry_at IS NULL OR next_retry_at <= ?", arguments: [now])
                .order(Column("created_at"))
                .limit(100)
                .fetchAll(db)
        }
        guard !due.isEmpty else { return }

        let mutations: [Mutation] = due.compactMap { mut in
            guard let payloadData = mut.payload_json.data(using: .utf8),
                  let any = try? JSONDecoder().decode(AnyCodable.self, from: payloadData) else {
                return nil
            }
            return Mutation(
                client_uuid: mut.client_uuid,
                idempotency_key: mut.idempotency_key,
                entity: mut.entity,
                op: mut.op,
                payload: any,
                base_version: mut.base_version
            )
        }
        guard !mutations.isEmpty else { return }

        let response = try await api.send(APIEndpoints.syncMutations(MutationBatch(mutations: mutations)))
        let nowForRetry = clock.now()
        let dueByUuid: [String: String] = Dictionary(
            uniqueKeysWithValues: due.map { ($0.client_uuid, $0.entity) }
        )

        try await database.queue.write { db in
            for result in response.results {
                switch result.status {
                case "applied", "duplicate":
                    try PendingMutation
                        .filter(Column("client_uuid") == result.client_uuid)
                        .deleteAll(db)
                case "conflict":
                    try PendingMutation
                        .filter(Column("client_uuid") == result.client_uuid)
                        .deleteAll(db)
                default:
                    if var record = try PendingMutation
                        .filter(Column("client_uuid") == result.client_uuid)
                        .fetchOne(db) {
                        record.attempts += 1
                        let backoffSeconds = min(pow(2.0, Double(record.attempts)), 300)
                        record.next_retry_at = nowForRetry.addingTimeInterval(backoffSeconds)
                        try record.update(db)
                    }
                }
            }
        }

        // Surface conflicts AFTER the DB transaction so subscribers observe
        // a consistent state. Continuation is `let` (not actor-isolated),
        // safe to call from any context.
        for result in response.results where result.status == "conflict" {
            let entity = dueByUuid[result.client_uuid] ?? ""
            conflictContinuation.yield(
                ConflictEvent(
                    clientUuid: result.client_uuid,
                    entity: entity,
                    conflictType: result.conflict_type ?? "unknown",
                    messages: result.errors?.values.flatMap { $0 } ?? []
                )
            )
        }
    }

    // MARK: - Cursor

    private static let cursorKey = "changes"

    private func readCursor() async throws -> String? {
        try await database.queue.read { db in
            try SyncCursor.filter(Column("key") == Self.cursorKey).fetchOne(db)?.value
        }
    }

    private func writeCursor(_ value: String) async throws {
        try await database.queue.write { db in
            var record = SyncCursor(key: Self.cursorKey, value: value)
            try record.save(db)
        }
    }
}
