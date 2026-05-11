import Foundation
import GRDB

/// Reads typed domain models from the generic `entities` storage — each
/// table stores `payload_json` for the corresponding entity. Repositories
/// decode it lazily; tables are indexed on (sync_version) and (deleted_at)
/// for fast scans.
public actor HorseRepository {
    private let database: HoveraDatabase
    public init(database: HoveraDatabase) { self.database = database }

    public func loadAll() async throws -> [Horse] {
        try await database.queue.read { db in
            let rows = try String.fetchAll(
                db,
                sql: "SELECT payload_json FROM horses WHERE deleted_at IS NULL ORDER BY name COLLATE NOCASE"
            )
            let decoder = JSONDecoder()
            return rows.compactMap { json -> Horse? in
                guard let data = json.data(using: .utf8) else { return nil }
                return try? decoder.decode(Horse.self, from: data)
            }
        }
    }
}

public actor CalendarEntryRepository {
    private let database: HoveraDatabase
    public init(database: HoveraDatabase) { self.database = database }

    public func loadUpcoming(nowIso: String) async throws -> [CalendarEntry] {
        try await database.queue.read { db in
            let rows = try String.fetchAll(
                db,
                sql: "SELECT payload_json FROM calendar_entries WHERE deleted_at IS NULL"
            )
            let decoder = JSONDecoder()
            let entries = rows.compactMap { json -> CalendarEntry? in
                guard let data = json.data(using: .utf8) else { return nil }
                return try? decoder.decode(CalendarEntry.self, from: data)
            }
            return entries
                .filter { ($0.starts_at ?? "") >= nowIso }
                .sorted { ($0.starts_at ?? "") < ($1.starts_at ?? "") }
        }
    }
}

public actor InvoiceRepository {
    private let database: HoveraDatabase
    public init(database: HoveraDatabase) { self.database = database }

    public func loadAll() async throws -> [Invoice] {
        try await database.queue.read { db in
            let rows = try String.fetchAll(
                db,
                sql: "SELECT payload_json FROM invoices WHERE deleted_at IS NULL"
            )
            let decoder = JSONDecoder()
            return rows.compactMap { json -> Invoice? in
                guard let data = json.data(using: .utf8) else { return nil }
                return try? decoder.decode(Invoice.self, from: data)
            }
            .sorted { ($0.issued_at ?? "") > ($1.issued_at ?? "") }
        }
    }
}
