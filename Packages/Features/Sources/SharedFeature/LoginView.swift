import SwiftUI
import CoreAuth
import CoreNetworking
import CoreSync
import CoreDesignSystem

public struct LoginView: View {
    @EnvironmentObject private var session: Session
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isWorking = false
    @State private var errorMessage: LocalizedStringKey?

    public init() {}

    public var body: some View {
        VStack(spacing: HoveraTheme.Spacing.l) {
            Spacer()

            HoveraBrandHeader()
            Text("login.subtitle")
                .multilineTextAlignment(.center)
                .foregroundStyle(HoveraTheme.Colors.textMuted)
                .padding(.horizontal, HoveraTheme.Spacing.l)

            VStack(spacing: HoveraTheme.Spacing.m) {
                TextField("login.email.label", text: $email)
                    .textInputAutocapitalization(.never)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .padding(HoveraTheme.Spacing.m)
                    .background(HoveraTheme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: HoveraTheme.Radius.card))

                SecureField("login.password.label", text: $password)
                    .textContentType(.password)
                    .padding(HoveraTheme.Spacing.m)
                    .background(HoveraTheme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: HoveraTheme.Radius.card))

                if let errorMessage {
                    Text(errorMessage)
                        .font(HoveraTheme.Typography.caption)
                        .foregroundStyle(HoveraTheme.Colors.danger)
                }

                Button(action: submit) {
                    Text(isWorking ? "common.loading" : "login.action")
                }
                .buttonStyle(HoveraPrimaryButtonStyle())
                .disabled(isWorking || email.isEmpty || password.isEmpty)
            }
            .padding(HoveraTheme.Spacing.l)

            Spacer()
        }
        .padding(HoveraTheme.Spacing.l)
    }

    private func submit() {
        Task { @MainActor in
            isWorking = true
            errorMessage = nil
            let capturedEmail = email
            let capturedPassword = password
            await session.signIn(email: capturedEmail, password: capturedPassword) { email, password in
                let response = try await APIClient.shared.send(
                    APIEndpoints.login(email: email, password: password, deviceName: "iOS")
                )
                return (
                    response.token,
                    response.memberships.map { m in
                        Membership(
                            id: m.tenant.id,
                            tenantName: m.tenant.name,
                            brandColorHex: m.tenant.brand_color,
                            role: MembershipRole(raw: m.role)
                        )
                    }
                )
            }
            isWorking = false
            if case .unauthenticated = session.state, !capturedEmail.isEmpty {
                errorMessage = "login.error.invalid"
            }
            if case .ready = session.state {
                await SyncEngineProvider.shared.runOnce()
                await DeviceTokenUploader.shared.uploadIfPending()
            }
        }
    }
}
