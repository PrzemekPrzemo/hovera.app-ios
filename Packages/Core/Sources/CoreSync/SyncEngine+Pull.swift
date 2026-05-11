import Foundation
import CoreNetworking
import CorePersistence
import GRDB

extension SyncEngine {
    func pullChanges() async throws {
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

    private static let cursorKey = "changes"

    func readCursor() async throws -> String? {
        let key = SyncEngine.cursorKey
        return try await database.queue.read { db in
            try String.fetchOne(db, sql: "SELECT value FROM sync_cursors WHERE key = ? LIMIT 1", arguments: [key])
        }
    }

    func writeCursor(_ value: String) async throws {
        let key = SyncEngine.cursorKey
        try await database.queue.write { db in
            try db.execute(
                sql: "INSERT INTO sync_cursors (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value",
                arguments: [key, value]
            )
        }
    }
}
