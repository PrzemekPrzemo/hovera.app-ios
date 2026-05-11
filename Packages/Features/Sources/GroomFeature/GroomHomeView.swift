import SwiftUI
import CoreDesignSystem
import CorePersistence
import SharedFeature

public struct GroomHomeView: View {
    @State private var viewModel = GroomHomeViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: HoveraTheme.Spacing.m) {
                    Text("groom.intro.offline")
                        .font(HoveraTheme.Typography.body)
                        .foregroundStyle(HoveraTheme.Colors.textMuted)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(HoveraTheme.Spacing.m)
                        .background(HoveraTheme.Colors.brandPrimary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: HoveraTheme.Radius.card))

                    sectionHeader("Zadania na dziś (\(viewModel.pendingToday.count))")
                    if viewModel.pendingToday.isEmpty {
                        PlaceholderCard(
                            title: "Brak zadań na dziś",
                            subtitle: "Wszystko zrobione albo dane jeszcze się ładują.",
                            icon: "checkmark.seal"
                        )
                    } else {
                        ForEach(viewModel.pendingToday) { activity in
                            ActivityRow(activity: activity) {
                                Task { await viewModel.toggleActivity(activity) }
                            }
                        }
                    }

                    sectionHeader("Konie pod opieką (\(viewModel.horses.count))")
                    if viewModel.horses.isEmpty {
                        PlaceholderCard(title: "Brak koni", subtitle: "Pojawią się po synchronizacji.", icon: "figure.equestrian.sports")
                    } else {
                        ForEach(viewModel.horses) { horse in
                            HStack {
                                Text(horse.name)
                                    .font(HoveraTheme.Typography.heading)
                                    .foregroundStyle(HoveraTheme.Colors.textPrimary)
                                Spacer()
                                if let box = horse.box_id {
                                    Text("Boks \(box)")
                                        .font(HoveraTheme.Typography.body)
                                        .foregroundStyle(HoveraTheme.Colors.textMuted)
                                }
                            }
                            .hoveraCard()
                        }
                    }

                    if !viewModel.recentWeights.isEmpty {
                        sectionHeader("Ostatnie pomiary wagi")
                        ForEach(Array(viewModel.recentWeights.prefix(5))) { w in
                            WeightRow(measurement: w)
                        }
                    }
                }
                .padding(HoveraTheme.Spacing.l)
            }
            .navigationTitle(Text("role.groom.home.title"))
            .toolbar { LogoutToolbarItem() }
            .refreshable { await viewModel.load() }
        }
        .task { await viewModel.load() }
        .hoveraSyncStatus()
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(HoveraTheme.Typography.heading)
            .foregroundStyle(HoveraTheme.Colors.brandSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ActivityRow: View {
    let activity: StableActivity
    let onToggle: () -> Void

    var body: some View {
        let done = activity.status == "completed"
        Button(action: onToggle) {
            HStack(spacing: HoveraTheme.Spacing.m) {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(done ? HoveraTheme.Colors.brandPrimary : HoveraTheme.Colors.textMuted)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.title ?? activity.kind ?? "Zadanie")
                        .font(HoveraTheme.Typography.heading)
                        .foregroundStyle(HoveraTheme.Colors.textPrimary)
                        .strikethrough(done, color: HoveraTheme.Colors.textMuted)
                    if let due = activity.due_at {
                        Text(due)
                            .font(HoveraTheme.Typography.body)
                            .foregroundStyle(HoveraTheme.Colors.textMuted)
                    }
                }
                Spacer()
            }
            .hoveraCard()
        }
        .buttonStyle(.plain)
    }
}

struct WeightRow: View {
    let measurement: HorseWeightMeasurement

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Koń: \(String(measurement.horse_id.prefix(8)))")
                    .font(HoveraTheme.Typography.heading)
                    .foregroundStyle(HoveraTheme.Colors.textPrimary)
                if let date = measurement.measurement_date {
                    Text(date)
                        .font(HoveraTheme.Typography.body)
                        .foregroundStyle(HoveraTheme.Colors.textMuted)
                }
            }
            Spacer()
            if let kg = measurement.weight_kg {
                Text("\(kg, specifier: "%.0f") kg")
                    .font(HoveraTheme.Typography.heading)
                    .foregroundStyle(HoveraTheme.Colors.brandPrimary)
            }
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
