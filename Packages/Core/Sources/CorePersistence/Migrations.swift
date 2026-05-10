import Foundation
import GRDB

enum Migrations {
    static func register(in queue: DatabaseQueue) throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_core") { db in
            try db.create(table: "sync_cursors") { t in
                t.primaryKey("key", .text)
                t.column("value", .text).notNull()
            }
            try db.create(table: "mutation_queue") { t in
                t.primaryKey("client_uuid", .text)
                t.column("idempotency_key", .text).notNull().unique()
                t.column("entity", .text).notNull()
                t.column("op", .text).notNull()
                t.column("payload_json", .text).notNull()
                t.column("base_version", .integer)
                t.column("attempts", .integer).notNull().defaults(to: 0)
                t.column("next_retry_at", .datetime)
                t.column("created_at", .datetime).notNull()
            }
            try db.create(index: "mutation_queue_next_retry_at",
                          on: "mutation_queue", columns: ["next_retry_at"])
        }

        migrator.registerMigration("v1_entities") { db in
            // One generic table per syncable entity. We persist the full
            // payload as JSON + indexed columns we filter on. Apps with
            // heavier query needs can normalise selected entities later.
            for entity in SyncableEntities.all {
                try db.create(table: entity) { t in
                    t.primaryKey("id", .text)
                    t.column("sync_version", .integer).notNull()
                    t.column("updated_at", .datetime)
                    t.column("deleted_at", .datetime)
                    t.column("payload_json", .text).notNull()
                }
                try db.create(index: "\(entity)_sync_version_idx",
                              on: entity, columns: ["sync_version"])
                try db.create(index: "\(entity)_deleted_at_idx",
                              on: entity, columns: ["deleted_at"])
            }
        }

        try migrator.migrate(queue)
    }
}

public enum SyncableEntities {
    public static let all: [String] = [
        "horses", "horse_photos", "horse_documents", "horse_weight_measurements",
        "horse_feeding_plan_items", "horse_messages",
        "calendar_entries", "recurring_calendar_entries", "calendar_entry_participants",
        "arenas", "buildings", "boxes", "box_assignments",
        "clients", "client_messages",
        "instructors", "specialists",
        "passes", "pass_uses",
        "invoices", "invoice_items", "payments",
        "health_records", "treatment_templates",
        "boarding_services", "stable_activities",
        "feed_items", "feed_stock_movements",
    ]
}
