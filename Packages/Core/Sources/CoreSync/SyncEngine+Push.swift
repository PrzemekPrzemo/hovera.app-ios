import Foundation
import CoreNetworking
import CorePersistence
import CoreAuth
import GRDB

extension SyncEngine {
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
        let bv = baseVersion
        try await database.queue.write { db in
            try db.execute(
                sql: "INSERT INTO mutation_queue (client_uuid, idempotency_key, entity, op, payload_json, base_version, attempts, next_retry_at, created_at) VALUES (?, ?, ?, ?, ?, ?, 0, NULL, ?)",
                arguments: [clientUuid, idempotency, entity, op, payloadJson, bv, createdAt]
            )
        }
        return clientUuid
    }

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

        let response = try await api.send(APIEndpoints.syncMutations(MutationBatch(mutations: mutations)))
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
                    let nextRetry = nowForRetry.addingTimeInterval(8)
                    try db.execute(
                        sql: "UPDATE mutation_queue SET attempts = attempts + 1, next_retry_at = ? WHERE client_uuid = ?",
                        arguments: [nextRetry, uuid]
                    )
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
}
