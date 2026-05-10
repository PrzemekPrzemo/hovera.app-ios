import SwiftUI
import CoreDesignSystem
import SharedFeature

public struct ManagerHomeView: View {
    public init() {}

    public var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            List {
                Section(header: Text("manager.section.overview")) {
                    NavigationLink(destination: Text("manager.calendar.placeholder")) {
                        Label("manager.calendar.title", systemImage: "calendar")
                    }
                    NavigationLink(destination: Text("manager.boxes.placeholder")) {
                        Label("manager.boxes.title", systemImage: "square.grid.2x2")
                    }
                    NavigationLink(destination: Text("manager.invoices.placeholder")) {
                        Label("manager.invoices.title", systemImage: "doc.text")
                    }
                    NavigationLink(destination: Text("manager.clients.placeholder")) {
                        Label("manager.clients.title", systemImage: "person.2")
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle(Text("role.manager.home.title"))
        } content: {
            HoveraEmptyState(title: "manager.content.empty", icon: "chart.bar")
        } detail: {
            HoveraEmptyState(title: "manager.detail.empty", icon: "sidebar.right")
        }
        .hoveraSyncStatus()
    }
}
