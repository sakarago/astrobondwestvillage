import SwiftUI

struct RootView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        Group {
            switch session.phase {
            case .loading:
                ZStack {
                    CosmicBackdrop()
                    ProgressView()
                        .tint(ABColor.lavenderSoft)
                }
            case .welcome:
                WelcomeView()
            case .onboarding:
                OnboardingFlowView()
            case .main:
                MainTabView()
            }
        }
        .environment(\.locale, Locale(identifier: "tr_TR"))
        .animation(.easeInOut(duration: 0.28), value: session.phase)
        .task {
            AppLanguageStore.shared.language = .tr
            await session.bootstrap()
        }
    }
}

#Preview {
    RootView()
        .environment(SessionStore())
}
