import Foundation

enum Gender: String, CaseIterable, Identifiable, Codable, Sendable {
    case woman, man, nonBinary, other, preferNotSay

    var id: String { rawValue }

    var labelTR: String {
        switch self {
        case .woman: return "Kadın"
        case .man: return "Erkek"
        case .nonBinary: return "Non-binary"
        case .other: return "Diğer"
        case .preferNotSay: return "Belirtmek istemiyorum"
        }
    }

    var stableName: String { rawValue }

    static func fromStableName(_ name: String) -> Gender {
        Gender(rawValue: name) ?? .preferNotSay
    }
}

enum ZodiacSign: String, CaseIterable, Equatable, Hashable, Codable, Sendable {
    case aries, taurus, gemini, cancer, leo, virgo
    case libra, scorpio, sagittarius, capricorn, aquarius, pisces

    var englishName: String { rawValue.capitalized }

    var glyph: String {
        switch self {
        case .aries: return "♈︎"
        case .taurus: return "♉︎"
        case .gemini: return "♊︎"
        case .cancer: return "♋︎"
        case .leo: return "♌︎"
        case .virgo: return "♍︎"
        case .libra: return "♎︎"
        case .scorpio: return "♏︎"
        case .sagittarius: return "♐︎"
        case .capricorn: return "♑︎"
        case .aquarius: return "♒︎"
        case .pisces: return "♓︎"
        }
    }

    var lineGlyph: String { glyph }

    var labelTR: String {
        switch self {
        case .aries: return "Koç"
        case .taurus: return "Boğa"
        case .gemini: return "İkizler"
        case .cancer: return "Yengeç"
        case .leo: return "Aslan"
        case .virgo: return "Başak"
        case .libra: return "Terazi"
        case .scorpio: return "Akrep"
        case .sagittarius: return "Yay"
        case .capricorn: return "Oğlak"
        case .aquarius: return "Kova"
        case .pisces: return "Balık"
        }
    }

    /// Tropical sun-sign window, shown on the Eşleşme reveal card.
    var dateRangeText: String {
        switch self {
        case .aries: return "21 Mar – 19 Nis"
        case .taurus: return "20 Nis – 20 May"
        case .gemini: return "21 May – 20 Haz"
        case .cancer: return "21 Haz – 22 Tem"
        case .leo: return "23 Tem – 22 Ağu"
        case .virgo: return "23 Ağu – 22 Eyl"
        case .libra: return "23 Eyl – 22 Eki"
        case .scorpio: return "23 Eki – 21 Kas"
        case .sagittarius: return "22 Kas – 21 Ara"
        case .capricorn: return "22 Ara – 19 Oca"
        case .aquarius: return "20 Oca – 18 Şub"
        case .pisces: return "19 Şub – 20 Mar"
        }
    }

    /// Approximate tropical sun sign from calendar month/day (good enough for V1 profile).
    static func sunSign(month: Int, day: Int) -> ZodiacSign {
        let md = month * 100 + day
        switch md {
        case 321...419: return .aries
        case 420...520: return .taurus
        case 521...620: return .gemini
        case 621...722: return .cancer
        case 723...822: return .leo
        case 823...922: return .virgo
        case 923...1022: return .libra
        case 1023...1121: return .scorpio
        case 1122...1221: return .sagittarius
        case 1222...1231, 101...119: return .capricorn
        case 120...218: return .aquarius
        default: return .pisces
        }
    }

    static func fromEnglishName(_ name: String?) -> ZodiacSign? {
        guard let name else { return nil }
        return allCases.first { $0.englishName.caseInsensitiveCompare(name) == .orderedSame }
    }

    enum Element: String, Hashable, Codable, Sendable { case fire, earth, air, water

        var labelTR: String {
            switch self {
            case .fire: return "Ateş"
            case .earth: return "Toprak"
            case .air: return "Hava"
            case .water: return "Su"
            }
        }

        var blurbTR: String {
            switch self {
            case .fire: return "girişken, doğrudan ve hızlı tutuşan"
            case .earth: return "somut, sabırlı ve köklü"
            case .air: return "meraklı, sözel ve bağlantı arayan"
            case .water: return "sezgisel, duygusal ve derin"
            }
        }

        /// Fire↔Air and Earth↔Water — the traditionally complementary pairs.
        func isComplementary(to other: Element) -> Bool {
            switch (self, other) {
            case (.fire, .air), (.air, .fire): return true
            case (.earth, .water), (.water, .earth): return true
            default: return false
            }
        }

        /// Fire↔Water and Earth↔Air — the traditionally friction-prone pairs.
        func isChallenging(to other: Element) -> Bool {
            switch (self, other) {
            case (.fire, .water), (.water, .fire): return true
            case (.earth, .air), (.air, .earth): return true
            default: return false
            }
        }
    }

    enum Modality: String, Hashable, Codable, Sendable { case cardinal, fixed, mutable

        var labelTR: String {
            switch self {
            case .cardinal: return "Öncü"
            case .fixed: return "Sabit"
            case .mutable: return "Değişken"
            }
        }

        var blurbTR: String {
            switch self {
            case .cardinal: return "başlatır, harekete geçirir"
            case .fixed: return "sürdürür, derinleştirir"
            case .mutable: return "uyum sağlar, dönüştürür"
            }
        }
    }

    /// Classical element — same grouping used by every tropical astrology
    /// system, independent of any ephemeris data.
    var element: Element {
        switch self {
        case .aries, .leo, .sagittarius: return .fire
        case .taurus, .virgo, .capricorn: return .earth
        case .gemini, .libra, .aquarius: return .air
        case .cancer, .scorpio, .pisces: return .water
        }
    }

    /// Classical modality (quality).
    var modality: Modality {
        switch self {
        case .aries, .cancer, .libra, .capricorn: return .cardinal
        case .taurus, .leo, .scorpio, .aquarius: return .fixed
        case .gemini, .virgo, .sagittarius, .pisces: return .mutable
        }
    }

    /// Traditional ruling planet (glyph + Turkish name).
    var rulerTR: String {
        switch self {
        case .aries: return "♂ Mars"
        case .taurus: return "♀ Venüs"
        case .gemini: return "☿ Merkür"
        case .cancer: return "☽ Ay"
        case .leo: return "☉ Güneş"
        case .virgo: return "☿ Merkür"
        case .libra: return "♀ Venüs"
        case .scorpio: return "♇ Plüton"
        case .sagittarius: return "♃ Jüpiter"
        case .capricorn: return "♄ Satürn"
        case .aquarius: return "♅ Uranüs"
        case .pisces: return "♆ Neptün"
        }
    }

    /// Index 0...11 in the fixed Aries→Pisces order, used to derive
    /// whole-sign house cusps from the Ascendant.
    var index: Int { Self.allCases.firstIndex(of: self) ?? 0 }

    /// Starting degree of this sign on the ecliptic (0° Aries = 0).
    var startDegree: Double { Double(index) * 30 }

    /// Same-element signs (the classical trine).
    func isTrine(to other: ZodiacSign) -> Bool { element == other.element }

    /// Complementary elements: Fire–Air, Earth–Water.
    func isSextile(to other: ZodiacSign) -> Bool { element.isComplementary(to: other.element) }

    /// Three (or nine) signs apart.
    func isSquare(to other: ZodiacSign) -> Bool {
        let diff = abs(index - other.index)
        return diff == 3 || diff == 9
    }

    /// Six signs apart.
    func isOpposite(to other: ZodiacSign) -> Bool {
        abs(index - other.index) == 6
    }

    /// Derive the sign from ecliptic longitude (0–360).
    static func from(longitude: Double) -> ZodiacSign {
        let normalized = ((longitude.truncatingRemainder(dividingBy: 360)) + 360).truncatingRemainder(dividingBy: 360)
        return allCases[Int(normalized / 30) % 12]
    }

    /// Degree within the sign (0–30).
    static func degreeWithinSign(longitude: Double) -> Double {
        let normalized = ((longitude.truncatingRemainder(dividingBy: 360)) + 360).truncatingRemainder(dividingBy: 360)
        return normalized.truncatingRemainder(dividingBy: 30)
    }

    /// Whole-sign house system: house 1 = rising sign, each subsequent house
    /// is simply the next sign around the wheel. It's the simplest classical
    /// house system and the only one that's meaningful without an exact
    /// birth time + ephemeris, which this app doesn't compute yet.
    static func houseSign(_ house: Int, ascendant: ZodiacSign) -> ZodiacSign {
        allCases[(ascendant.index + house - 1 + 1200) % 12]
    }
}

/// A neighbourhood/district within a `CityOption`. Birth-location precision
/// lives here (matches the old app's rule: `profiles.city` stores the
/// metropolitan city, the finer-grained place lives in `birth_data`).
struct District: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
}

struct CityOption: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let country: String
    let utcOffset: Double
    let districts: [District]

    /// Fallback city-level coordinate (first district) — used anywhere a
    /// single lat/long is needed without a specific district chosen yet.
    var latitude: Double { districts.first?.latitude ?? 0 }
    var longitude: Double { districts.first?.longitude ?? 0 }

    static func == (lhs: CityOption, rhs: CityOption) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    private static func d(_ name: String, _ lat: Double, _ lon: Double) -> District {
        District(id: name, name: name, latitude: lat, longitude: lon)
    }

    static let presets: [CityOption] = [
        .init(id: "istanbul", name: "İstanbul", country: "Türkiye", utcOffset: 3, districts: [
            d("Adalar", 40.8747, 29.0894), d("Arnavutköy", 41.1841, 28.7405), d("Ataşehir", 40.9927, 29.1244),
            d("Avcılar", 40.9795, 28.7214), d("Bağcılar", 41.0344, 28.8564), d("Bahçelievler", 41.0020, 28.8598),
            d("Bakırköy", 40.9780, 28.8721), d("Başakşehir", 41.0931, 28.8020), d("Bayrampaşa", 41.0490, 28.9025),
            d("Beşiktaş", 41.0430, 29.0094), d("Beykoz", 41.1342, 29.0922), d("Beylikdüzü", 40.9820, 28.6391),
            d("Beyoğlu", 41.0369, 28.9850), d("Büyükçekmece", 41.0201, 28.5850), d("Çekmeköy", 41.0323, 29.1764),
            d("Esenler", 41.0433, 28.8767), d("Esenyurt", 41.0330, 28.6753), d("Eyüpsultan", 41.0477, 28.9338),
            d("Fatih", 41.0186, 28.9647), d("Gaziosmanpaşa", 41.0750, 28.9126), d("Kadıköy", 40.9917, 29.0277),
            d("Kağıthane", 41.0812, 28.9720), d("Kartal", 40.8880, 29.1897), d("Küçükçekmece", 40.9951, 28.7784),
            d("Maltepe", 40.9351, 29.1307), d("Pendik", 40.8760, 29.2330), d("Sancaktepe", 41.0024, 29.2298),
            d("Sarıyer", 41.1690, 29.0493), d("Şişli", 41.0605, 28.9872), d("Ümraniye", 41.0164, 29.1248),
            d("Üsküdar", 41.0230, 29.0151), d("Zeytinburnu", 40.9897, 28.9005)
        ]),
        .init(id: "ankara", name: "Ankara", country: "Türkiye", utcOffset: 3, districts: [
            d("Çankaya", 39.9179, 32.8627), d("Keçiören", 39.9739, 32.8663), d("Yenimahalle", 39.9675, 32.7934),
            d("Mamak", 39.9208, 32.9223), d("Etimesgut", 39.9497, 32.6526)
        ]),
        .init(id: "izmir", name: "İzmir", country: "Türkiye", utcOffset: 3, districts: [
            d("Karşıyaka", 38.4584, 27.1097), d("Bornova", 38.4622, 27.2177), d("Konak", 38.4192, 27.1287),
            d("Buca", 38.3847, 27.1690), d("Çiğli", 38.4870, 27.0497)
        ]),
        .init(id: "bursa", name: "Bursa", country: "Türkiye", utcOffset: 3, districts: [
            d("Osmangazi", 40.1826, 29.0665), d("Nilüfer", 40.2200, 28.9517),
            d("Yıldırım", 40.1950, 29.1070), d("İnegöl", 40.0781, 29.5133)
        ]),
        .init(id: "antalya", name: "Antalya", country: "Türkiye", utcOffset: 3, districts: [
            d("Muratpaşa", 36.8841, 30.7056), d("Kepez", 36.9176, 30.6896),
            d("Konyaaltı", 36.8590, 30.6360), d("Alanya", 36.5444, 31.9954)
        ]),
        .init(id: "nyc", name: "New York", country: "USA", utcOffset: -5, districts: [
            d("Manhattan", 40.7831, -73.9712), d("Brooklyn", 40.6782, -73.9442),
            d("Queens", 40.7282, -73.7949), d("Bronx", 40.8448, -73.8648)
        ]),
        .init(id: "london", name: "London", country: "UK", utcOffset: 0, districts: [
            d("Westminster", 51.4975, -0.1357), d("Camden", 51.5290, -0.1255),
            d("Hackney", 51.5450, -0.0553), d("Greenwich", 51.4826, -0.0077)
        ])
    ]

    static func district(named name: String, in cityId: String) -> District? {
        presets.first(where: { $0.id == cityId })?.districts.first(where: { $0.name == name })
    }

    /// Finds which preset city contains a district with this name — used to
    /// reverse-map a stored `birth_data.city` (district) back to a picker
    /// selection when hydrating the edit-profile screen.
    static func city(containingDistrictNamed name: String) -> CityOption? {
        presets.first(where: { city in city.districts.contains(where: { $0.name == name }) })
    }
}
