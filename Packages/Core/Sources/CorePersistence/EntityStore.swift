import Foundation
import GRDB

public struct EntityRow: Codable, FetchableRecord, MutablePersistableRecord {
    public var id: String
    public var sync_version: Int
    public var updated_at: Date?
    public var deleted_at: Date?
    public var payload_json: String

    public static var databaseTableName: String { "" } // overridden by table name in queries
}

/// Lightweight type-erased upsert/delete API used by the change applier.
/// Avoids generating a struct per entity at this stage — features query
/// rows by their JSON payload via small projection helpers below.
public enum EntityStore {
    public static func upsert(in db: Database, table: String, change: ChangeRow) throws {
        try db.execute(sql: """
            INSERT INTO \(quote(table)) (id, sync_version, updated_at, deleted_at, payload_json)
            VALUES (?, ?, ?, NULL, ?)
            ON CONFLICT(id) DO UPDATE SET
              sync_version = excluded.sync_version,
              updated_at = excluded.updated_at,
              deleted_at = NULL,
              payload_json = excluded.payload_json
        """, arguments: [change.id, change.syncVersion, change.updatedAt, change.payloadJson])
    }

    public static func tombstone(in db: Database, table: String, id: String,
                                 syncVersion: Int, updatedAt: Date?) throws {
        try db.execute(sql: """
            INSERT INTO \(quote(table)) (id, sync_version, updated_at, deleted_at, payload_json)
            VALUES (?, ?, ?, ?, '{}')
            ON CONFLICT(id) DO UPDATE SET
              sync_version = excluded.sync_version,
              updated_at = excluded.updated_at,
              deleted_at = excluded.updated_at
        """, arguments: [id, syncVersion, updatedAt, updatedAt ?? Date()])
    }

    public static func count(in db: Database, table: String) throws -> Int {
        try Int.fetchOne(db, sql: "SELECT count(*) FROM \(quote(table)) WHERE deleted_at IS NULL") ?? 0
    }

    private static func quote(_ ident: String) -> String { "`\(ident.replacingOccurrences(of: "`", with: ""))`" }
}

public struct ChangeRow: Sendable {
    public let id: String
    public let syncVersion: Int
    public let updatedAt: Date?
    public let payloadJson: String
    public init(id: String, syncVersion: Int, updatedAt: Date?, payloadJson: String) {
        self.id = id
        self.syncVersion = syncVersion
        self.updatedAt = updatedAt
        self.payloadJson = payloadJson
    }
}
