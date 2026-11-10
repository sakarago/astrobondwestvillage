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
    /// A color that resolves differently in light / dark appearance.
    static func adaptive(light: String, dark: String) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(Color(hex: dark)) : UIColor(Color(hex: light))
        })
    }
}

enum ABColor {
    static let lavender = Color(hex: "#8F7FF7")
    /// Accent / icon tint. Soft lilac on dark, deeper violet on cream.
    static let lavenderSoft = Color.adaptive(light: "#7A66DB", dark: "#D6CFFF")
    static let ink = Color.adaptive(light: "#2B2237", dark: "#F4F6FA")
    static let inkMuted = Color.adaptive(light: "#6E6272", dark: "#A6ACB6")
    static let space = Color(hex: "#0A0A0C")

    /// Primary text on a CTA surface.
    static let ctaText = Color.adaptive(light: "#3A2430", dark: "#FFFFFF")
    /// Bright rim / bevel line on glass (white on dark, warm sand on cream).
    static let rim = Color.adaptive(light: "#E2C4B3", dark: "#FFFFFF")
    /// Neutral glass tint.
    static let glassTint = Color.adaptive(light: "#FFFFFF", dark: "#FFFFFF")
    /// Warm accent used for light-mode glows and shadows.
    static let peachGlow = Color(hex: "#E8A990")
    /// Faint overlay for strokes / fills (white on dark, plum on cream).
    static let veil = Color.adaptive(light: "#2B2237", dark: "#FFFFFF")
    /// Panel scrim (black on dark, white on cream).
    static let panel = Color.adaptive(light: "#FFFFFF", dark: "#000000")
    /// Screen-level surface for sheets etc.
    static let surface = Color.adaptive(light: "#FBF1E8", dark: "#0A0A0C")
}
