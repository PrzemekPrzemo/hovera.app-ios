import SwiftUI
import CoreAuth
import CoreDesignSystem
import SharedFeature
import ClientFeature
import InstructorFeature
import GroomFeature
import ManagerFeature

/// Root router. Three states:
///   1. unauthenticated  → LoginView
///   2. signed in but no tenant chosen yet → TenantPickerView
///   3. signed in + tenant active  → RoleHomeView (per role)
struct RootView: View {
    @EnvironmentObject private var session: Session

    var body: some View {
        ZStack {
            HoveraTheme.Colors.brandBackground.ignoresSafeArea()

            switch session.state {
            case .unauthenticated:
                LoginView()
            case .needsTenant:
                TenantPickerView()
            case .ready(let role):
                RoleHomeView(role: role)
            case .loading:
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(HoveraTheme.Colors.brandPrimary)
            }
        }
        .task {
            await session.bootstrap()
        }
    }
}

/// Routes to the per-role landing screen. Roles are determined by the
/// active TenantMembership; the user can switch tenant (and thus role)
/// from the toolbar of any role home.
struct RoleHomeView: View {
    let role: MembershipRole

    var body: some View {
        switch role {
        case .client:
            ClientHomeView()
        case .instructor:
            InstructorHomeView()
        case .groom:
            GroomHomeView()
        case .manager:
            ManagerHomeView()
        case .unknown(let raw):
            UnknownRoleView(raw: raw)
        }
    }
}

private struct UnknownRoleView: View {
    let raw: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(HoveraTheme.Colors.brandSecondary)
            Text("role.unknown.title")
                .font(.headline)
            Text(verbatim: raw)
                .font(.caption)
                .foregroundStyle(HoveraTheme.Colors.textMuted)
        }
        .padding()
    }
}
