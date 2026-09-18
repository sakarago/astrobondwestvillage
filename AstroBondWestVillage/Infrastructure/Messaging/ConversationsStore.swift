import Foundation

/// Single shared source of truth for the inbox list. All four tabs stay
/// mounted at once (`MainTabView` just toggles opacity), so a view-local
/// `.task { await load() }` on the Messages tab only ever runs once and goes
/// stale — a freshly accepted match would create a conversation server-side
/// but never appear until the app relaunched. Routing everything through this
/// shared `@Observable` store means any screen (Match, Chat, Inbox) can
/// mutate the same list and every observer re-renders immediately.
@MainActor
@Observable
final class ConversationsStore {
    static let shared = ConversationsStore()

    private(set) var conversations: [ConversationSummary] = []
    var isLoading = false
    var error: String?

    private let messaging = MessagingService()
    private var hasLoadedOnce = false

    func loadIfNeeded() async {
        guard !hasLoadedOnce else { return }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            conversations = try await messaging.listConversations()
            hasLoadedOnce = true
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Optimistically inserts/updates a conversation the moment it's created
    /// (e.g. right after a match accept) so the inbox reflects it instantly,
    /// without waiting for a full server round-trip refresh.
    func upsert(_ conversation: ConversationSummary) {
        if let idx = conversations.firstIndex(where: {
            $0.id == conversation.id || $0.otherUserId.lowercased() == conversation.otherUserId.lowercased()
        }) {
            conversations[idx] = conversation
        } else {
            conversations.insert(conversation, at: 0)
        }
    }

    /// Original Cosmic Match: thumbs-up creates the inbox row even before the first message.
    func ensureConversation(otherUserId: String) async {
        let id = otherUserId.lowercased()
        if conversations.contains(where: { $0.otherUserId.lowercased() == id }) { return }
        do {
            let conversation = try await messaging.getOrCreateConversation(otherUserId: id)
            upsert(conversation)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func syncAcceptedMatches(userId: String) async {
        let ids = MatchDecisionsStore.shared.acceptedIds(for: userId)
        for matchId in ids {
            await ensureConversation(otherUserId: matchId)
        }
    }
}
