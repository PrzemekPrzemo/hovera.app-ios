import Foundation
import GRDB

public actor ClientRepository {
    private let database: HoveraDatabase
    public init(database: HoveraDatabase) { self.database = database }
    public func loadAll() async throws -> [Client] {
        try await database.queue.read { db in
            let rows = try String.fetchAll(db, sql: "SELECT payload_json FROM clients WHERE deleted_at IS NULL")
            let decoder = JSONDecoder()
            return rows.compactMap { json -> Client? in
                guard let data = json.data(using: .utf8) else { return nil }
                return try? decoder.decode(Client.self, from: data)
            }
            .sorted { ($0.name ?? "").lowercased() < ($1.name ?? "").lowercased() }
        }
    }
}

public actor BoxRepository {
    private let database: HoveraDatabase
    public init(database: HoveraDatabase) { self.database = database }
    public func loadAll() async throws -> [StableBox] {
        try await database.queue.read { db in
            let rows = try String.fetchAll(db, sql: "SELECT payload_json FROM boxes WHERE deleted_at IS NULL")
            let decoder = JSONDecoder()
            return rows.compactMap { json -> StableBox? in
                guard let data = json.data(using: .utf8) else { return nil }
                return try? decoder.decode(StableBox.self, from: data)
            }
            .sorted { ($0.number ?? $0.name ?? "") < ($1.number ?? $1.name ?? "") }
        }
    }
}

public actor BoxAssignmentRepository {
    private let database: HoveraDatabase
    public init(database: HoveraDatabase) { self.database = database }
    public func loadActive(nowIso: String) async throws -> [BoxAssignment] {
        try await database.queue.read { db in
            let rows = try String.fetchAll(db, sql: "SELECT payload_json FROM box_assignments WHERE deleted_at IS NULL")
            let decoder = JSONDecoder()
            return rows.compactMap { json -> BoxAssignment? in
                guard let data = json.data(using: .utf8) else { return nil }
                return try? decoder.decode(BoxAssignment.self, from: data)
            }
            .filter { ($0.to_date ?? "9999") >= nowIso }
        }
    }
}
