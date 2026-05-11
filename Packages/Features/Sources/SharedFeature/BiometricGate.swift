import SwiftUI
import LocalAuthentication
import CoreDesignSystem

/// Owijka biometric (Face ID / Touch ID) — gateuje content widoku. Gdy device
/// nie ma biometric ustawionego, propmpt pomijany i content widoczny od razu
/// (gracjowy fallback). User może poprawić błędną próbę przyciskiem retry.
public struct BiometricGate<Content: View>: View {
    @State private var status: GateStatus = .pending
    private let content: () -> Content

    enum GateStatus { case pending, unlocked, failed(String) }

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        Group {
            switch status {
            case .unlocked:
                content()
            case .pending:
                lockedView(message: "Odblokowywanie…")
            case .failed(let reason):
                lockedView(message: reason, showRetry: true)
            }
        }
        .task {
            if case .pending = status {
                await authenticate()
            }
        }
    }

    @ViewBuilder
    private func lockedView(message: String, showRetry: Bool = false) -> some View {
        VStack(spacing: HoveraTheme.Spacing.m) {
            HoveraBrandHeader()
            Image(systemName: "faceid")
                .font(.system(size: 56))
                .foregroundStyle(HoveraTheme.Colors.brandPrimary)
            Text(message)
                .font(HoveraTheme.Typography.body)
                .foregroundStyle(HoveraTheme.Colors.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, HoveraTheme.Spacing.l)
            if showRetry {
                Button("Spróbuj ponownie") {
                    status = .pending
                    Task { await authenticate() }
                }
                .buttonStyle(HoveraPrimaryButtonStyle())
                .padding(.horizontal, HoveraTheme.Spacing.l)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HoveraTheme.Colors.brandBackground)
    }

    private func authenticate() async {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // Brak skonfigurowanej biometrii / passcode — nie blokuj.
            await MainActor.run { status = .unlocked }
            return
        }
        do {
            let ok = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Odblokuj hovera"
            )
            await MainActor.run { status = ok ? .unlocked : .failed("Nie udało się zweryfikować.") }
        } catch {
            await MainActor.run { status = .failed("Anulowano. Stuknij, aby spróbować ponownie.") }
        }
    }
}
