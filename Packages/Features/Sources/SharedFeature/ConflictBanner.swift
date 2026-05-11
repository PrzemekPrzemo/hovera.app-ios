import SwiftUI
import CoreSync
import CoreDesignSystem

/// Lekki banner pojawiający się na doła ekranu gdy SyncEngine emituje
/// ConflictEvent (rejecta z `/api/v1/sync/mutations`). Trzyma ostatnie
/// zdarzenie ~6 sekund. Mountłe jako overlay na root content (RootView
/// lub per-role home) przez `.hoveraConflictBanner()`.
public struct ConflictBanner: View {
    @State private var current: ConflictEvent?
    @State private var hideTask: Task<Void, Never>?

    public init() {}

    public var body: some View {
        Group {
            if let event = current {
                bannerContent(event)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: current)
        .task {
            for await event in SyncEngineProvider.shared.conflicts {
                current = event
                hideTask?.cancel()
                hideTask = Task {
                    try? await Task.sleep(nanoseconds: 6_000_000_000)
                    if !Task.isCancelled { current = nil }
                }
            }
        }
    }

    @ViewBuilder
    private func bannerContent(_ event: ConflictEvent) -> some View {
        HStack(alignment: .top, spacing: HoveraTheme.Spacing.s) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 4) {
                Text("Konflikt: \(event.entity) · \(event.conflictType)")
                    .font(HoveraTheme.Typography.heading)
                    .foregroundStyle(.white)
                if let first = event.messages.first, !first.isEmpty {
                    Text(first)
                        .font(HoveraTheme.Typography.body)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            Spacer()
            Button { current = nil } label: {
                Image(systemName: "xmark").foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(HoveraTheme.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: HoveraTheme.Radius.card)
                .fill(HoveraTheme.Colors.danger)
        )
        .padding(.horizontal, HoveraTheme.Spacing.m)
        .padding(.bottom, HoveraTheme.Spacing.l)
    }
}

public extension View {
    /// Mounts ConflictBanner as a bottom overlay. Call once at the root
    /// of each role home view (or RootView) to surface SyncEngine
    /// conflict events as a dismissable danger-tinted card.
    func hoveraConflictBanner() -> some View {
        overlay(alignment: .bottom) { ConflictBanner() }
    }
}
