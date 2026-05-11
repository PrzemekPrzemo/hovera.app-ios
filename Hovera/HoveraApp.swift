import SwiftUI
import CoreAuth
import CoreSync
import CoreDesignSystem
import SharedFeature

@main
struct HoveraApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var session = Session.shared

    init() {
        // Wire the SharedFeature shim so SyncStatusPill reflects real engine
        // status without SharedFeature having to depend on the app target.
        SyncEngineProviderShim.statusProvider = {
            await SyncEngineProvider.shared.currentStatus()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .tint(HoveraTheme.Colors.brandPrimary)
                .preferredColorScheme(.light)
        }
    }
}
