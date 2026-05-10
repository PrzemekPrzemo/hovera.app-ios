import SwiftUI
import CoreAuth
import CoreSync
import CoreDesignSystem
import SharedFeature

@main
struct HoveraApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var session = Session.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .tint(HoveraTheme.Colors.brandPrimary)
                .preferredColorScheme(.light)
        }
    }
}
