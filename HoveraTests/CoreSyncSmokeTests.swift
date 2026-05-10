import XCTest
@testable import CoreSync

final class CoreSyncSmokeTests: XCTestCase {
    func testSyncableEntitiesCoverAllPlanned() throws {
        // Sanity: make sure we registered all entities the API exposes.
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
