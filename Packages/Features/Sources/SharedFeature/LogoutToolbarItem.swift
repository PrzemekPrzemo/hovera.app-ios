import SwiftUI
import CoreAuth
import CoreDesignSystem

/// Drop-in toolbar item for role home screens. Used to be only inside
/// TenantPickerView; mounting it on each role home gives the user a
/// visible logout entry without backtracking.
public struct LogoutToolbarItem: ToolbarContent {
    @EnvironmentObject private var session: Session

    public init() {}

    public var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                Task { @MainActor in await session.signOut() }
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .foregroundStyle(HoveraTheme.Colors.brandSecondary)
            }
        }
    }
}
