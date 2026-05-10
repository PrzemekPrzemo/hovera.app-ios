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

/// Drives the offline-first sync loop. Implementation uses GRDB SQL
/// string interpolation (`db.execute(literal:)`) so every parameter is
/// type-safe through `SQLExpressible` — sidesteps `StatementArguments`
/// array-literal inference issues under Swift 6 strict concurrency.
public actor SyncEngine {
    private let api: APIClient
    private let database: HoveraDatabase
    private let clock: any SyncClock
    private var status: SyncStatus = .idle
    private let conflictContinuation: AsyncStream<ConflictEvent>.Continuation
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
        let bv: Int? = baseVersion

        try await database.queue.write { db in
            try db.execute(literal: """
                INSERT INTO mutation_queue
                  (client_uuid, idempotency_key, entity, op, payload_json,
                   base_version, attempts, next_retry_at, created_at)
                VALUES (\(clientUuid), \(idempotency), \(entity), \(op), \(payloadJson),
                        \(bv), 0, NULL, \(createdAt))
            """)
        }
        return clientUuid
    }

    // MARK: - Pull

    private func pullChanges() async throws {
        var since: String? = try await readCursor()
        var pages = 0
        while pages < 50 {
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
            try PendingMutation.fetchAll(db, literal: """
                SELECT * FROM mutation_queue
                WHERE next_retry_at IS NULL OR next_retry_at <= \(now)
                ORDER BY created_at ASC
                LIMIT 100
            """)
        }
        guard !due.isEmpty else { return }

        var entityByUuid: [String: String] = [:]
        var mutations: [Mutation] = []
        let decoder = JSONDecoder()
        for mut in due {
            entityByUuid[mut.client_uuid] = mut.entity
            guard let payloadData = mut.payload_json.data(using: .utf8),
                  let any = try? decoder.decode(AnyCodable.self, from: payloadData) else {
                continue
            }
            mutations.append(Mutation(
                client_uuid: mut.client_uuid,
                idempotency_key: mut.idempotency_key,
                entity: mut.entity,
                op: mut.op,
                payload: any,
                base_version: mut.base_version
            ))
        }
        guard !mutations.isEmpty else { return }

        let response = try await api.send(
            APIEndpoints.syncMutations(MutationBatch(mutations: mutations))
        )
        let nowForRetry = clock.now()
        let results = response.results

        try await database.queue.write { db in
            for result in results {
                let uuid = result.client_uuid
                switch result.status {
                case "applied", "duplicate", "conflict":
                    try db.execute(literal: """
                        DELETE FROM mutation_queue WHERE client_uuid = \(uuid)
                    """)
                default:
                    let nextRetry = nowForRetry.addingTimeInterval(8)
                    try db.execute(literal: """
                        UPDATE mutation_queue
                        SET attempts = attempts + 1, next_retry_at = \(nextRetry)
                        WHERE client_uuid = \(uuid)
                    """)
                }
            }
        }

        for result in results where result.status == "conflict" {
            let entity = entityByUuid[result.client_uuid] ?? ""
            var messages: [String] = []
            if let errors = result.errors {
                for arr in errors.values { messages.append(contentsOf: arr) }
            }
            conflictContinuation.yield(
                ConflictEvent(
                    clientUuid: result.client_uuid,
                    entity: entity,
                    conflictType: result.conflict_type ?? "unknown",
                    messages: messages
                )
            )
        }
    }

    // MARK: - Cursor

    private static let cursorKey = "changes"

    private func readCursor() async throws -> String? {
        let key = SyncEngine.cursorKey
        return try await database.queue.read { db in
            try String.fetchOne(db, literal: """
                SELECT value FROM sync_cursors WHERE key = \(key) LIMIT 1
            """)
        }
    }

    private func writeCursor(_ value: String) async throws {
        let key = SyncEngine.cursorKey
        try await database.queue.write { db in
            try db.execute(literal: """
                INSERT INTO sync_cursors (key, value) VALUES (\(key), \(value))
                ON CONFLICT(key) DO UPDATE SET value = excluded.value
            """)
        }
    }
}
