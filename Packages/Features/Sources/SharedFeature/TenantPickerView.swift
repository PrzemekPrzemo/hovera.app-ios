import SwiftUI
import CoreAuth
import CoreDesignSystem

public struct TenantPickerView: View {
    @EnvironmentObject private var session: Session

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: HoveraTheme.Spacing.m) {
            HoveraBrandHeader()
                .padding(.bottom, HoveraTheme.Spacing.s)
            Text("tenant.picker.title")
                .font(HoveraTheme.Typography.heading)
                .foregroundStyle(HoveraTheme.Colors.brandSecondary)

            if session.memberships.isEmpty {
                HoveraEmptyState(title: "tenant.picker.title", icon: "building.2")
            } else {
                ScrollView {
                    VStack(spacing: HoveraTheme.Spacing.m) {
                        ForEach(session.memberships) { membership in
                            Button(action: { Task { await session.pickTenant(membership) } }) {
                                tenantRow(membership)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Button(action: { Task { await session.signOut() } }) {
                Text("common.logout")
            }
            .buttonStyle(HoveraSecondaryButtonStyle())
            .padding(.top, HoveraTheme.Spacing.l)
        }
        .padding(HoveraTheme.Spacing.l)
    }

    @ViewBuilder
    private func tenantRow(_ m: Session.Membership) -> some View {
        HStack {
            Circle()
                .fill(HoveraTheme.Colors.brandPrimary)
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(m.tenantName.prefix(1)))
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(m.tenantName)
                    .font(HoveraTheme.Typography.heading)
                    .foregroundStyle(HoveraTheme.Colors.textPrimary)
                Text(verbatim: roleLabel(m.role))
                    .font(HoveraTheme.Typography.caption)
                    .foregroundStyle(HoveraTheme.Colors.textMuted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(HoveraTheme.Colors.textMuted)
        }
        .hoveraCard()
    }

    private func roleLabel(_ role: MembershipRole) -> String {
        switch role {
        case .client: return "Klient"
        case .instructor: return "Instruktor"
        case .groom: return "Stajenny"
        case .manager: return "Manager"
        case .unknown(let raw): return raw
        }
    }
}
