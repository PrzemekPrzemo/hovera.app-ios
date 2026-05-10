import SwiftUI
import CoreDesignSystem
import SharedFeature

public struct GroomHomeView: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: HoveraTheme.Spacing.m) {
                    Text("groom.intro.offline", bundle: .module)
                        .font(HoveraTheme.Typography.body)
                        .foregroundStyle(HoveraTheme.Colors.textMuted)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(HoveraTheme.Spacing.m)
                        .background(HoveraTheme.Colors.brandPrimary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: HoveraTheme.Radius.card))

                    GroomChecklistRow(title: "groom.task.feeding_morning", icon: "leaf")
                    GroomChecklistRow(title: "groom.task.cleaning", icon: "bubbles.and.sparkles")
                    GroomChecklistRow(title: "groom.task.weight_check", icon: "scalemass")
                }
                .padding(HoveraTheme.Spacing.l)
            }
            .navigationTitle(Text("role.groom.home.title", bundle: .module))
        }
        .hoveraSyncStatus()
    }
}

struct GroomChecklistRow: View {
    let title: LocalizedStringKey
    let icon: String
    @State private var done = false

    var body: some View {
        Button(action: { done.toggle() }) {
            HStack {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(done ? HoveraTheme.Colors.brandPrimary : HoveraTheme.Colors.textMuted)
                    .font(.title2)
                Image(systemName: icon).foregroundStyle(HoveraTheme.Colors.brandSecondary)
                Text(title, bundle: .module)
                    .font(HoveraTheme.Typography.body)
                    .foregroundStyle(HoveraTheme.Colors.textPrimary)
                    .strikethrough(done, color: HoveraTheme.Colors.textMuted)
                Spacer()
            }
            .hoveraCard()
        }
        .buttonStyle(.plain)
    }
}
