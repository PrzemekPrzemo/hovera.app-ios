import Foundation

/// Uploads a cached APNs device token to the API once the user is signed in.
/// Reads token + platform from UserDefaults (set by
/// AppDelegate.didRegisterForRemoteNotifications via
/// Session.registerDeviceToken). Idempotent via a single boolean flag.
/// Lives in CoreNetworking so it can reach `APIClient` and `APIEndpoints`
/// directly without a circular dep into CoreAuth.
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
