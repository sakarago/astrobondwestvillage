import Foundation

/// Local accept/reject memory + today’s strip for Match.
@MainActor
final class MatchDecisionsStore {
    static let shared = MatchDecisionsStore()

    private let defaults = UserDefaults.standard

    struct Record: Codable, Identifiable, Equatable, Sendable {
        var id: String
        var displayName: String
        var age: Int
        var city: String?
        var sunSignRaw: String?
        var photoURL: String?
        var cartoonAvatarId: String?
        var accepted: Bool
        var decidedAt: Date

        var sunSign: ZodiacSign? {
            ZodiacSign.fromEnglishName(sunSignRaw)
        }
    }

    func acceptedKey(for userId: String) -> String { "wv.match.accepted.\(userId)" }
    func rejectedKey(for userId: String) -> String { "wv.match.rejected.\(userId)" }
    private func historyKey(for userId: String) -> String { "wv.match.history.\(userId)" }

    func acceptedIds(for userId: String) -> Set<String> {
        Set(defaults.stringArray(forKey: acceptedKey(for: userId)) ?? [])
    }

    func rejectedIds(for userId: String) -> Set<String> {
        Set(defaults.stringArray(forKey: rejectedKey(for: userId)) ?? [])
    }

    func history(for userId: String) -> [Record] {
        guard let data = defaults.data(forKey: historyKey(for: userId)),
              let decoded = try? JSONDecoder().decode([Record].self, from: data) else {
            return []
        }
        return decoded.sorted { $0.decidedAt > $1.decidedAt }
    }

    func todayHistory(for userId: String) -> [Record] {
        let cal = Calendar.current
        return history(for: userId).filter { cal.isDateInToday($0.decidedAt) }
    }

    func accept(myUserId: String, card: MatchCard) {
        var set = acceptedIds(for: myUserId)
        set.insert(card.id.lowercased())
        defaults.set(Array(set), forKey: acceptedKey(for: myUserId))
        var rejected = rejectedIds(for: myUserId)
        rejected.remove(card.id.lowercased())
        defaults.set(Array(rejected), forKey: rejectedKey(for: myUserId))
        appendHistory(myUserId: myUserId, card: card, accepted: true)
    }

    func reject(myUserId: String, card: MatchCard) {
        var set = rejectedIds(for: myUserId)
        set.insert(card.id.lowercased())
        defaults.set(Array(set), forKey: rejectedKey(for: myUserId))
        appendHistory(myUserId: myUserId, card: card, accepted: false)
    }

    /// Legacy helpers kept for call sites that only have an id.
    func accept(myUserId: String, matchId: String) {
        var set = acceptedIds(for: myUserId)
        set.insert(matchId.lowercased())
        defaults.set(Array(set), forKey: acceptedKey(for: myUserId))
    }

    func reject(myUserId: String, matchId: String) {
        var set = rejectedIds(for: myUserId)
        set.insert(matchId.lowercased())
        defaults.set(Array(set), forKey: rejectedKey(for: myUserId))
    }

    private func appendHistory(myUserId: String, card: MatchCard, accepted: Bool) {
        var items = history(for: myUserId).filter { $0.id != card.id.lowercased() }
        items.insert(
            Record(
                id: card.id.lowercased(),
                displayName: card.displayName,
                age: card.age,
                city: card.city,
                sunSignRaw: card.sunSign?.englishName,
                photoURL: card.photoURL,
                cartoonAvatarId: card.cartoonAvatarId,
                accepted: accepted,
                decidedAt: Date()
            ),
            at: 0
        )
        if items.count > 40 { items = Array(items.prefix(40)) }
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: historyKey(for: myUserId))
        }
    }
}

/// Client-side daily reveal counter (server still enforces the real cap).
@MainActor
final class DailyRevealQuotaStore {
    static let shared = DailyRevealQuotaStore()
    static let dailyLimit = 3

    private let defaults = UserDefaults.standard

    private func key(for userId: String) -> String {
        let day = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        return "wv.reveal.count.\(userId).\(Int(day))"
    }

    func used(for userId: String) -> Int {
        defaults.integer(forKey: key(for: userId))
    }

    var remaining: Int { max(0, Self.dailyLimit - 0) } // placeholder; use remaining(for:)

    /// No client-side daily reveal limit.
    static let isUnlimited = true

    func remaining(for userId: String) -> Int {
        99
    }

    func recordReveal(for userId: String) {
        // Kept for compatibility; limit is not enforced.
        let k = key(for: userId)
        defaults.set(used(for: userId) + 1, forKey: k)
    }
}
