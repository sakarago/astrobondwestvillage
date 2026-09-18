import Foundation
import SwissEphemeris

@_silgen_name("swe_houses")
private func swe_houses(
    _ tjd_ut: Double,
    _ geolat: Double,
    _ geolon: Double,
    _ hsys: Int32,
    _ cusp: UnsafeMutablePointer<Double>,
    _ ascmc: UnsafeMutablePointer<Double>
) -> Int32

/// Swiss Ephemeris natal calculator — same engine as the original AstroBond app.
/// Planets: `swe_calc_ut` via SwissEphemeris.Coordinate (bundled sepl/semo/seas 1800–2399).
/// Houses: `swe_houses` Placidus (hsys 'P'); Whole Sign when birth time unknown.
///
/// Note: the SPM package's HouseSystem.placidus raw value is 0 (bug), so we call
/// swe_houses directly with ASCII 'P'.
actor SimplifiedAstronomyCalculator {
    private static let ephemerisLock = NSLock()
    private static var didConfigureEphemeris = false
    private static let placidusHSys = Int32(Character("P").asciiValue!)

    static func configureEphemerisIfNeeded() {
        ephemerisLock.lock()
        defer { ephemerisLock.unlock() }
        guard !didConfigureEphemeris else { return }
        JPLFileManager.setEphemerisPath()
        didConfigureEphemeris = true
    }

    func calculateNatalChart(birthData: BirthData, userId: String) throws -> NatalChart {
        Self.configureEphemerisIfNeeded()

        let jd = birthData.julianDay()
        let utDate = Date(julianDate: jd)
        let planetCoords = calculateAllPlanetCoordinates(at: utDate)

        let (houseCusps, ascLongitude, mcLongitude) = birthData.timeOfBirth.isKnown
            ? calculateSwissPlacidusHouses(
                jd: jd,
                latitude: birthData.location.latitude,
                longitude: birthData.location.longitude
              )
            : calculateWholeSignHouses(sunLongitude: planetCoords[.sun]?.longitude ?? 0)

        var planetPositions: [PlanetPosition] = []
        for planet in Planet.allCases {
            guard let coord = planetCoords[planet] else { continue }
            let longitude = normalize(coord.longitude)
            let sign = ZodiacSign.from(longitude: longitude)
            let degree = ZodiacSign.degreeWithinSign(longitude: longitude)
            let house = houseNumber(longitude: longitude, cusps: houseCusps)
            planetPositions.append(PlanetPosition(
                planet: planet,
                sign: sign,
                degree: degree,
                longitude: longitude,
                house: house,
                isRetrograde: isRetrograde(planet: planet, speedLongitude: coord.speedLongitude)
            ))
        }
        planetPositions.sort { $0.planet.rawValue < $1.planet.rawValue }

        var houseEntities: [HouseEntity] = []
        for i in 0..<12 {
            let cuspLong = houseCusps[i]
            let sign = ZodiacSign.from(longitude: cuspLong)
            let planetsInHouse = planetPositions.filter { $0.house == i + 1 }.map(\.planet)
            houseEntities.append(HouseEntity(
                number: i + 1,
                sign: sign,
                cuspLongitude: cuspLong,
                planets: planetsInHouse
            ))
        }

        let aspects = calculateAspects(positions: planetPositions)
        let (dominantElement, elementCounts) = calculateDominantElement(positions: planetPositions)
        let (dominantModality, modalityCounts) = calculateDominantModality(positions: planetPositions)

        return NatalChart(
            userId: userId,
            calculatedAt: Date(),
            birthData: birthData,
            planets: planetPositions,
            houses: houseEntities,
            aspects: aspects,
            ascendant: ZodiacPoint(longitude: ascLongitude),
            midheaven: ZodiacPoint(longitude: mcLongitude),
            dominantElement: dominantElement,
            dominantModality: dominantModality,
            elementCounts: elementCounts,
            modalityCounts: modalityCounts
        )
    }

    func calculateTransits(for date: Date) throws -> [PlanetPosition] {
        Self.configureEphemerisIfNeeded()
        let coords = calculateAllPlanetCoordinates(at: date)
        return Planet.allCases.compactMap { planet -> PlanetPosition? in
            guard let coord = coords[planet] else { return nil }
            let longitude = normalize(coord.longitude)
            return PlanetPosition(
                planet: planet,
                sign: ZodiacSign.from(longitude: longitude),
                degree: ZodiacSign.degreeWithinSign(longitude: longitude),
                longitude: longitude,
                house: 1,
                isRetrograde: isRetrograde(planet: planet, speedLongitude: coord.speedLongitude)
            )
        }.sorted { $0.planet.rawValue < $1.planet.rawValue }
    }

    private struct PlanetCoord {
        let longitude: Double
        let speedLongitude: Double
    }

    private func calculateAllPlanetCoordinates(at date: Date) -> [Planet: PlanetCoord] {
        var result: [Planet: PlanetCoord] = [:]
        for planet in Planet.allCases {
            let body = swissPlanet(for: planet)
            let coord = Coordinate<SwissEphemeris.Planet>(body: body, date: date)
            result[planet] = PlanetCoord(longitude: coord.longitude, speedLongitude: coord.speedLongitude)
        }
        return result
    }

    private func swissPlanet(for planet: Planet) -> SwissEphemeris.Planet {
        switch planet {
        case .sun: return .sun
        case .moon: return .moon
        case .mercury: return .mercury
        case .venus: return .venus
        case .mars: return .mars
        case .jupiter: return .jupiter
        case .saturn: return .saturn
        case .uranus: return .uranus
        case .neptune: return .neptune
        case .pluto: return .pluto
        }
    }

    private func isRetrograde(planet: Planet, speedLongitude: Double) -> Bool {
        switch planet {
        case .sun, .moon: return false
        default: return speedLongitude < 0
        }
    }

    private func calculateSwissPlacidusHouses(
        jd: Double,
        latitude: Double,
        longitude: Double
    ) -> ([Double], Double, Double) {
        var cuspBuffer = [Double](repeating: 0, count: 13)
        var ascmcBuffer = [Double](repeating: 0, count: 10)

        _ = cuspBuffer.withUnsafeMutableBufferPointer { cuspPtr in
            ascmcBuffer.withUnsafeMutableBufferPointer { ascmcPtr in
                swe_houses(
                    jd,
                    latitude,
                    longitude,
                    Self.placidusHSys,
                    cuspPtr.baseAddress!,
                    ascmcPtr.baseAddress!
                )
            }
        }

        let asc = normalize(ascmcBuffer[0])
        let mc = normalize(ascmcBuffer[1])
        var cusps = Array(repeating: 0.0, count: 12)
        for i in 0..<12 {
            cusps[i] = normalize(cuspBuffer[i + 1])
        }
        return (cusps, asc, mc)
    }

    private func calculateWholeSignHouses(sunLongitude: Double) -> ([Double], Double, Double) {
        let ascLongitude = sunLongitude
        let ascSign = ZodiacSign.from(longitude: ascLongitude)
        let firstHouseCusp = ascSign.startDegree
        let cusps = (0..<12).map { i in normalize(firstHouseCusp + Double(i) * 30.0) }
        let mc = normalize(firstHouseCusp + 270)
        return (cusps, firstHouseCusp, mc)
    }

    private func houseNumber(longitude: Double, cusps: [Double]) -> Int {
        let normalizedLong = normalize(longitude)
        for i in 0..<12 {
            let start = cusps[i]
            let end = cusps[(i + 1) % 12]
            if start <= end {
                if normalizedLong >= start && normalizedLong < end { return i + 1 }
            } else if normalizedLong >= start || normalizedLong < end {
                return i + 1
            }
        }
        return 1
    }

    private func calculateAspects(positions: [PlanetPosition]) -> [AspectEntity] {
        var aspects: [AspectEntity] = []
        for i in 0..<positions.count {
            for j in (i + 1)..<positions.count {
                let p1 = positions[i]
                let p2 = positions[j]
                let diff = abs(p1.longitude - p2.longitude)
                let angle = min(diff, 360 - diff)
                for type in AspectType.allCases {
                    let orb = abs(angle - type.angle)
                    if orb <= type.orb {
                        aspects.append(AspectEntity(
                            planet1: p1.planet,
                            planet2: p2.planet,
                            type: type,
                            orb: orb,
                            isApplying: p1.planet.isPersonal && !p2.planet.isPersonal
                        ))
                        break
                    }
                }
            }
        }
        return aspects.sorted { $0.strength > $1.strength }
    }

    private func calculateDominantElement(positions: [PlanetPosition]) -> (ZodiacSign.Element, [ZodiacSign.Element: Int]) {
        var counts: [ZodiacSign.Element: Int] = [.fire: 0, .earth: 0, .air: 0, .water: 0]
        for pos in positions {
            counts[pos.sign.element, default: 0] += pos.planet.isPersonal ? 2 : 1
        }
        let dominant = counts.max { $0.value < $1.value }?.key ?? .fire
        return (dominant, counts)
    }

    private func calculateDominantModality(positions: [PlanetPosition]) -> (ZodiacSign.Modality, [ZodiacSign.Modality: Int]) {
        var counts: [ZodiacSign.Modality: Int] = [.cardinal: 0, .fixed: 0, .mutable: 0]
        for pos in positions {
            counts[pos.sign.modality, default: 0] += pos.planet.isPersonal ? 2 : 1
        }
        let dominant = counts.max { $0.value < $1.value }?.key ?? .cardinal
        return (dominant, counts)
    }

    private func normalize(_ degrees: Double) -> Double {
        ((degrees.truncatingRemainder(dividingBy: 360)) + 360).truncatingRemainder(dividingBy: 360)
    }
}
