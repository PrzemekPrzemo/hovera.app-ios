import Foundation
import CoreNetworking
import CorePersistence
import CoreAuth

/// Single shared sync engine. Created lazily on first access. Drop
/// @MainActor isolation so AppDelegate's background task handler can
/// call us off the main thread without an extra hop.
public enum SyncEngineProvider {
    public static let shared: SyncEngine = SyncEngine(
        api: APIClient.shared,
        database: HoveraDatabase.shared,
        clock: SystemClock()
    )
}
