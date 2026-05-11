import SwiftUI
import CoreDesignSystem
import CorePersistence
import SharedFeature

public struct ManagerHomeView: View {
    @State private var viewModel = ManagerHomeViewModel()
    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HoveraTheme.Spacing.l) {
                    HStack(spacing: HoveraTheme.Spacing.s) {
                        StatTile(label: "Konie", value: "\(viewModel.totalHorses)")
                        StatTile(label: "Klienci", value: "\(viewModel.totalClients)")
                        StatTile(label: "Boksy", value: "\(viewModel.boxes.count)")
                    }
                    HStack(spacing: HoveraTheme.Spacing.s) {
                        StatTile(label: "Aktywne przypisania", value: "\(viewModel.activeAssignments.count)")
                        StatTile(label: "Niezapłacone faktury", value: "\(viewModel.unpaidCount)")
                    }

                    section("Najbliższe lekcje")
                    if viewModel.upcomingLessons.isEmpty {
                        Text("Brak nadchodzących lekcji")
                            .foregroundStyle(HoveraTheme.Colors.textMuted)
                    } else {
                        ForEach(viewModel.upcomingLessons) { lesson in
                            LessonRow(lesson: lesson)
                        }
                    }

                    section("Ostatnie faktury")
                    if viewModel.recentInvoices.isEmpty {
                        Text("Brak faktur")
                            .foregroundStyle(HoveraTheme.Colors.textMuted)
                    } else {
                        ForEach(viewModel.recentInvoices) { invoice in
                            InvoiceRow(invoice: invoice)
                        }
                    }
                }
                .padding(HoveraTheme.Spacing.l)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(Text("role.manager.home.title"))
            .refreshable { await viewModel.load() }
        }
        .task { await viewModel.load() }
        .hoveraSyncStatus()
    }

    @ViewBuilder
    private func section(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(HoveraTheme.Typography.heading)
            .foregroundStyle(HoveraTheme.Colors.brandSecondary)
    }
}

struct StatTile: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .foregroundStyle(HoveraTheme.Colors.brandPrimary)
            Text(label)
                .font(HoveraTheme.Typography.caption)
                .foregroundStyle(HoveraTheme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .hoveraCard()
    }
}

struct LessonRow: View {
    let lesson: CalendarEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(lesson.title ?? lesson.type ?? "Lekcja")
                .font(HoveraTheme.Typography.heading)
                .foregroundStyle(HoveraTheme.Colors.textPrimary)
            Text(lesson.starts_at ?? "")
                .font(HoveraTheme.Typography.body)
                .foregroundStyle(HoveraTheme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .hoveraCard()
    }
}

struct InvoiceRow: View {
    let invoice: Invoice
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(invoice.number ?? invoice.id)
                .font(HoveraTheme.Typography.heading)
                .foregroundStyle(HoveraTheme.Colors.textPrimary)
            let amount = invoice.amount_cents.map { String(format: "%.2f %@", Double($0) / 100.0, invoice.currency ?? "PLN") }
            let line = [amount, invoice.issued_at].compactMap { $0 }.joined(separator: " · ")
            if !line.isEmpty {
                Text(line)
                    .font(HoveraTheme.Typography.body)
                    .foregroundStyle(HoveraTheme.Colors.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .hoveraCard()
    }
}
