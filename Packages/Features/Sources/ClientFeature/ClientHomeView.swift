import SwiftUI
import CoreDesignSystem
import CorePersistence
import SharedFeature

public struct ClientHomeView: View {
    @State private var viewModel = ClientHomeViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HoveraTheme.Spacing.l) {
                    sectionHeader("client.section.next_lesson")
                    NextLessonCard(entry: viewModel.nextLesson)

                    sectionHeader("client.section.my_horses")
                    if viewModel.horses.isEmpty {
                        PlaceholderCard(
                            title: "client.my_horses.empty.title",
                            subtitle: "client.my_horses.empty.subtitle",
                            icon: "figure.equestrian.sports"
                        )
                    } else {
                        ForEach(viewModel.horses) { HorseCard(horse: $0) }
                    }

                    sectionHeader("client.section.invoices")
                    if viewModel.invoices.isEmpty {
                        PlaceholderCard(
                            title: "client.invoices.empty.title",
                            subtitle: "client.invoices.empty.subtitle",
                            icon: "doc.text"
                        )
                    } else {
                        ForEach(Array(viewModel.invoices.prefix(5))) { InvoiceCard(invoice: $0) }
                    }
                }
                .padding(HoveraTheme.Spacing.l)
            }
            .navigationTitle(Text("role.client.home.title"))
            .toolbarBackground(HoveraTheme.Colors.brandBackground, for: .navigationBar)
            .refreshable { await viewModel.load() }
        }
        .task { await viewModel.load() }
        .hoveraSyncStatus()
    }

    @ViewBuilder
    private func sectionHeader(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(HoveraTheme.Typography.heading)
            .foregroundStyle(HoveraTheme.Colors.brandSecondary)
    }
}

struct NextLessonCard: View {
    let entry: CalendarEntry?

    var body: some View {
        HStack(alignment: .top, spacing: HoveraTheme.Spacing.m) {
            Image(systemName: "calendar")
                .font(.title2)
                .foregroundStyle(HoveraTheme.Colors.brandPrimary)
                .frame(width: 40, height: 40)
                .background(Circle().fill(HoveraTheme.Colors.brandPrimary.opacity(0.12)))
            VStack(alignment: .leading, spacing: 4) {
                if let entry {
                    Text(entry.title ?? entry.type ?? "Lekcja")
                        .font(HoveraTheme.Typography.heading)
                    Text(entry.starts_at ?? "")
                        .font(HoveraTheme.Typography.body)
                        .foregroundStyle(HoveraTheme.Colors.textMuted)
                } else {
                    Text("client.next_lesson.empty.title")
                        .font(HoveraTheme.Typography.heading)
                    Text("client.next_lesson.empty.subtitle")
                        .font(HoveraTheme.Typography.body)
                        .foregroundStyle(HoveraTheme.Colors.textMuted)
                }
            }
            Spacer()
        }
        .hoveraCard()
    }
}

struct HorseCard: View {
    let horse: Horse

    var body: some View {
        HStack(alignment: .top, spacing: HoveraTheme.Spacing.m) {
            Image(systemName: "figure.equestrian.sports")
                .font(.title2)
                .foregroundStyle(HoveraTheme.Colors.brandPrimary)
                .frame(width: 40, height: 40)
                .background(Circle().fill(HoveraTheme.Colors.brandPrimary.opacity(0.12)))
            VStack(alignment: .leading, spacing: 4) {
                Text(horse.name)
                    .font(HoveraTheme.Typography.heading)
                let parts = [horse.breed, horse.sex, horse.color].compactMap { $0 }
                if !parts.isEmpty {
                    Text(parts.joined(separator: " · "))
                        .font(HoveraTheme.Typography.body)
                        .foregroundStyle(HoveraTheme.Colors.textMuted)
                }
            }
            Spacer()
        }
        .hoveraCard()
    }
}

struct InvoiceCard: View {
    let invoice: Invoice

    var body: some View {
        HStack(alignment: .top, spacing: HoveraTheme.Spacing.m) {
            Image(systemName: "doc.text")
                .font(.title2)
                .foregroundStyle(HoveraTheme.Colors.brandPrimary)
                .frame(width: 40, height: 40)
                .background(Circle().fill(HoveraTheme.Colors.brandPrimary.opacity(0.12)))
            VStack(alignment: .leading, spacing: 4) {
                Text(invoice.number ?? invoice.id)
                    .font(HoveraTheme.Typography.heading)
                var formatted: String { String(format: "%.2f %@", Double(invoice.amount_cents ?? 0) / 100.0, invoice.currency ?? "PLN") }
                let line = [formatted, invoice.issued_at]
                    .compactMap { $0 }
                    .joined(separator: " · ")
                if !line.isEmpty {
                    Text(line)
                        .font(HoveraTheme.Typography.body)
                        .foregroundStyle(HoveraTheme.Colors.textMuted)
                }
            }
            Spacer()
        }
        .hoveraCard()
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
                .background(Circle().fill(HoveraTheme.Colors.brandPrimary.opacity(0.12)))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(HoveraTheme.Typography.heading)
                Text(subtitle).font(HoveraTheme.Typography.body).foregroundStyle(HoveraTheme.Colors.textMuted)
            }
            Spacer()
        }
        .hoveraCard()
    }
}
