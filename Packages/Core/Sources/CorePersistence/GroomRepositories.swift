import Foundation
import GRDB

public actor StableActivityRepository {
    private let database: HoveraDatabase
    public init(database: HoveraDatabase) { self.database = database }

    public func loadAll() async throws -> [StableActivity] {
        try await database.queue.read { db in
            let rows = try String.fetchAll(
                db,
                sql: "SELECT payload_json FROM stable_activities WHERE deleted_at IS NULL"
            )
            let decoder = JSONDecoder()
            return rows.compactMap { json -> StableActivity? in
                guard let data = json.data(using: .utf8) else { return nil }
                return try? decoder.decode(StableActivity.self, from: data)
            }
            .sorted { ($0.due_at ?? "") < ($1.due_at ?? "") }
        }
    }

    public func loadPendingToday(startIso: String, endIso: String) async throws -> [StableActivity] {
        let all = try await loadAll()
        return all.filter { activity in
            guard let due = activity.due_at else { return activity.status != "completed" }
            return due >= startIso && due <= endIso && activity.status != "completed"
        }
    }

    /// Optimistic local update of an activity row. Persists immediately so the
    /// checklist UI feels responsive, separately from the eventual sync push.
    public func setStatus(_ activity: StableActivity, to newStatus: String, completedAt: String?) async throws {
        let id = activity.id
        let payloadDict: [String: Any?] = [
            "id": activity.id,
            "kind": activity.kind,
            "title": activity.title,
            "description": activity.description,
            "status": newStatus,
            "due_at": activity.due_at,
            "completed_at": completedAt,
            "horse_id": activity.horse_id,
            "assigned_to_user_id": activity.assigned_to_user_id,
            "notes": activity.notes,
        ]
        let cleaned = payloadDict.compactMapValues { $0 }
        let data = try JSONSerialization.data(withJSONObject: cleaned)
        let json = String(data: data, encoding: .utf8) ?? "{}"

        try await database.queue.write { db in
            try db.execute(
                sql: "UPDATE stable_activities SET payload_json = ? WHERE id = ?",
                arguments: [json, id]
            )
        }
    }
}

public actor HorseWeightRepository {
    private let database: HoveraDatabase
    public init(database: HoveraDatabase) { self.database = database }

    public func loadAll() async throws -> [HorseWeightMeasurement] {
        try await database.queue.read { db in
            let rows = try String.fetchAll(
                db,
                sql: "SELECT payload_json FROM horse_weight_measurements WHERE deleted_at IS NULL"
            )
            let decoder = JSONDecoder()
            return rows.compactMap { json -> HorseWeightMeasurement? in
                guard let data = json.data(using: .utf8) else { return nil }
                return try? decoder.decode(HorseWeightMeasurement.self, from: data)
            }
            .sorted { ($0.measurement_date ?? "") > ($1.measurement_date ?? "") }
        }
    }

    public func loadForHorse(_ horseId: String) async throws -> [HorseWeightMeasurement] {
        try await loadAll().filter { $0.horse_id == horseId }
    }
}
