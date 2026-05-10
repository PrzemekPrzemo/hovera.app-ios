import SwiftUI
import CoreDesignSystem
import SharedFeature

public struct InstructorHomeView: View {
    public init() {}

    public var body: some View {
        NavigationSplitView {
            // Lessons list (collapsed to stack on iPhone via size class).
            List {
                Section(header: Text("instructor.section.today", bundle: .module)) {
                    Text("instructor.empty.today", bundle: .module)
                        .foregroundStyle(HoveraTheme.Colors.textMuted)
                }
            }
            .navigationTitle(Text("role.instructor.home.title", bundle: .module))
        } detail: {
            HoveraEmptyState(title: "instructor.detail.empty", icon: "calendar.badge.plus")
        }
        .hoveraSyncStatus()
    }
}
