import SwiftUI

struct RootView: View {
    @State private var selectedTab = 1

    var body: some View {
        ZStack {
            CosmicBackdrop()

            TabView(selection: $selectedTab) {
                WelcomePlaceholderView()
                    .tag(0)
                MatchPlaceholderView()
                    .tag(1)
                MessagesPlaceholderView()
                    .tag(2)
                ProfilePlaceholderView()
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack {
                Spacer()
                WestVillageTabBar(selectedTab: $selectedTab)
            }
        }
    }
}

private struct WestVillageTabBar: View {
    @Binding var selectedTab: Int

    private let items: [(Int, String)] = [
        (0, "sparkles"),
        (1, "heart.fill"),
        (2, "message.fill"),
        (3, "person.fill")
    ]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items, id: \.0) { index, icon in
                Button {
                    selectedTab = index
                } label: {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: selectedTab == index ? .semibold : .regular))
                        .foregroundStyle(.white.opacity(selectedTab == index ? 1 : 0.55))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background {
                            if selectedTab == index {
                                Capsule(style: .continuous)
                                    .fill(Color.white.opacity(0.10))
                                    .overlay(
                                        Capsule(style: .continuous)
                                            .strokeBorder(ABColor.lavenderSoft.opacity(0.45), lineWidth: 1)
                                    )
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        }
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.50), Color.white.opacity(0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.9
                )
        )
        .shadow(color: Color.black.opacity(0.28), radius: 18, y: 10)
        .padding(.horizontal, 36)
        .padding(.bottom, 18)
    }
}

#Preview {
    RootView()
}
