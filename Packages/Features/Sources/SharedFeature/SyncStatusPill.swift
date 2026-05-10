import SwiftUI
import CoreSync
import CoreDesignSystem

/// Persistent footer / status pill that surfaces the SyncEngine status
/// to the user. Mounted on every role home view via `.hoveraSyncStatus()`.
public struct SyncStatusPill: View {
    @State private var status: SyncStatus = .idle

    public init() {}

    public var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label, bundle: .module)
                .font(HoveraTheme.Typography.caption)
                .foregroundStyle(HoveraTheme.Colors.textMuted)
        }
        .padding(.horizontal, HoveraTheme.Spacing.m)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(HoveraTheme.Colors.surface)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
        )
        .task {
            // Re-sample status every 5s while the view is on screen.
            while !Task.isCancelled {
                status = await SyncEngineProviderShim.status()
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }
    }

    private var label: LocalizedStringKey {
        switch status {
        case .idle: return "sync.status.idle"
        case .syncing: return "sync.status.syncing"
        case .offline: return "sync.status.offline"
        case .error: return "sync.status.offline"
        }
    }

    private var color: Color {
        switch status {
        case .idle: return .green
        case .syncing: return .yellow
        case .offline, .error: return HoveraTheme.Colors.danger
        }
    }
}

/// Indirection so we don't need to expose the app-target SyncEngineProvider
/// to feature packages. Feature code calls into this shim; the host app
/// can override `provider` at launch.
public enum SyncEngineProviderShim {
    nonisolated(unsafe) public static var statusProvider: @Sendable () async -> SyncStatus = { .idle }
    public static func status() async -> SyncStatus { await statusProvider() }
}

public extension View {
    func hoveraSyncStatus() -> some View {
        overlay(alignment: .bottom) {
            SyncStatusPill()
                .padding(.bottom, HoveraTheme.Spacing.m)
        }
    }
}
