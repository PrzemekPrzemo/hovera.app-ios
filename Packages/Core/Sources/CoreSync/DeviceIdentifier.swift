import Foundation
import UIKit

/// Reads `UIDevice.identifierForVendor` on the main actor, exposes
/// the result as a vanilla async function so SyncEngine can call it
/// without importing UIKit (which would otherwise force a UIKit
/// dependency on every target that imports CoreSync transitively).
public enum DeviceIdentifier {
    public static func current() async -> String {
        await MainActor.run {
            UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        }
    }
}
