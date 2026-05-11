import XCTest
@testable import CoreSync
import CorePersistence

final class CoreSyncSmokeTests: XCTestCase {
    func testSyncableEntitiesCoverAllPlanned() throws {
        let expected: Set<String> = [
            "horses", "calendar_entries", "client_messages", "invoices", "horse_messages",
            "passes", "pass_uses", "health_records", "stable_activities",
        ]
        let actual = Set(SyncableEntities.all)
        for entity in expected {
            XCTAssertTrue(actual.contains(entity), "\(entity) missing from SyncableEntities.all")
        }
    }

    func testSyncStatusEquality() {
        XCTAssertEqual(SyncStatus.idle, SyncStatus.idle)
        XCTAssertNotEqual(SyncStatus.idle, SyncStatus.syncing)
        XCTAssertEqual(SyncStatus.error("x"), SyncStatus.error("x"))
        XCTAssertNotEqual(SyncStatus.error("x"), SyncStatus.error("y"))
    }

    func testConflictEventEquality() {
        let a = ConflictEvent(clientUuid: "1", entity: "horses", conflictType: "lww", messages: ["x"])
        let b = ConflictEvent(clientUuid: "1", entity: "horses", conflictType: "lww", messages: ["x"])
        let c = ConflictEvent(clientUuid: "1", entity: "horses", conflictType: "lww", messages: [])
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }
}
