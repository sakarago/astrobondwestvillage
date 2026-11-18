import Foundation

/// A short, personal daily astrology note — "bring back" the daily insight
/// feature the app's settings already advertise ("Günlük İçgörü") but never
/// actually surfaced anywhere. Deterministic per calendar day + user + their
/// real sun/moon/rising, so it's stable through the day, genuinely unique to
/// that person's chart (not a copy of "everyone born under this sun sign"),
/// and honest about being a V1 approximation rather than claiming precise
/// live planetary transits we don't compute.
struct DailyNote: Equatable {
    let dateLabel: String
    let headline: String
    let body: String
    let focus: String
    let energyScore: Int
    let luckyHue: String
}

enum DailyNoteEngine {
    private static let focuses = [
        "Aşk", "Sosyal Çevre", "Kariyer", "İçe Dönüş", "Yaratıcılık", "Denge", "İletişim"
    ]
    private static let headlines: [String: [String]] = [
        "Aşk": ["Kalbin bugün önde", "Yakınlık kolaylaşıyor", "Bir söz yerini bulur"],
        "Sosyal Çevre": ["Çevren sana ayna tutuyor", "Bir sohbet kapı açıyor", "İnsanlar bugün yakın"],
        "Kariyer": ["Emeğin görünür oluyor", "Bir iş bugün ilerler", "Yönün netleşiyor"],
        "İçe Dönüş": ["Sessizlik de bir cevap", "İçe dönmek iyi gelir", "Kendinle bir randevu"],
        "Yaratıcılık": ["Bir kıvılcım bekliyor", "Yaratmak bugün kolay", "Elini boş bırakma"],
        "Denge": ["Tempo düşürmek güçtür", "Orta yol bugün açık", "Azı karar, çoğu zarar"],
        "İletişim": ["Sözün bugün ağır", "Bir mesaj yerini bulur", "Net konuşmak rahatlatır"]
    ]
    private static let luckyHues = [
        "Lavanta", "Altın", "Deniz mavisi", "Gül kurusu", "Zümrüt", "Gümüş", "Mercan"
    ]

    static func note(
        for date: Date,
        userId: String,
        sun: ZodiacSign?,
        moon: ZodiacSign?,
        rising: ZodiacSign?
    ) -> DailyNote {
        let cal = Calendar.current
        let dayOfYear = cal.ordinality(of: .day, in: .year, for: date) ?? 1
        let seed = stableHash(
            "\(userId)|\(cal.component(.year, from: date))|\(dayOfYear)|\(sun?.rawValue ?? "")|\(moon?.rawValue ?? "")|\(rising?.rawValue ?? "")"
        )
        var rng = Seeded(seed: seed)

        let focus = focuses[Int(rng.next() * Double(focuses.count)) % focuses.count]
        let hue = luckyHues[Int(rng.next() * Double(luckyHues.count)) % luckyHues.count]
        let energy = 54 + Int(rng.next() * 44) // 54...97
        let headlines = Self.headlines[focus] ?? ["Bugün gökyüzü seninle"]
        let headline = headlines[Int(rng.next() * Double(headlines.count)) % headlines.count]

        var parts: [String] = []
        if let sun {
            parts.append("\(sun.glyph) \(sun.labelTR) güneşin bugün \(sun.element.blurbTR) bir tavırla öne çıkıyor.")
        }
        if let moon {
            parts.append("\(moon.glyph) \(moon.labelTR) ayın iç dünyanı \(moon.element.labelTR.lowercased()) bir tonla renklendiriyor.")
        }
        if let rising {
            parts.append("Dışa yansıyan \(rising.labelTR) yükselenin bugün özellikle \(focus.lowercased()) alanında konuşuyor.")
        } else {
            parts.append("Enerjini bugün en çok \(focus.lowercased()) alanında hissedeceksin.")
        }

        let df = DateFormatter()
        df.locale = Locale(identifier: "tr_TR")
        df.dateFormat = "d MMMM"

        return DailyNote(
            dateLabel: df.string(from: date),
            headline: headline,
            body: parts.joined(separator: " "),
            focus: focus,
            energyScore: energy,
            luckyHue: hue
        )
    }

    private static func stableHash(_ s: String) -> UInt64 {
        var h: UInt64 = 14695981039346656037
        for b in s.utf8 {
            h ^= UInt64(b)
            h &*= 1099511628211
        }
        return h
    }
}

private struct Seeded {
    private var state: UInt64
    init(seed: UInt64) { state = seed &* 0x9E3779B97F4A7C15 }
    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1
        return Double((state >> 11) & 0x1FFFFF) / Double(0x1FFFFF)
    }
}
