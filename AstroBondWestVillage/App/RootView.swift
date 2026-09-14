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
        .animation(.easeInOut(duration: 0.28), value: session.phase)
        .task {
            await session.bootstrap()
        }
    }
}

#Preview {
    RootView()
        .environment(SessionStore())
}
