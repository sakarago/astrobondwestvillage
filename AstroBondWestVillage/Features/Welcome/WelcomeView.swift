import SwiftUI

struct WelcomeView: View {
    @Environment(SessionStore.self) private var session
    @State private var authRoute: AuthRoute?

    var body: some View {
        ZStack {
            CosmicBackdrop()

            VStack(spacing: 0) {
                Spacer(minLength: 40)

                VStack(spacing: 14) {
                    Text("ASTROBOND")
                        .font(ABFont.display(36, weight: .bold))
                        .foregroundStyle(ABColor.ink)
                        .tracking(4)

                    Text("Yıldızlar altında bağ kur.")
                        .font(ABFont.body(16))
                        .foregroundStyle(ABColor.inkMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28)

                Spacer()

                HStack(spacing: 10) {
                    AuthPillButton(title: "Giriş", emphasized: false) {
                        authRoute = AuthRoute(mode: .signIn)
                    }
                    AuthPillButton(title: "Kaydol", emphasized: true) {
                        authRoute = AuthRoute(mode: .signUp)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
            }
        }
        .sheet(item: $authRoute) { route in
            AuthSheetView(mode: route.mode)
                .environment(session)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

struct AuthRoute: Identifiable, Equatable {
    let id = UUID()
    let mode: AuthSheetView.Mode
}

/// Shared Giriş / Kaydol capsule used on welcome and the auth sheet.
struct AuthPillButton: View {
    let title: String
    var emphasized: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ABFont.body(15, weight: .semibold))
                .foregroundStyle(isEnabled ? ABColor.ink : ABColor.inkMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background {
                    Capsule(style: .continuous)
                        .fill(emphasized ? ABColor.lavender.opacity(0.32) : Color.white.opacity(0.07))
                }
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(
                            emphasized ? ABColor.lavenderSoft.opacity(0.6) : Color.white.opacity(0.14),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.55)
    }
}

#Preview {
    WelcomeView()
        .environment(SessionStore())
}
