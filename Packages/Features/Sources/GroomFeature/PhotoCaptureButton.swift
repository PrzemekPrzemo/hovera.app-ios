import SwiftUI
import PhotosUI
import CoreDesignSystem
import CorePersistence

/// Reusable photo picker button. Wraps `PhotosPicker` (iOS 16+) — nie
/// wymaga permission flow, picker uchodzi out-of-process.
/// Po wyborze ładuje dane do `Data` i wywołuje async `onSelected`.
public struct PhotoCaptureButton: View {
    let horse: Horse
    let onSelected: @MainActor (Data, Horse) async -> Void

    @State private var selection: PhotosPickerItem?
    @State private var isLoading = false

    public init(horse: Horse, onSelected: @escaping @MainActor (Data, Horse) async -> Void) {
        self.horse = horse
        self.onSelected = onSelected
    }

    public var body: some View {
        PhotosPicker(selection: $selection, matching: .images, photoLibrary: .shared()) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Image(systemName: "camera")
                }
                Text("Sfotografuj konia")
                    .font(HoveraTheme.Typography.caption)
            }
            .padding(.horizontal, HoveraTheme.Spacing.m)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(HoveraTheme.Colors.brandPrimary.opacity(0.12))
            )
            .foregroundStyle(HoveraTheme.Colors.brandSecondary)
        }
        .onChange(of: selection) { _, newItem in
            guard let newItem else { return }
            isLoading = true
            Task { @MainActor in
                defer { isLoading = false; selection = nil }
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await onSelected(data, horse)
                }
            }
        }
    }
}
