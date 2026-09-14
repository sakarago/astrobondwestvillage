import Foundation
import Supabase

struct ConversationSummary: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let otherUserId: String
    let otherName: String
    let otherPhotoURL: String?
    let otherSunSign: ZodiacSign?
    let lastMessage: String
    let lastMessageAt: Date
    let unreadCount: Int
}

struct ChatMessage: Identifiable, Equatable, Sendable {
    let id: String
    let conversationId: String
    let senderId: String
    let text: String
    let sentAt: Date
    let isRead: Bool
}

enum MessagingError: LocalizedError {
    case dailyLimit
    case empty
    case tooLong
    case notAllowed
    case network(String)

    var errorDescription: String? {
        switch self {
        case .dailyLimit: return "Günlük mesaj hakkın doldu (10)."
        case .empty: return "Boş mesaj gönderilemez."
        case .tooLong: return "Mesaj en fazla 500 karakter olabilir."
        case .notAllowed: return "Bu kişiyle henüz mesajlaşamazsın."
        case .network(let m): return m
        }
    }

    static func fromServer(_ message: String) -> MessagingError {
        let m = message.lowercased()
        if m.contains("daily_message_limit") { return .dailyLimit }
        if m.contains("empty_message") { return .empty }
        if m.contains("message_too_long") { return .tooLong }
        if m.contains("messaging_not_allowed") { return .notAllowed }
        return .network(message)
    }
}

enum PhotoGate {
    static let unlockAfterMessageCount = 10

    static func isUnlocked(messageCount: Int) -> Bool {
        messageCount >= unlockAfterMessageCount
    }
}

final class MessagingService: Sendable {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientProvider.shared.client) {
        self.client = client
    }

    func listConversations() async throws -> [ConversationSummary] {
        do {
            let rows: [ConversationRow] = try await client.rpc("list_conversations").execute().value
            return rows.map { $0.summary }
        } catch {
            throw MessagingError.fromServer(error.localizedDescription)
        }
    }

    func getOrCreateConversation(otherUserId: String) async throws -> ConversationSummary {
        do {
            let rows: [ConversationRow] = try await client
                .rpc("get_or_create_conversation", params: ["p_other_user_id": otherUserId])
                .execute()
                .value
            guard let row = rows.first else {
                throw MessagingError.network("Sohbet açılamadı.")
            }
            return row.summary
        } catch let error as MessagingError {
            throw error
        } catch {
            throw MessagingError.fromServer(error.localizedDescription)
        }
    }

    func fetchMessages(conversationId: String) async throws -> [ChatMessage] {
        do {
            let rows: [MessageRow] = try await client
                .from("messages")
                .select()
                .eq("conversation_id", value: conversationId)
                .order("sent_at", ascending: true)
                .execute()
                .value
            return rows.map(\.message)
        } catch {
            throw MessagingError.fromServer(error.localizedDescription)
        }
    }

    func sendMessage(conversationId: String, text: String) async throws -> ChatMessage {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw MessagingError.empty }
        guard trimmed.count <= 500 else { throw MessagingError.tooLong }
        do {
            let rows: [MessageRow] = try await client
                .rpc("send_message", params: SendParams(conversationId: conversationId, text: trimmed))
                .execute()
                .value
            guard let row = rows.first else {
                throw MessagingError.network("Mesaj gönderilemedi.")
            }
            return row.message
        } catch let error as MessagingError {
            throw error
        } catch {
            throw MessagingError.fromServer(error.localizedDescription)
        }
    }

    func markRead(conversationId: String, myUserId: String) async {
        _ = try? await client
            .from("messages")
            .update(["is_read": true])
            .eq("conversation_id", value: conversationId)
            .neq("sender_id", value: myUserId)
            .eq("is_read", value: false)
            .execute()
    }

    func observeMessages(conversationId: String) -> AsyncStream<ChatMessage> {
        AsyncStream { continuation in
            let task = Task {
                let channel = client.realtimeV2.channel("messages:\(conversationId)")
                let insertions = channel.postgresChange(
                    InsertAction.self,
                    schema: "public",
                    table: "messages",
                    filter: .eq("conversation_id", value: conversationId)
                )
                do {
                    try await channel.subscribeWithError()
                } catch {
                    continuation.finish()
                    return
                }
                for await insert in insertions {
                    if Task.isCancelled { break }
                    if let row = try? insert.decodeRecord(as: MessageRow.self, decoder: .messagingDates) {
                        continuation.yield(row.message)
                    }
                }
                await client.realtimeV2.removeChannel(channel)
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

private struct SendParams: Encodable {
    let conversationId: String
    let text: String
    enum CodingKeys: String, CodingKey {
        case conversationId = "p_conversation_id"
        case text = "p_text"
    }
}

private struct ConversationRow: Decodable {
    let id: String
    let lastMessageText: String?
    let lastMessageAt: Date?
    let unreadCount: Int64?
    let otherUserId: String
    let otherDisplayName: String
    let otherProfilePhotoURL: String?
    let otherSunSign: String?

    enum CodingKeys: String, CodingKey {
        case id
        case lastMessageText = "last_message_text"
        case lastMessageAt = "last_message_at"
        case unreadCount = "unread_count"
        case otherUserId = "other_user_id"
        case otherDisplayName = "other_display_name"
        case otherProfilePhotoURL = "other_profile_photo_url"
        case otherSunSign = "other_sun_sign"
    }

    var summary: ConversationSummary {
        let preview = (lastMessageText ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return ConversationSummary(
            id: id,
            otherUserId: otherUserId.lowercased(),
            otherName: otherDisplayName,
            otherPhotoURL: otherProfilePhotoURL,
            otherSunSign: ZodiacSign.fromEnglishName(otherSunSign),
            lastMessage: preview.isEmpty ? "Astro Bond açıldı. İlk mesajı sen at!" : preview,
            lastMessageAt: lastMessageAt ?? .distantPast,
            unreadCount: Int(unreadCount ?? 0)
        )
    }
}

private struct MessageRow: Codable {
    let id: String
    let conversationId: String
    let senderId: String
    let body: String
    let sentAt: Date
    let isRead: Bool

    enum CodingKeys: String, CodingKey {
        case id, body
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case sentAt = "sent_at"
        case isRead = "is_read"
    }

    var message: ChatMessage {
        ChatMessage(
            id: id,
            conversationId: conversationId,
            senderId: senderId.lowercased(),
            text: body,
            sentAt: sentAt,
            isRead: isRead
        )
    }
}

private extension JSONDecoder {
    static let messagingDates: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let raw = try decoder.singleValueContainer().decode(String.self)
            let f1 = ISO8601DateFormatter()
            f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let f2 = ISO8601DateFormatter()
            f2.formatOptions = [.withInternetDateTime]
            if let d = f1.date(from: raw) ?? f2.date(from: raw) { return d }
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: raw))
        }
        return decoder
    }()
}
