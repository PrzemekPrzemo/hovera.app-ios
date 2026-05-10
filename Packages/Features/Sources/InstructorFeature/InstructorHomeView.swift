import SwiftUI
import CoreDesignSystem
import SharedFeature

public struct InstructorHomeView: View {
    public init() {}

    public var body: some View {
        NavigationSplitView {
            List {
                Section(header: Text("instructor.section.today")) {
                    Text("instructor.empty.today")
                        .foregroundStyle(HoveraTheme.Colors.textMuted)
                }
            }
            .navigationTitle(Text("role.instructor.home.title"))
        } detail: {
            HoveraEmptyState(title: "instructor.detail.empty", icon: "calendar.badge.plus")
        }
        .hoveraSyncStatus()
    }
}
