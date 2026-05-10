import XCTest
@testable import CoreSync
import CorePersistence

final class CoreSyncSmokeTests: XCTestCase {
    func testSyncableEntitiesCoverAllPlanned() throws {
        // SyncableEntities lives in CorePersistence (single source of
        // truth for the table names that the change feed iterates).
        let expected: Set<String> = [
            "horses", "calendar_entries", "client_messages", "invoices", "horse_messages",
            "passes", "pass_uses", "health_records", "stable_activities",
        ]
        let actual = Set(SyncableEntities.all)
        for entity in expected {
            XCTAssertTrue(actual.contains(entity), "\(entity) missing from SyncableEntities.all")
        }
    }
}
