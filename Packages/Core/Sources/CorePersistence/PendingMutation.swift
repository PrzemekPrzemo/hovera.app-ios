import Foundation
import GRDB

public struct PendingMutation: Codable, Sendable, FetchableRecord, MutablePersistableRecord {
    public var client_uuid: String
    public var idempotency_key: String
    public var entity: String
    public var op: String
    public var payload_json: String
    public var base_version: Int?
    public var attempts: Int
    public var next_retry_at: Date?
    public var created_at: Date

    public static var databaseTableName: String { "mutation_queue" }

    public init(
        client_uuid: String, idempotency_key: String,
        entity: String, op: String, payload_json: String,
        base_version: Int? = nil, attempts: Int = 0,
        next_retry_at: Date? = nil, created_at: Date = Date()
    ) {
        self.client_uuid = client_uuid
        self.idempotency_key = idempotency_key
        self.entity = entity
        self.op = op
        self.payload_json = payload_json
        self.base_version = base_version
        self.attempts = attempts
        self.next_retry_at = next_retry_at
        self.created_at = created_at
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        // No-op — client_uuid is the PK and is set by the caller.
    }
}

public struct SyncCursor: Codable, Sendable, FetchableRecord, MutablePersistableRecord {
    public var key: String
    public var value: String
    public static var databaseTableName: String { "sync_cursors" }
}
