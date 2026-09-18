import Foundation

/// Original AstroBond compatibility engine — 100-point synastry:
/// Sun 15 + Moon 20 + Venus–Mars 25 + Ascendant 15 + composite aspects 25.
nonisolated final class CalculateCompatibilityUseCase: Sendable {
    func execute(chart1: NatalChart, chart2: NatalChart) -> CompatibilityReport {
        var breakdown: [CategoryScore] = []
        var strengths: [String] = []
        var challenges: [String] = []

        let sunResult = scoreSunCompatibility(sign1: chart1.sunSign, sign2: chart2.sunSign)
        breakdown.append(sunResult.score)
        strengths.append(contentsOf: sunResult.strengths)
        challenges.append(contentsOf: sunResult.challenges)

        let moonResult = scoreMoonCompatibility(sign1: chart1.moonSign, sign2: chart2.moonSign)
        breakdown.append(moonResult.score)
        strengths.append(contentsOf: moonResult.strengths)
        challenges.append(contentsOf: moonResult.challenges)

        let venusMarsResult = scoreVenusMars(chart1: chart1, chart2: chart2)
        breakdown.append(venusMarsResult.score)
        strengths.append(contentsOf: venusMarsResult.strengths)
        challenges.append(contentsOf: venusMarsResult.challenges)

        let bothHaveBirthTime = chart1.birthData.timeOfBirth.isKnown && chart2.birthData.timeOfBirth.isKnown
        if bothHaveBirthTime {
            let ascResult = scoreAscendantCompatibility(asc1: chart1.risingSign, asc2: chart2.risingSign)
            breakdown.append(ascResult.score)
            strengths.append(contentsOf: ascResult.strengths)
            challenges.append(contentsOf: ascResult.challenges)
        } else {
            breakdown.append(CategoryScore(
                category: .ascendant,
                score: 0,
                maxScore: 0,
                description: "Doğum saati bilinmediğinden bu kategori değerlendirilmedi."
            ))
        }

        let synastryAspects = NatalChart.synastryAspects(chart1: chart1, chart2: chart2, limit: 5)
        let compositeResult = scoreCompositeAspects(aspects: synastryAspects)
        breakdown.append(compositeResult.score)
        strengths.append(contentsOf: compositeResult.strengths)
        challenges.append(contentsOf: compositeResult.challenges)

        let totalScore = min(100, max(0, breakdown.reduce(0) { $0 + $1.score }))
        let label = CompatibilityLabel.from(score: totalScore)

        return CompatibilityReport(
            userId1: chart1.userId,
            userId2: chart2.userId,
            totalScore: totalScore,
            breakdown: breakdown,
            strengths: Array(strengths.prefix(5)),
            challenges: Array(challenges.prefix(3)),
            overallLabel: label,
            topSynastryAspects: synastryAspects,
            calculatedAt: Date()
        )
    }

    private struct ScoringResult {
        let score: CategoryScore
        let strengths: [String]
        let challenges: [String]
    }

    private func scoreSunCompatibility(sign1: ZodiacSign, sign2: ZodiacSign) -> ScoringResult {
        var points = 0
        var strengths: [String] = []
        var challenges: [String] = []

        if sign1 == sign2 {
            points = 15
            strengths.append("Aynı Güneş burcu — temel değerlerde derin bir anlayış paylaşıyorsunuz.")
        } else if sign1.element == sign2.element {
            points = 15
            strengths.append("\(sign1.element.labelTR) elementi paylaşıyorsunuz — doğal bir uyum var.")
        } else if sign1.element.isComplementary(to: sign2.element) {
            points = 10
            strengths.append("Tamamlayıcı elementler (\(sign1.element.labelTR)-\(sign2.element.labelTR)) — birbirinizi dengeleyen enerjiler.")
        } else if sign1.isSquare(to: sign2) {
            points = 2
            challenges.append("\(sign1.labelTR) ile \(sign2.labelTR) kare açısında — ortak noktalar bulmak çaba gerektirebilir.")
        } else {
            points = 5
        }

        return ScoringResult(
            score: CategoryScore(
                category: .sunSign,
                score: points,
                maxScore: 15,
                description: "\(sign1.glyph) \(sign1.labelTR) × \(sign2.glyph) \(sign2.labelTR)"
            ),
            strengths: strengths,
            challenges: challenges
        )
    }

    private func scoreMoonCompatibility(sign1: ZodiacSign, sign2: ZodiacSign) -> ScoringResult {
        var points = 0
        var strengths: [String] = []
        var challenges: [String] = []

        if sign1 == sign2 {
            points = 20
            strengths.append("Aynı Ay burcu — duygusal dünyalarınız mükemmel uyum içinde.")
        } else if sign1.element == sign2.element {
            points = 12
            strengths.append("Ay burçlarınız aynı elementte — duygusal anlayış güçlü.")
        } else if sign1.isTrine(to: sign2) {
            points = 15
            strengths.append("Ay burçları üçgen açısında — duygusal akış doğal ve rahat.")
        } else if sign1.isSextile(to: sign2) {
            points = 15
            strengths.append("Ay burçları sekstil açısında — duygusal iletişim akıcı.")
        } else if sign1.isOpposite(to: sign2) {
            points = 8
            strengths.append("Karşıt Ay burçları — farklı duygusal ihtiyaçlar farkındalıkla köprü kurabilir.")
        } else if sign1.isSquare(to: sign2) {
            points = 3
            challenges.append("Ay burçları kare açısında — duygusal ihtiyaçlar zaman zaman çatışabilir.")
        } else {
            points = 6
        }

        return ScoringResult(
            score: CategoryScore(
                category: .moonSign,
                score: points,
                maxScore: 20,
                description: "\(sign1.glyph) \(sign1.labelTR) Ayı × \(sign2.glyph) \(sign2.labelTR) Ayı"
            ),
            strengths: strengths,
            challenges: challenges
        )
    }

    private func scoreVenusMars(chart1: NatalChart, chart2: NatalChart) -> ScoringResult {
        var strengths: [String] = []
        var challenges: [String] = []

        guard let v1 = chart1.venusPosition, let m1 = chart1.marsPosition,
              let v2 = chart2.venusPosition, let m2 = chart2.marsPosition else {
            return ScoringResult(
                score: CategoryScore(category: .venusMars, score: 12, maxScore: 25, description: "Venüs-Mars verisi eksik"),
                strengths: [],
                challenges: []
            )
        }

        let score1 = venusMarsAspectScore(venus: v1, mars: m2)
        let score2 = venusMarsAspectScore(venus: v2, mars: m1)
        let points = max(score1.points, score2.points)
        if score1.points >= score2.points {
            strengths.append(contentsOf: score1.strengths)
            challenges.append(contentsOf: score1.challenges)
        } else {
            strengths.append(contentsOf: score2.strengths)
            challenges.append(contentsOf: score2.challenges)
        }

        if v1.sign.element.isComplementary(to: m2.sign.element) {
            strengths.append("Venüs ve Mars elementleri tamamlayıcı — çekim güçlü.")
        }

        return ScoringResult(
            score: CategoryScore(
                category: .venusMars,
                score: points,
                maxScore: 25,
                description: "Venüs \(v1.sign.glyph) × Mars \(m2.sign.glyph)"
            ),
            strengths: strengths,
            challenges: challenges
        )
    }

    private struct VenusMarsScore {
        let points: Int
        let strengths: [String]
        let challenges: [String]
    }

    private func venusMarsAspectScore(venus: PlanetPosition, mars: PlanetPosition) -> VenusMarsScore {
        let diff = abs(venus.longitude - mars.longitude)
        let angle = min(diff, 360 - diff)
        if let aspect = AspectType.from(angleDifference: angle) {
            switch aspect {
            case .conjunction, .trine:
                return VenusMarsScore(
                    points: 25,
                    strengths: ["Venüs ve Mars güçlü bir uyum içinde — romantik çekim yoğun."],
                    challenges: []
                )
            case .sextile:
                return VenusMarsScore(
                    points: 18,
                    strengths: ["Venüs-Mars sekstil — romantik enerji akıcı ve doğal."],
                    challenges: []
                )
            case .opposition:
                return VenusMarsScore(
                    points: 12,
                    strengths: ["Venüs-Mars karşıtlığı — güçlü çekim, farkındalık gerektirir."],
                    challenges: []
                )
            case .square:
                return VenusMarsScore(
                    points: 10,
                    strengths: [],
                    challenges: ["Venüs-Mars kare — tutku var ama sürtüşme olabilir."]
                )
            }
        }
        return VenusMarsScore(points: 5, strengths: [], challenges: [])
    }

    private func scoreAscendantCompatibility(asc1: ZodiacSign, asc2: ZodiacSign) -> ScoringResult {
        var points = 0
        var strengths: [String] = []
        let challenges: [String] = []

        if asc1.isOpposite(to: asc2) {
            points = 15
            strengths.append("Karşıt yükselen burçlar — 'karşıtlar çekilir' dinamiği güçlü.")
        } else if asc1.element == asc2.element {
            points = 15
            strengths.append("Yükselen burçlar aynı elementte — ilk izlenim ve iletişim doğal.")
        } else if asc1.isTrine(to: asc2) {
            points = 12
            strengths.append("Yükselen burçlar üçgen açısında — birliktelik akıcı ve rahat hissettiriyor.")
        } else {
            points = 8
        }

        return ScoringResult(
            score: CategoryScore(
                category: .ascendant,
                score: points,
                maxScore: 15,
                description: "\(asc1.glyph) \(asc1.labelTR) × \(asc2.glyph) \(asc2.labelTR) Yükselen"
            ),
            strengths: strengths,
            challenges: challenges
        )
    }

    private func scoreCompositeAspects(aspects: [SynastryAspect]) -> ScoringResult {
        var points = 0
        var strengths: [String] = []
        var challenges: [String] = []

        for aspect in aspects.prefix(5) {
            if aspect.type.isHarmonious {
                let isBenefic = aspect.planet1.isBenefic || aspect.planet2.isBenefic
                points += isBenefic ? 5 : 4
                strengths.append("\(aspect.description) — \(aspect.type.rawValue.lowercased()) enerjisi uyumlu.")
            } else {
                let isMalefic = aspect.planet1.isMalefic || aspect.planet2.isMalefic
                points -= isMalefic ? 2 : 1
                challenges.append("\(aspect.description) — dikkat ve farkındalık gerektirir.")
            }
        }

        points = max(0, min(25, points))

        return ScoringResult(
            score: CategoryScore(
                category: .composite,
                score: points,
                maxScore: 25,
                description: "\(aspects.count) önemli sinastri aspekti"
            ),
            strengths: strengths,
            challenges: challenges
        )
    }
}
