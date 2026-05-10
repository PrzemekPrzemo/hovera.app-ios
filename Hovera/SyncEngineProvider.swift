import Foundation
import CoreNetworking
import CorePersistence
import CoreAuth

/// Single shared sync engine accessible from AppDelegate (background
/// tasks / silent push) and from feature views (manual refresh).
@MainActor
public enum SyncEngineProvider {
    public static let shared = SyncEngine(
        api: APIClient.shared,
        database: HoveraDatabase.shared,
        clock: SystemClock()
    )
}
