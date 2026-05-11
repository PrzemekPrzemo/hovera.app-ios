import SwiftUI
import CoreDesignSystem
import CorePersistence
import SharedFeature

public struct InstructorHomeView: View {
    @State private var viewModel = InstructorHomeViewModel()
    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HoveraTheme.Spacing.m) {
                    Text("instructor.section.today")
                        .font(HoveraTheme.Typography.heading)
                        .foregroundStyle(HoveraTheme.Colors.brandSecondary)
                    + Text(verbatim: " (\(viewModel.todayLessons.count))")
                        .font(HoveraTheme.Typography.heading)
                        .foregroundStyle(HoveraTheme.Colors.textMuted)

                    if viewModel.todayLessons.isEmpty {
                        Text("instructor.empty.today")
                            .foregroundStyle(HoveraTheme.Colors.textMuted)
                    } else {
                        ForEach(viewModel.todayLessons) { lesson in
                            LessonCard(
                                lesson: lesson,
                                horseName: lesson.horse_id.flatMap { viewModel.horsesById[$0]?.name }
                            )
                        }
                    }
                }
                .padding(HoveraTheme.Spacing.l)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(Text("role.instructor.home.title"))
            .refreshable { await viewModel.load() }
        }
        .task { await viewModel.load() }
        .hoveraSyncStatus()
    }
}

struct LessonCard: View {
    let lesson: CalendarEntry
    let horseName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(lesson.title ?? lesson.type ?? "Lekcja")
                .font(HoveraTheme.Typography.heading)
                .foregroundStyle(HoveraTheme.Colors.textPrimary)
            let parts = [lesson.starts_at, horseName.map { "— " + $0 }].compactMap { $0 }
            if !parts.isEmpty {
                Text(parts.joined(separator: " "))
                    .font(HoveraTheme.Typography.body)
                    .foregroundStyle(HoveraTheme.Colors.textMuted)
            }
            if let status = lesson.status {
                Text("Status: \(status)")
                    .font(HoveraTheme.Typography.caption)
                    .foregroundStyle(HoveraTheme.Colors.brandPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .hoveraCard()
    }
}
