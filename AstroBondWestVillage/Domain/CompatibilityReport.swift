import Foundation

nonisolated struct CompatibilityReport: Equatable, Hashable, Codable, Sendable {
    let userId1: String
    let userId2: String
    let totalScore: Int
    let breakdown: [CategoryScore]
    let strengths: [String]
    let challenges: [String]
    let overallLabel: CompatibilityLabel
    let topSynastryAspects: [SynastryAspect]
    let calculatedAt: Date

    var normalizedScore: Double { Double(totalScore) / 100.0 }
}

nonisolated struct CategoryScore: Equatable, Hashable, Codable, Sendable {
    let category: CompatibilityCategory
    let score: Int
    let maxScore: Int
    let description: String

    var percentage: Double {
        guard maxScore > 0 else { return 0 }
        return Double(score) / Double(maxScore)
    }
}

nonisolated enum CompatibilityCategory: String, CaseIterable, Equatable, Hashable, Codable, Sendable {
    case sunSign = "Güneş Uyumu"
    case moonSign = "Ay Uyumu"
    case venusMars = "Venüs-Mars Sinerjisi"
    case ascendant = "Yükselen Uyumu"
    case composite = "Karma Etkiler"

    var weight: Int {
        switch self {
        case .sunSign: return 15
        case .moonSign: return 20
        case .venusMars: return 25
        case .ascendant: return 15
        case .composite: return 25
        }
    }

    var emoji: String {
        switch self {
        case .sunSign: return "☉"
        case .moonSign: return "☽"
        case .venusMars: return "♀♂"
        case .ascendant: return "↑"
        case .composite: return "⚹"
        }
    }
}

nonisolated enum CompatibilityLabel: String, CaseIterable, Equatable, Hashable, Codable, Sendable {
    case universalHarmony = "Evrensel Uyum"
    case deepBond = "Derin Bağ"
    case compatible = "Uyumlu"
    case growthArea = "Gelişim Alanı"
    case challenging = "Zorlayıcı"

    static func from(score: Int) -> CompatibilityLabel {
        switch score {
        case 90...100: return .universalHarmony
        case 75...89: return .deepBond
        case 60...74: return .compatible
        case 45...59: return .growthArea
        default: return .challenging
        }
    }

    var description: String {
        switch self {
        case .universalHarmony:
            return "Nadir görülen kozmik bir uyum. İkinizin enerji alanları mükemmel örtüşüyor."
        case .deepBond:
            return "Güçlü ve anlamlı bir bağ. Birbirinizi derin bir düzeyde anlayabilirsiniz."
        case .compatible:
            return "Sağlıklı ve uyumlu bir ilişki potansiyeli. Birlikte büyüyebilirsiniz."
        case .growthArea:
            return "Farklılıklarınız sizi tamamlıyor. Birbirinizden öğrenecek çok şeyiniz var."
        case .challenging:
            return "Güçlü farklılıklar mevcut. Bilinçli çabayla değerli bir ilişki kurulabilir."
        }
    }
}
