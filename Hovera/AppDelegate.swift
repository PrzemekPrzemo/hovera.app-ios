import UIKit
import BackgroundTasks
import UserNotifications
import CoreSync
import CoreAuth

/// Bridges iOS lifecycle hooks that SwiftUI's App protocol does not expose:
/// APNs token registration, silent push handoff to the sync engine, and
/// BGTaskScheduler registration for periodic background sync.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self

        BackgroundSync.registerTask(identifier: "app.hovera.sync") {
            await SyncEngineProvider.shared.runOnce()
        }

        // Ask for notification permission lazily — only once the user is
        // signed in. The actual call lives in SharedFeature/RootView.
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task { await Session.shared.registerDeviceToken(token, platform: "ios") }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Non-fatal — the app still works without push, just won't get
        // wake-ups for remote changes.
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Silent push (`content-available: 1`) → trigger one sync cycle.
        Task {
            await SyncEngineProvider.shared.runOnce()
            completionHandler(.newData)
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
