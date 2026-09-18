import Foundation

nonisolated struct ZodiacPoint: Equatable, Hashable, Codable, Sendable {
    let sign: ZodiacSign
    let degree: Double
    let longitude: Double

    init(longitude: Double) {
        self.longitude = ((longitude.truncatingRemainder(dividingBy: 360)) + 360).truncatingRemainder(dividingBy: 360)
        self.sign = ZodiacSign.from(longitude: self.longitude)
        self.degree = ZodiacSign.degreeWithinSign(longitude: self.longitude)
    }

    init(sign: ZodiacSign, degree: Double) {
        self.sign = sign
        self.degree = max(0, min(29.99, degree))
        self.longitude = sign.startDegree + self.degree
    }

    var formatted: String {
        let d = Int(degree)
        let m = Int((degree - Double(d)) * 60)
        return "\(d)°\(m)' \(sign.glyph) \(sign.labelTR)"
    }
}

nonisolated struct PlanetPosition: Equatable, Hashable, Codable, Sendable {
    let planet: Planet
    let sign: ZodiacSign
    let degree: Double
    let longitude: Double
    let house: Int
    let isRetrograde: Bool

    var zodiacPoint: ZodiacPoint { ZodiacPoint(longitude: longitude) }

    var formatted: String {
        let d = Int(degree)
        let m = Int((degree - Double(d)) * 60)
        return "\(planet.name) \(sign.glyph)\(sign.labelTR) \(d)°\(m)'\(isRetrograde ? " ℞" : "")"
    }
}

nonisolated struct HouseEntity: Equatable, Hashable, Codable, Sendable {
    let number: Int
    let sign: ZodiacSign
    let cuspLongitude: Double
    let planets: [Planet]

    var romanNumeral: String {
        let numerals = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]
        return (1...12).contains(number) ? numerals[number - 1] : "\(number)"
    }

    var theme: String {
        switch number {
        case 1: return "Kimlik, Görünüm, Yeni Başlangıçlar"
        case 2: return "Değerler, Para, Sahip Olunanlar"
        case 3: return "İletişim, Kardeşler, Kısa Seyahatler"
        case 4: return "Ev, Aile, Kökenler"
        case 5: return "Yaratıcılık, Aşk, Eğlence"
        case 6: return "Sağlık, Çalışma, Günlük Yaşam"
        case 7: return "İlişkiler, Ortaklıklar, Evlilik"
        case 8: return "Dönüşüm, Miras, Gizem"
        case 9: return "Felsefe, Uzak Seyahatler, Yükseköğretim"
        case 10: return "Kariyer, Statü, Kamuoyu Kimliği"
        case 11: return "Dostluklar, Gruplar, Umutlar"
        case 12: return "Bilinçdışı, Gizlilik, Maneviyat"
        default: return ""
        }
    }
}

nonisolated struct AspectEntity: Equatable, Hashable, Codable, Sendable {
    let planet1: Planet
    let planet2: Planet
    let type: AspectType
    let orb: Double
    let isApplying: Bool

    var isExact: Bool { orb < 0.5 }

    var strength: Double {
        max(0, 1.0 - (orb / type.orb))
    }

    var description: String {
        let exactStr = isExact ? " (tam)" : " (\(String(format: "%.1f", orb))° orb)"
        return "\(planet1.name) \(type.glyph) \(planet2.name)\(exactStr)"
    }
}

nonisolated struct NatalChart: Equatable, Hashable, Codable, Sendable {
    let userId: String
    let calculatedAt: Date
    let birthData: BirthData
    let planets: [PlanetPosition]
    let houses: [HouseEntity]
    let aspects: [AspectEntity]
    let ascendant: ZodiacPoint
    let midheaven: ZodiacPoint
    let dominantElement: ZodiacSign.Element
    let dominantModality: ZodiacSign.Modality
    let elementCounts: [ZodiacSign.Element: Int]
    let modalityCounts: [ZodiacSign.Modality: Int]

    var sunSign: ZodiacSign { planet(.sun)?.sign ?? .aries }
    var moonSign: ZodiacSign { planet(.moon)?.sign ?? .aries }
    var risingSign: ZodiacSign { ascendant.sign }

    var sunPosition: PlanetPosition? { planet(.sun) }
    var moonPosition: PlanetPosition? { planet(.moon) }
    var venusPosition: PlanetPosition? { planet(.venus) }
    var marsPosition: PlanetPosition? { planet(.mars) }

    func planet(_ p: Planet) -> PlanetPosition? {
        planets.first { $0.planet == p }
    }

    /// Most significant synastry aspects between two charts — original engine.
    static func synastryAspects(
        chart1: NatalChart,
        chart2: NatalChart,
        limit: Int = 5
    ) -> [SynastryAspect] {
        var aspects: [SynastryAspect] = []
        for pos1 in chart1.planets {
            for pos2 in chart2.planets {
                let diff = abs(pos1.longitude - pos2.longitude)
                let angle = min(diff, 360 - diff)
                for type in AspectType.allCases {
                    let orb = abs(angle - type.angle)
                    if orb <= type.orb {
                        aspects.append(SynastryAspect(
                            planet1: pos1.planet,
                            chart1Sign: pos1.sign,
                            planet2: pos2.planet,
                            chart2Sign: pos2.sign,
                            type: type,
                            orb: orb
                        ))
                    }
                }
            }
        }
        return Array(aspects.sorted { $0.strength > $1.strength }.prefix(limit))
    }
}

nonisolated struct SynastryAspect: Equatable, Hashable, Codable, Sendable {
    let planet1: Planet
    let chart1Sign: ZodiacSign
    let planet2: Planet
    let chart2Sign: ZodiacSign
    let type: AspectType
    let orb: Double

    var strength: Double {
        max(0, 1.0 - (orb / type.orb))
    }

    var description: String {
        "\(planet1.glyph)\(planet1.name) \(type.glyph) \(planet2.glyph)\(planet2.name)"
    }
}

nonisolated enum NatalChartError: LocalizedError, Sendable {
    case invalidBirthDate
    case invalidBirthLocation
    case calculationFailed(String)
    case chartNotFound(userId: String)
    case storageFailure(String)

    var errorDescription: String? {
        switch self {
        case .invalidBirthDate:
            return "Geçersiz doğum tarihi. Lütfen doğru bir tarih girin."
        case .invalidBirthLocation:
            return "Doğum yeri bulunamadı. Lütfen geçerli bir şehir adı girin."
        case .calculationFailed(let reason):
            return "Doğum haritası hesaplanamadı: \(reason)"
        case .chartNotFound(let userId):
            return "Kullanıcı \(userId) için doğum haritası bulunamadı."
        case .storageFailure(let reason):
            return "Kayıt hatası: \(reason)"
        }
    }
}
