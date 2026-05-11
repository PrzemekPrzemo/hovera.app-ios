import Foundation
import CoreNetworking
import CorePersistence
import CoreAuth
import CoreSync

/// Single shared sync engine. Created lazily on first access.
public enum SyncEngineProvider {
    public static let shared: SyncEngine = SyncEngine(
        api: APIClient.shared,
        database: HoveraDatabase.shared,
        clock: SystemSyncClock()
    )
}
