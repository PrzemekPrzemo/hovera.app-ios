import Foundation
import CoreNetworking

/// Uploads a cached APNs device token to the API once the user is signed in
/// and has picked a tenant. Reads from `UserDefaults` keys set by
/// AppDelegate.didRegisterForRemoteNotifications. Failures are swallowed —
/// next launch / token rotation retries.
public actor DeviceTokenUploader {
    public static let shared = DeviceTokenUploader()

    private let tokenKey = "hovera.pending_device_token"
    private let uploadedKey = "hovera.device_token_uploaded"
    private let platformKey = "hovera.pending_device_platform"

    public func uploadIfPending() async {
        let defaults = UserDefaults.standard
        guard let token = defaults.string(forKey: tokenKey), !token.isEmpty else { return }
        if defaults.bool(forKey: uploadedKey) { return }
        let platform = defaults.string(forKey: platformKey) ?? "ios"
        let locale = Locale.current.identifier
        let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0.0"

        let payload = DeviceRegistration(
            platform: platform,
            token: token,
            locale: locale,
            app_version: appVersion
        )
        do {
            _ = try await APIClient.shared.send(APIEndpoints.registerDevice(payload))
            defaults.set(true, forKey: uploadedKey)
        } catch {
            // Silent — retry on next launch / next tenant pick.
        }
    }

    public func reset() {
        UserDefaults.standard.set(false, forKey: uploadedKey)
    }
}
