import Foundation

nonisolated enum AspectType: String, CaseIterable, Equatable, Hashable, Codable, Sendable {
    case conjunction = "Kavuşum"
    case sextile = "Sekstil"
    case square = "Kare"
    case trine = "Üçgen"
    case opposition = "Karşıtlık"

    var englishName: String {
        switch self {
        case .conjunction: return "Conjunction"
        case .sextile: return "Sextile"
        case .square: return "Square"
        case .trine: return "Trine"
        case .opposition: return "Opposition"
        }
    }

    var angle: Double {
        switch self {
        case .conjunction: return 0
        case .sextile: return 60
        case .square: return 90
        case .trine: return 120
        case .opposition: return 180
        }
    }

    /// Standard orb (tolerance) in degrees — same values as the original engine.
    var orb: Double {
        switch self {
        case .conjunction: return 8
        case .sextile: return 4
        case .square: return 6
        case .trine: return 6
        case .opposition: return 8
        }
    }

    var isHarmonious: Bool {
        switch self {
        case .trine, .sextile, .conjunction: return true
        case .square, .opposition: return false
        }
    }

    var isChallenging: Bool { !isHarmonious }

    var glyph: String {
        switch self {
        case .conjunction: return "☌"
        case .sextile: return "⚹"
        case .square: return "□"
        case .trine: return "△"
        case .opposition: return "☍"
        }
    }

    static func from(angleDifference: Double) -> AspectType? {
        let normalized = ((angleDifference.truncatingRemainder(dividingBy: 360)) + 360).truncatingRemainder(dividingBy: 360)
        let angle = min(normalized, 360 - normalized)
        for aspectType in AspectType.allCases {
            if abs(angle - aspectType.angle) <= aspectType.orb {
                return aspectType
            }
        }
        return nil
    }
}
