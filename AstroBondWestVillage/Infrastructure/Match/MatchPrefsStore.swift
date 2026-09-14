import Foundation

enum MatchIntent: String, CaseIterable, Identifiable, Codable, Sendable {
    case romantic
    case relationship
    case business
    case friends

    var id: String { rawValue }

    var titleTR: String {
        switch self {
        case .romantic: return "Romantik"
        case .relationship: return "İlişki"
        case .business: return "İş"
        case .friends: return "Arkadaş"
        }
    }

    var subtitle: String {
        switch self {
        case .romantic: return "Çekim & bağ"
        case .relationship: return "Uzun vadeli"
        case .business: return "Ortaklık"
        case .friends: return "Dostluk"
        }
    }

    var iconName: String {
        switch self {
        case .romantic: return "heart.fill"
        case .relationship: return "link"
        case .business: return "briefcase.fill"
        case .friends: return "person.2.fill"
        }
    }
}

@MainActor
final class MatchPrefsStore {
    static let shared = MatchPrefsStore()
    private let defaults = UserDefaults.standard
    private let key = "wv.match.prefs.v1"

    struct Snapshot: Codable, Equatable, Sendable {
        var intent: MatchIntent
        var preferredGenders: [Gender]
        var ageEnabled: Bool
        var ageMin: Int
        var ageMax: Int
        var locationEnabled: Bool
        var searchCity: String
        var maxDistanceKm: Double
    }

    var snapshot: Snapshot {
        get {
            guard let data = defaults.data(forKey: key),
                  let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) else {
                return .default
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: key)
            }
        }
    }
}

extension MatchPrefsStore.Snapshot {
    static let `default` = MatchPrefsStore.Snapshot(
        intent: .romantic,
        preferredGenders: [.woman, .man],
        ageEnabled: false,
        ageMin: 22,
        ageMax: 45,
        locationEnabled: false,
        searchCity: "İstanbul",
        maxDistanceKm: 100
    )
}

/// Deterministic bond story for match detail (no server synastry engine yet).
enum BondStory {
    struct Dimension: Identifiable, Equatable {
        let id: String
        let title: String
        let score: Int
        let blurb: String
    }

    struct Report: Equatable {
        let title: String
        let headline: String
        let overall: Int
        let dimensions: [Dimension]
        let aspects: [String]
    }

    static func report(mySun: ZodiacSign?, their: MatchCard, intent: MatchIntent) -> Report {
        let seed = stableSeed(their.id + (mySun?.rawValue ?? "x") + intent.rawValue)
        let dims: [(String, String, [String])] = [
            ("Kimya", "chemistry", ["İlk bakışta kıvılcım", "Yavaş ısınan çekim", "Sessiz ama yoğun"]),
            ("İletişim", "talk", ["Aynı dilde konuşuyorsunuz", "Bazen çeviri gerekir", "Derin sohbet potansiyeli"]),
            ("Güven", "trust", ["Stabil zemin", "Dikkatli adımlar", "Açık kalp ister"]),
            ("Büyüme", "grow", ["Birlikte yükselme", "Ayna etkisi", "Öğretici bağ"])
        ]
        var dimensions: [Dimension] = []
        var total = 0
        for (i, d) in dims.enumerated() {
            let score = 55 + Int(seed >> (i * 5) & 0x1F)
            let clamped = min(96, max(52, score))
            total += clamped
            dimensions.append(Dimension(
                id: d.1,
                title: d.0,
                score: clamped,
                blurb: d.2[Int(seed >> (i * 3) & 0x3) % d.2.count]
            ))
        }
        let overall = total / dims.count
        let title: String
        switch overall {
        case 85...: title = "Kozmik Bağ"
        case 75..<85: title = "Güçlü Rezonans"
        case 65..<75: title = "Uyumlu Çekim"
        default: title = "Keşif Bağı"
        }
        let aspects = [
            "Güneş–Ay gerilim/uyum çizgisi",
            "Venüs teması: \(intent.titleTR.lowercased()) odaklı",
            "Merkür diyaloğu açık",
            their.sunSign.map { "\($0.glyph) \($0.labelTR) vurgusu" } ?? "Burç vurgusu gizli"
        ]
        return Report(
            title: title,
            headline: "\(their.displayName) ile \(intent.titleTR.lowercased()) bağınızın özeti",
            overall: overall,
            dimensions: dimensions,
            aspects: aspects
        )
    }

    private static func stableSeed(_ s: String) -> UInt64 {
        var h: UInt64 = 14695981039346656037
        for b in s.utf8 {
            h ^= UInt64(b)
            h &*= 1099511628211
        }
        return h
    }
}
