import SwiftUI

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleaned.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension Color {
    /// Kept for call-site compatibility; always resolves to the dark palette.
    static func adaptive(light: String, dark: String) -> Color {
        Color(hex: dark)
    }
}

enum ABColor {
    static let lavender = Color(hex: "#8F7FF7")
    static let lavenderSoft = Color(hex: "#D6CFFF")
    static let ink = Color(hex: "#F4F6FA")
    static let inkMuted = Color(hex: "#A6ACB6")
    static let space = Color(hex: "#0A0A0C")
    static let ctaText = Color(hex: "#FFFFFF")
    static let rim = Color(hex: "#FFFFFF")
    static let glassTint = Color(hex: "#FFFFFF")
    static let peachGlow = Color(hex: "#E8A990")
    static let veil = Color(hex: "#FFFFFF")
    static let panel = Color(hex: "#000000")
    static let surface = Color(hex: "#0A0A0C")
}
