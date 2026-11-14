import Foundation
import Supabase

struct MatchCard: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let displayName: String
    let age: Int
    let city: String?
    let sunSign: ZodiacSign?
    let moonSign: ZodiacSign?
    let risingSign: ZodiacSign?
    let bio: String
    let photoURL: String?
    let cartoonAvatarId: String?
}

enum MatchServiceError: LocalizedError {
    case dailyLimit
    case emptyPool
    case network(String)

    var errorDescription: String? {
        switch self {
        case .dailyLimit: return "Bugünkü eşleşme hakkın doldu."
        case .emptyPool: return "Şu an gösterilecek aday yok."
        case .network(let m): return m
        }
    }
}

final class MatchService: Sendable {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientProvider.shared.client) {
        self.client = client
    }

    func fetchCandidates(limit: Int = 20) async throws -> [MatchCard] {
        struct Row: Decodable {
            let id: String
            let displayName: String
            let age: Int?
            let bio: String?
            let city: String?
            let sunSign: String?
            let moonSign: String?
            let risingSign: String?
            let photoURL: String?
            let cartoonAvatarId: String?
            let isDemo: Bool?
            enum CodingKeys: String, CodingKey {
                case id, age, bio, city
                case displayName = "display_name"
                case sunSign = "sun_sign"
                case moonSign = "moon_sign"
                case risingSign = "rising_sign"
                case photoURL = "profile_photo_url"
                case cartoonAvatarId = "cartoon_avatar_id"
                case isDemo = "is_demo"
            }
        }

        do {
            let rows: [Row] = try await client
                .rpc("get_daily_candidates", params: ["p_limit": limit])
                .execute()
                .value
            return rows
                .filter { !($0.isDemo ?? false) }
                .filter { !$0.displayName.trimmingCharacters(in: .whitespaces).isEmpty }
                .map {
                    MatchCard(
                        id: $0.id.lowercased(),
                        displayName: $0.displayName,
                        age: $0.age ?? 0,
                        city: $0.city,
                        sunSign: ZodiacSign.fromEnglishName($0.sunSign),
                        moonSign: ZodiacSign.fromEnglishName($0.moonSign),
                        risingSign: ZodiacSign.fromEnglishName($0.risingSign),
                        bio: $0.bio ?? "",
                        photoURL: $0.photoURL,
                        cartoonAvatarId: $0.cartoonAvatarId
                    )
                }
        } catch {
            throw MatchServiceError.network(error.localizedDescription)
        }
    }

    /// Records a reveal in `daily_reveals` (required before messaging).
    /// Idempotent: already-revealed pairs are a server no-op.
    /// When the app is in unlimited mode, ask the server for a high daily cap
    /// so we never show a match that can't later open a chat.
    func reveal(userId: String) async throws {
        struct Params: Encodable {
            let p_target_user_id: String
            let p_daily_limit: Int
        }
        let limit = DailyRevealQuotaStore.isUnlimited ? 999 : DailyRevealQuotaStore.dailyLimit
        do {
            try await client
                .rpc("reveal_match", params: Params(p_target_user_id: userId, p_daily_limit: limit))
                .execute()
        } catch {
            let message = error.localizedDescription
            if message.contains("limit_reached") {
                throw MatchServiceError.dailyLimit
            }
            throw MatchServiceError.network(message)
        }
    }
}
