import SwiftUI

struct MessagesInboxView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.activeTab) private var activeTab
    @State private var store = ConversationsStore.shared
    @State private var openChat: ConversationSummary?

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicBackdrop()

                VStack(spacing: 0) {
                    topBrandBar
                        .padding(.horizontal, 24)
                        .padding(.top, 12)

                    if store.isLoading && store.conversations.isEmpty {
                        Spacer()
                        ProgressView().tint(ABColor.lavender)
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 18) {
                                if let error = store.error, !error.isEmpty {
                                    Text(error)
                                        .font(ABFont.body(13, weight: .medium))
                                        .foregroundStyle(ABColor.ink.opacity(0.75))
                                        .padding(.horizontal, 4)
                                }

                                recentMatchesRow
                                conversationList

                                if !store.isLoading, store.conversations.isEmpty, store.error == nil {
                                    emptyInboxHint
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            .padding(.bottom, 130)
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $openChat) { conv in
                ChatView(conversation: conv, onBack: { openChat = nil })
            }
            .task { await reload() }
            .refreshable { await reload() }
            .onChange(of: activeTab?.wrappedValue) { _, newValue in
                if newValue == 2, openChat == nil {
                    Task { await reload() }
                }
            }
        }
    }

    private func reload() async {
        await store.refresh()
        if let id = session.user?.id {
            await store.syncAcceptedMatches(userId: id)
        }
    }

    private var emptyInboxHint: some View {
        Text("Henüz mesajın yok. Çarktan eşleş, sonra buradan yazışmaya devam et.")
            .font(ABFont.body(13, weight: .medium))
            .foregroundStyle(ABColor.inkMuted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 24)
    }

    private var topBrandBar: some View {
        HStack {
            HStack(spacing: 10) {
                AstroBondEmblem(size: 24)
                Text("ASTROBOND")
                    .font(ABFont.display(18, weight: .regular))
                    .tracking(5)
                    .padding(.leading, 6)
                    .foregroundStyle(ABColor.ink)
                    .fixedSize(horizontal: true, vertical: false)
            }
            Spacer()
            Button {
                activeTab?.wrappedValue = 0
            } label: {
                Image(systemName: "house")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(ABColor.ink)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [ABColor.lavenderSoft.opacity(0.85), ABColor.lavender.opacity(0.45)],
                                    startPoint: .top, endPoint: .bottom
                                ),
                                lineWidth: 5
                            )
                            .blur(radius: 7)
                    )
                    .overlay(
                        Circle().strokeBorder(
                            LinearGradient(
                                colors: [ABColor.lavenderSoft.opacity(0.75), ABColor.lavender.opacity(0.30)],
                                startPoint: .top, endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Keşfet’e dön")
        }
    }

    @ViewBuilder
    private var recentMatchesRow: some View {
        if !store.conversations.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("SON EŞLEŞMELER")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(store.conversations) { conv in
                            Button {
                                openChat = conv
                            } label: {
                                VStack(spacing: 7) {
                                    PersonAvatar(
                                        name: conv.otherName,
                                        photoURL: conv.otherPhotoURL,
                                        cartoonAvatarId: conv.otherCartoonAvatarId,
                                        sunSign: conv.otherSunSign,
                                        unlocked: false,
                                        size: 64
                                    )
                                    .overlay(alignment: .bottomTrailing) {
                                        if conv.unreadCount > 0 {
                                            Circle()
                                                .fill(ABColor.lavender)
                                                .frame(width: 11, height: 11)
                                                .overlay(Circle().stroke(ABColor.veil.opacity(0.2), lineWidth: 2))
                                        }
                                    }
                                    Text(conv.otherName)
                                        .font(ABFont.body(12, weight: .medium))
                                        .foregroundStyle(ABColor.ink.opacity(0.8))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.85)
                                }
                                .frame(width: 76)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 2)
                }
            }
        }
    }

    private var conversationList: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("MESAJLAR")

            VStack(spacing: 6) {
                ForEach(store.conversations) { conv in
                    Button {
                        openChat = conv
                    } label: {
                        inboxRow(conv)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(ABFont.body(11, weight: .semibold))
            .foregroundStyle(ABColor.inkMuted)
            .fixedSize(horizontal: true, vertical: false)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 2)
    }

    private func inboxRow(_ conv: ConversationSummary) -> some View {
        HStack(spacing: 14) {
            PersonAvatar(
                name: conv.otherName,
                photoURL: conv.otherPhotoURL,
                cartoonAvatarId: conv.otherCartoonAvatarId,
                sunSign: conv.otherSunSign,
                unlocked: false,
                size: 58
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(conv.otherName)
                    .font(ABFont.display(18))
                    .foregroundStyle(ABColor.ink)

                HStack(spacing: 6) {
                    Text(conv.otherSunSign?.lineGlyph ?? "✦")
                        .font(.system(size: 14))
                        .foregroundStyle(ABColor.lavender)
                    Text(conv.otherSunSign?.labelTR ?? "")
                        .font(ABFont.body(13))
                        .foregroundStyle(ABColor.inkMuted)
                }

                Text(conv.lastMessage)
                    .font(ABFont.body(13))
                    .foregroundStyle(ABColor.inkMuted)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 10) {
                Text(timeLabel(conv.lastMessageAt))
                    .font(ABFont.body(12))
                    .foregroundStyle(ABColor.inkMuted)

                if conv.unreadCount > 0 {
                    Circle()
                        .fill(ABColor.lavender)
                        .frame(width: 10, height: 10)
                } else {
                    Color.clear.frame(width: 10, height: 10)
                }
            }
        }
        .padding(15)
        .crystalPlate(cornerRadius: 22)
        .padding(4)
    }

    private func timeLabel(_ date: Date) -> String {
        guard date > .distantPast.addingTimeInterval(1) else { return "" }
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            return f.string(from: date)
        }
        if cal.isDateInYesterday(date) { return "Dün" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "dd MMM"
        return f.string(from: date)
    }
}
