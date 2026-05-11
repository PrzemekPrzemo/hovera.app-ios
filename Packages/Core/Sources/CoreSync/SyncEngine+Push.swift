import Foundation
import CoreNetworking
import CorePersistence
import CoreAuth
import GRDB

extension SyncEngine {
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
        let baseVer = baseVersion

        try await database.queue.write { db in
            var record = PendingMutation(
                client_uuid: clientUuid,
                idempotency_key: idempotency,
                entity: entity,
                op: op,
                payload_json: payloadJson,
                base_version: baseVer,
                attempts: 0,
                next_retry_at: nil,
                created_at: createdAt
            )
            try record.insert(db)
        }
        return clientUuid
    }

    /// Drain `mutation_queue`: POST batch to /api/v1/sync/mutations,
    /// delete applied/duplicate/conflict rows, bump attempts on transient
    /// failures with exponential backoff. Conflicts surface to
    /// `conflictContinuation`.
    func pushMutations() async throws {
        let now = clock.now()
        let due: [PendingMutation] = try await database.queue.read { db in
            try PendingMutation.fetchAll(
                db,
                sql: "SELECT * FROM mutation_queue WHERE next_retry_at IS NULL OR next_retry_at <= ? ORDER BY created_at ASC LIMIT 100",
                arguments: [now]
            )
        }
        guard !due.isEmpty else { return }

        var entityByUuid: [String: String] = [:]
        var mutations: [Mutation] = []
        let decoder = JSONDecoder()
        for mut in due {
            entityByUuid[mut.client_uuid] = mut.entity
            guard let data = mut.payload_json.data(using: .utf8),
                  let any = try? decoder.decode(AnyCodable.self, from: data) else {
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
                    try db.execute(
                        sql: "DELETE FROM mutation_queue WHERE client_uuid = ?",
                        arguments: [uuid]
                    )
                default:
                    // Read attempts, bump, schedule retry with exponential
                    // backoff capped at 5 minutes.
                    let currentAttempts: Int = (try Int.fetchOne(
                        db,
                        sql: "SELECT attempts FROM mutation_queue WHERE client_uuid = ?",
                        arguments: [uuid]
                    )) ?? 0
                    let newAttempts = currentAttempts + 1
                    let backoffSeconds = min(pow(2.0, Double(newAttempts)), 300)
                    let nextRetry = nowForRetry.addingTimeInterval(backoffSeconds)
                    try db.execute(
                        sql: "UPDATE mutation_queue SET attempts = ?, next_retry_at = ? WHERE client_uuid = ?",
                        arguments: [newAttempts, nextRetry, uuid]
                    )
                }
            }
        }

        // Surface conflicts AFTER the DB transaction commits.
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
}
