import Foundation

/// The ten bodies the original matching engine scores and draws.
nonisolated enum Planet: Int, CaseIterable, Equatable, Hashable, Codable, Sendable {
    case sun = 0
    case moon
    case mercury
    case venus
    case mars
    case jupiter
    case saturn
    case uranus
    case neptune
    case pluto

    var name: String {
        switch self {
        case .sun: return "Güneş"
        case .moon: return "Ay"
        case .mercury: return "Merkür"
        case .venus: return "Venüs"
        case .mars: return "Mars"
        case .jupiter: return "Jüpiter"
        case .saturn: return "Satürn"
        case .uranus: return "Uranüs"
        case .neptune: return "Neptün"
        case .pluto: return "Plüton"
        }
    }

    var englishName: String {
        switch self {
        case .sun: return "Sun"
        case .moon: return "Moon"
        case .mercury: return "Mercury"
        case .venus: return "Venus"
        case .mars: return "Mars"
        case .jupiter: return "Jupiter"
        case .saturn: return "Saturn"
        case .uranus: return "Uranus"
        case .neptune: return "Neptune"
        case .pluto: return "Pluto"
        }
    }

    var glyph: String {
        switch self {
        case .sun: return "☉"
        case .moon: return "☽"
        case .mercury: return "☿"
        case .venus: return "♀"
        case .mars: return "♂"
        case .jupiter: return "♃"
        case .saturn: return "♄"
        case .uranus: return "♅"
        case .neptune: return "♆"
        case .pluto: return "♇"
        }
    }

    var isPersonal: Bool {
        switch self {
        case .sun, .moon, .mercury, .venus, .mars: return true
        default: return false
        }
    }

    var isBenefic: Bool {
        switch self {
        case .venus, .jupiter, .sun, .moon: return true
        default: return false
        }
    }

    var isMalefic: Bool {
        switch self {
        case .mars, .saturn, .pluto: return true
        default: return false
        }
    }
}
