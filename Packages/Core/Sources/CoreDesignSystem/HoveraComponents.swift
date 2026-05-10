import SwiftUI

public struct HoveraPrimaryButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: HoveraTheme.Radius.card, style: .continuous)
                    .fill(HoveraTheme.Colors.brandPrimary.opacity(configuration.isPressed ? 0.85 : 1))
            )
    }
}

public struct HoveraSecondaryButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(HoveraTheme.Colors.brandSecondary)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: HoveraTheme.Radius.card, style: .continuous)
                    .stroke(HoveraTheme.Colors.brandSecondary.opacity(0.4), lineWidth: 1)
            )
    }
}

public struct HoveraCardModifier: ViewModifier {
    public init() {}
    public func body(content: Content) -> some View {
        content
            .padding(HoveraTheme.Spacing.m)
            .background(HoveraTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HoveraTheme.Radius.card, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

public extension View {
    func hoveraCard() -> some View { modifier(HoveraCardModifier()) }
}

public struct HoveraEmptyState: View {
    let title: LocalizedStringKey
    let icon: String

    public init(title: LocalizedStringKey, icon: String = "tray") {
        self.title = title
        self.icon = icon
    }

    public var body: some View {
        VStack(spacing: HoveraTheme.Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(HoveraTheme.Colors.brandSecondary.opacity(0.5))
            Text(title)
                .font(HoveraTheme.Typography.heading)
                .foregroundStyle(HoveraTheme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

public struct HoveraBrandHeader: View {
    public init() {}
    public var body: some View {
        Text("hovera")
            .font(.system(size: 40, weight: .bold, design: .serif))
            .foregroundStyle(HoveraTheme.Colors.brandSecondary)
            .accessibilityAddTraits(.isHeader)
    }
}
