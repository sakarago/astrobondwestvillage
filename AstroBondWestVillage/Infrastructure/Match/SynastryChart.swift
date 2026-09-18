import Foundation

/// A single synastry comparison point — one astrological placement (Sun,
/// Moon, Ascendant, a personal planet, or the Midheaven) shown for *both*
/// people. This is the single source of truth for the Sinastri screen's
/// comparison table AND its dual-wheel drawing, so the two views can never
/// disagree with each other about what "their Moon" supposedly is.
struct SynastryPoint: Identifiable, Equatable {
    let id: String
    let label: String
    let glyph: String
    let mine: ZodiacSign
    let theirs: ZodiacSign
    /// Degree (0-29) + minute (0-59) within `mine`/`theirs`'s sign — used for
    /// the wheel's tick placement and the "12° 34'" readout under each glyph.
    let mineDegree: Int
    let mineMinute: Int
    let theirDegree: Int
    let theirMinute: Int
}

/// Builds the shared synastry point set for a match.
///
/// Real data wins whenever it's known: the signed-in user's actual Sun/Moon/
/// Ascendant (from their profile), and the match's actual Sun sign (the one
/// piece of their chart the backend already returns via `MatchCard.sunSign`).
/// Everything else — either person's Moon/Ascendant when not yet loaded, and
/// both people's Mercury/Venus/Mars/Midheaven, since this app has no full
/// ephemeris — is a stable per-person hash keyed off their user id, so it
/// never changes between screens or app launches. It reads as "a chart", not
/// as an obviously-random placeholder, without ever claiming to be a live
/// ephemeris reading.
enum SynastryChart {
    static func points(
        mySeed: String,
        mySun: ZodiacSign?,
        myMoon: ZodiacSign?,
        myRising: ZodiacSign?,
        card: MatchCard,
        myChart: NatalChart? = nil,
        theirChart: NatalChart? = nil
    ) -> [SynastryPoint] {
        if let myChart, let theirChart {
            return fromCharts(myChart, theirChart)
        }
        return hashedPoints(mySeed: mySeed, mySun: mySun, myMoon: myMoon, myRising: myRising, card: card)
    }

    static func fromCharts(_ mine: NatalChart, _ theirs: NatalChart) -> [SynastryPoint] {
        func pair(_ id: String, _ label: String, _ glyph: String, _ myP: ZodiacPoint, _ theirP: ZodiacPoint) -> SynastryPoint {
            SynastryPoint(
                id: id, label: label, glyph: glyph,
                mine: myP.sign, theirs: theirP.sign,
                mineDegree: Int(myP.degree),
                mineMinute: Int((myP.degree - Double(Int(myP.degree))) * 60),
                theirDegree: Int(theirP.degree),
                theirMinute: Int((theirP.degree - Double(Int(theirP.degree))) * 60)
            )
        }
        func planetPoint(_ chart: NatalChart, _ planet: Planet) -> ZodiacPoint {
            chart.planet(planet)?.zodiacPoint ?? ZodiacPoint(sign: chart.sunSign, degree: 0)
        }
        return [
            pair("sun", "Güneş", "☉", planetPoint(mine, .sun), planetPoint(theirs, .sun)),
            pair("moon", "Ay", "☽", planetPoint(mine, .moon), planetPoint(theirs, .moon)),
            pair("rising", "Yükselen", "↑", mine.ascendant, theirs.ascendant),
            pair("mercury", "Merkür", "☿", planetPoint(mine, .mercury), planetPoint(theirs, .mercury)),
            pair("venus", "Venüs", "♀", planetPoint(mine, .venus), planetPoint(theirs, .venus)),
            pair("mars", "Mars", "♂", planetPoint(mine, .mars), planetPoint(theirs, .mars)),
            pair("mc", "MC (Tepe)", "MC", mine.midheaven, theirs.midheaven),
        ]
    }

    private static func hashedPoints(
        mySeed: String,
        mySun: ZodiacSign?,
        myMoon: ZodiacSign?,
        myRising: ZodiacSign?,
        card: MatchCard
    ) -> [SynastryPoint] {
        var mine = SynastrySeed(seed: stableHash(mySeed))
        var theirs = SynastrySeed(seed: stableHash(card.id))

        func resolvedSign(_ known: ZodiacSign?, _ rng: inout SynastrySeed) -> ZodiacSign {
            known ?? ZodiacSign.allCases[Int(rng.next() * 12) % 12]
        }

        func degree(_ rng: inout SynastrySeed) -> (Int, Int) {
            (Int(rng.next() * 30), Int(rng.next() * 60))
        }

        let mySunSign = resolvedSign(mySun, &mine)
        let myMoonSign = resolvedSign(myMoon, &mine)
        let myRisingSign = resolvedSign(myRising, &mine)
        let theirSunSign = resolvedSign(card.sunSign, &theirs)
        let theirMoonSign = resolvedSign(card.moonSign, &theirs)
        let theirRisingSign = resolvedSign(card.risingSign, &theirs)

        var rows: [SynastryPoint] = []
        func add(_ id: String, _ label: String, _ glyph: String, _ myS: ZodiacSign, _ theirS: ZodiacSign) {
            let (md, mm) = degree(&mine)
            let (td, tm) = degree(&theirs)
            rows.append(SynastryPoint(id: id, label: label, glyph: glyph, mine: myS, theirs: theirS,
                                       mineDegree: md, mineMinute: mm, theirDegree: td, theirMinute: tm))
        }

        add("sun", "Güneş", "☉", mySunSign, theirSunSign)
        add("moon", "Ay", "☽", myMoonSign, theirMoonSign)
        add("rising", "Yükselen", "↑", myRisingSign, theirRisingSign)
        add("mercury", "Merkür", "☿", resolvedSign(nil, &mine), resolvedSign(nil, &theirs))
        add("venus", "Venüs", "♀", resolvedSign(nil, &mine), resolvedSign(nil, &theirs))
        add("mars", "Mars", "♂", resolvedSign(nil, &mine), resolvedSign(nil, &theirs))
        add("mc", "MC (Tepe)", "MC", resolvedSign(nil, &mine), resolvedSign(nil, &theirs))
        return rows
    }

    fileprivate static func stableHash(_ s: String) -> UInt64 {
        var h: UInt64 = 14695981039346656037
        for b in s.utf8 {
            h ^= UInt64(b)
            h &*= 1099511628211
        }
        return h
    }
}

/// Tiny deterministic PRNG — same recipe used elsewhere in the match feature
/// (`CosmicMatchWheel`'s private `Seeded`), duplicated here under its own
/// name (rather than shared) to keep this small domain-ish file free of
/// view-layer imports without colliding with the other file-private copies.
struct SynastrySeed {
    private var state: UInt64
    init(seed: UInt64) { state = seed &* 0x9E3779B97F4A7C15 }
    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1
        return Double((state >> 11) & 0x1FFFFF) / Double(0x1FFFFF)
    }
}

extension MatchCard {
    /// Deterministic Moon sign for this candidate — used anywhere the match's
    /// full chart needs to be *shown* (comparison table, dual wheel) before
    /// their real chart data exists in this app's backend.
    var derivedMoonSign: ZodiacSign {
        SynastryChart.points(mySeed: "x", mySun: nil, myMoon: nil, myRising: nil, card: self)
            .first { $0.id == "moon" }?.theirs ?? .cancer
    }

    var derivedRisingSign: ZodiacSign {
        SynastryChart.points(mySeed: "x", mySun: nil, myMoon: nil, myRising: nil, card: self)
            .first { $0.id == "rising" }?.theirs ?? .leo
    }
}
