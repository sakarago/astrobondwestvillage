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

                VStack(spacing: 12) {
                    CrystalCTAButton(title: "Giriş Yap") {
                        authRoute = AuthRoute(mode: .signIn)
                    }

                    CrystalCTAButton(title: "Kaydol") {
                        authRoute = AuthRoute(mode: .signUp)
                    }

                    Text("Mevcut hesabın varsa Giriş Yap’ı kullan.")
                        .font(ABFont.body(12))
                        .foregroundStyle(ABColor.inkMuted)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
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

#Preview {
    WelcomeView()
        .environment(SessionStore())
}
