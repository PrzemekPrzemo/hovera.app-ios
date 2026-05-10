import SwiftUI
import CoreDesignSystem
import SharedFeature

public struct ClientHomeView: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HoveraTheme.Spacing.l) {
                    sectionHeader("client.section.next_lesson")
                    PlaceholderCard(
                        title: "client.next_lesson.title",
                        subtitle: "client.next_lesson.subtitle",
                        icon: "calendar"
                    )

                    sectionHeader("client.section.my_horses")
                    PlaceholderCard(
                        title: "client.my_horses.title",
                        subtitle: "client.my_horses.subtitle",
                        icon: "figure.equestrian.sports"
                    )

                    sectionHeader("client.section.invoices")
                    PlaceholderCard(
                        title: "client.invoices.title",
                        subtitle: "client.invoices.subtitle",
                        icon: "doc.text"
                    )
                }
                .padding(HoveraTheme.Spacing.l)
            }
            .navigationTitle(Text("role.client.home.title", bundle: .module))
            .toolbarBackground(HoveraTheme.Colors.brandBackground, for: .navigationBar)
        }
        .hoveraSyncStatus()
    }

    @ViewBuilder
    private func sectionHeader(_ key: LocalizedStringKey) -> some View {
        Text(key, bundle: .module)
            .font(HoveraTheme.Typography.heading)
            .foregroundStyle(HoveraTheme.Colors.brandSecondary)
    }
}

struct PlaceholderCard: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: HoveraTheme.Spacing.m) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(HoveraTheme.Colors.brandPrimary)
                .frame(width: 40, height: 40)
                .background(
                    Circle().fill(HoveraTheme.Colors.brandPrimary.opacity(0.12))
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(title, bundle: .module)
                    .font(HoveraTheme.Typography.heading)
                Text(subtitle, bundle: .module)
                    .font(HoveraTheme.Typography.body)
                    .foregroundStyle(HoveraTheme.Colors.textMuted)
            }
            Spacer()
        }
        .hoveraCard()
    }
}
