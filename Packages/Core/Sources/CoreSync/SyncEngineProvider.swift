import Foundation
import CoreNetworking
import CorePersistence
import CoreAuth

/// Single shared sync engine. Moved from the app target into CoreSync so
/// feature packages (which can't import the app) can call into it through
/// CoreSync — GroomFeature in particular needs `enqueueMutation` for
/// optimistic check-offs from the home screen.
public enum SyncEngineProvider {
    public static let shared: SyncEngine = SyncEngine(
        api: APIClient.shared,
        database: HoveraDatabase.shared,
        clock: SystemSyncClock()
    )
}
