import SwiftUI
import CoreAuth
import CoreNetworking
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
        Task {
            isWorking = true
            errorMessage = nil
            await session.signIn(email: email, password: password) { email, password in
                let response = try await APIClient.shared.send(
                    APIEndpoints.login(email: email, password: password, deviceName: "iOS")
                )
                let mapped = response.memberships.map { m in
                    Session.Membership(
                        id: m.tenant.id,
                        tenantName: m.tenant.name,
                        brandColorHex: m.tenant.brand_color,
                        role: MembershipRole(raw: m.role)
                    )
                }
                return (response.token, mapped)
            }
            isWorking = false
            if case .unauthenticated = session.state, !email.isEmpty {
                errorMessage = "login.error.invalid"
            }
        }
    }
}
