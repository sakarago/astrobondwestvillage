import SwiftUI

struct MessagesInboxView: View {
    @Environment(\.activeTab) private var activeTab
    @State private var store = ConversationsStore.shared
    @State private var openChat: ConversationSummary?

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicBackdrop()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Mesajlar")
                            .font(ABFont.display(30))
                            .foregroundStyle(ABColor.ink)
                            .padding(.horizontal, 4)

                        if store.isLoading && store.conversations.isEmpty {
                            ProgressView().tint(ABColor.lavenderSoft)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                        } else if store.conversations.isEmpty {
                            Text("Henüz sohbet yok. Çarktan eşleş, kabul et, sonra buradan yaz.")
                                .font(ABFont.body(14))
                                .foregroundStyle(ABColor.inkMuted)
                                .padding(20)
                                .crystalPlate(cornerRadius: 24)
                        } else {
                            ForEach(store.conversations) { conv in
                                Button {
                                    openChat = conv
                                } label: {
                                    inboxRow(conv)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if let error = store.error {
                            Text(error)
                                .font(ABFont.body(13))
                                .foregroundStyle(Color(hex: "#C69A9A"))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 130)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $openChat) { conv in
                ChatView(conversation: conv, onBack: { openChat = nil })
            }
            .task { await store.loadIfNeeded() }
            .refreshable { await store.refresh() }
            .onChange(of: activeTab?.wrappedValue) { _, newValue in
                // Backstop for the case above: every time this tab becomes
                // active, pull the latest from the server too (covers replies
                // that arrived while we were elsewhere, not just our own
                // freshly-accepted matches which are upserted instantly).
                if newValue == 2, openChat == nil {
                    Task { await store.refresh() }
                }
            }
        }
    }

    private func inboxRow(_ conv: ConversationSummary) -> some View {
        HStack(spacing: 14) {
            PersonAvatar(
                name: conv.otherName,
                photoURL: conv.otherPhotoURL,
                sunSign: conv.otherSunSign,
                unlocked: false,
                size: 54
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conv.otherName)
                        .font(ABFont.display(18))
                        .foregroundStyle(ABColor.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer()
                    if conv.unreadCount > 0 {
                        Circle()
                            .fill(ABColor.lavender)
                            .frame(width: 9, height: 9)
                    }
                }
                Text(conv.lastMessage)
                    .font(ABFont.body(13))
                    .foregroundStyle(ABColor.inkMuted)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .crystalPlate(cornerRadius: 22)
    }
}
