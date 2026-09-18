import Foundation
import Supabase

/// Loads, computes, and persists natal charts using the original Swiss Ephemeris engine.
final class ChartService: Sendable {
    static let shared = ChartService()
    static let engineVersion = "swiss-ephemeris-v5"

    private let client: SupabaseClient
    private let calculator = SimplifiedAstronomyCalculator()

    init(client: SupabaseClient = SupabaseClientProvider.shared.client) {
        self.client = client
    }

    func fetch(userId: String) async throws -> NatalChart? {
        struct Row: Decodable {
            let userId: String
            let chartJSON: NatalChart
            let engineVersion: String?
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case chartJSON = "chart_json"
                case engineVersion = "engine_version"
            }
        }
        do {
            let rows: [Row] = try await client
                .from("charts")
                .select("user_id,chart_json,engine_version")
                .eq("user_id", value: userId)
                .execute()
                .value
            guard let row = rows.first else { return nil }
            if row.engineVersion != Self.engineVersion || !Self.isFullSwissChart(row.chartJSON) {
                return nil
            }
            return row.chartJSON
        } catch {
            return nil
        }
    }

    /// Other users: only a stored Swiss Ephemeris chart. Never invent placements
    /// from sun/moon/rising labels — that was a sign-level stand-in, not a birth map.
    func fetchOrSynthesize(
        userId: String,
        sun: ZodiacSign? = nil,
        moon: ZodiacSign? = nil,
        rising: ZodiacSign? = nil
    ) async -> NatalChart? {
        try? await fetch(userId: userId)
    }

    @discardableResult
    func ensureOwnChart(userId: String) async throws -> NatalChart? {
        if let existing = try await fetch(userId: userId), Self.isFullSwissChart(existing) {
            return existing
        }
        guard let birth = try await fetchBirthData(userId: userId) else { return nil }
        return try await calculateAndSave(userId: userId, birthData: birth)
    }

    @discardableResult
    func calculateAndSave(userId: String, birthData: BirthData) async throws -> NatalChart {
        let chart = try await calculator.calculateNatalChart(birthData: birthData, userId: userId)
        try await save(chart)
        return chart
    }

    func calculateTransits(for date: Date) async throws -> [PlanetPosition] {
        try await calculator.calculateTransits(for: date)
    }

    private func save(_ chart: NatalChart) async throws {
        let sanitized = Self.stripBirthData(from: chart)
        struct ChartUpsert: Encodable {
            let user_id: String
            let chart_json: NatalChart
            let engine_version: String
        }
        struct ProfileSigns: Encodable {
            let sun_sign: String
            let moon_sign: String
            let rising_sign: String
            let dominant_element: String
        }
        do {
            try await client.from("charts").upsert(
                ChartUpsert(
                    user_id: chart.userId,
                    chart_json: sanitized,
                    engine_version: Self.engineVersion
                )
            ).execute()
            do {
                try await client.from("profiles").update(
                    ProfileSigns(
                        sun_sign: chart.sunSign.englishName,
                        moon_sign: chart.moonSign.englishName,
                        rising_sign: chart.risingSign.englishName,
                        dominant_element: chart.dominantElement.labelTR
                    )
                ).eq("id", value: chart.userId).execute()
            } catch {
                struct ProfileSignsMinimal: Encodable {
                    let sun_sign: String
                    let moon_sign: String
                    let rising_sign: String
                }
                try await client.from("profiles").update(
                    ProfileSignsMinimal(
                        sun_sign: chart.sunSign.englishName,
                        moon_sign: chart.moonSign.englishName,
                        rising_sign: chart.risingSign.englishName
                    )
                ).eq("id", value: chart.userId).execute()
            }
        } catch {
            throw NatalChartError.storageFailure(error.localizedDescription)
        }
    }

    func fetchBirthData(userId: String) async throws -> BirthData? {
        struct BirthRow: Decodable {
            let dateOfBirth: String?
            let timeHour: Int?
            let timeMinute: Int?
            let timeKnown: Bool?
            let city: String?
            let country: String?
            let latitude: Double?
            let longitude: Double?
            let utcOffset: Double?
            enum CodingKeys: String, CodingKey {
                case dateOfBirth = "date_of_birth"
                case timeHour = "time_hour"
                case timeMinute = "time_minute"
                case timeKnown = "time_known"
                case city, country, latitude, longitude
                case utcOffset = "utc_offset"
            }
        }
        let rows: [BirthRow] = try await client
            .from("birth_data")
            .select("date_of_birth,time_hour,time_minute,time_known,city,country,latitude,longitude,utc_offset")
            .eq("user_id", value: userId)
            .execute()
            .value
        guard let row = rows.first, let dateString = row.dateOfBirth, let date = Self.dateOnly(dateString) else {
            return nil
        }
        let known = row.timeKnown ?? false
        return BirthData(
            dateOfBirth: date,
            timeOfBirth: known
                ? .known(hour: row.timeHour ?? 12, minute: row.timeMinute ?? 0)
                : .unknown,
            location: BirthLocation(
                city: row.city ?? "",
                country: row.country ?? "",
                latitude: row.latitude ?? 0,
                longitude: row.longitude ?? 0,
                utcOffset: row.utcOffset ?? 0
            )
        )
    }

    private static func dateOnly(_ s: String) -> Date? {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd"
        return df.date(from: String(s.prefix(10)))
    }

    /// A real Swiss Ephemeris natal has 10 bodies plus aspects. The old
    /// sign-level `synthesized` helper had 10 planets and zero aspects.
    private static func isFullSwissChart(_ chart: NatalChart) -> Bool {
        chart.planets.count >= 10 && !chart.aspects.isEmpty
    }

    /// Public `charts` rows must not contain real birth date/time/place.
    /// Only `timeOfBirth.isKnown` is preserved — the compatibility engine needs it for Ascendant weight.
    private static func stripBirthData(from chart: NatalChart) -> NatalChart {
        let placeholderTime: BirthData.BirthTime = chart.birthData.timeOfBirth.isKnown
            ? .known(hour: 12, minute: 0)
            : .unknown
        return NatalChart(
            userId: chart.userId,
            calculatedAt: chart.calculatedAt,
            birthData: BirthData(
                dateOfBirth: Date(timeIntervalSince1970: 0),
                timeOfBirth: placeholderTime,
                location: .unknown
            ),
            planets: chart.planets,
            houses: chart.houses,
            aspects: chart.aspects,
            ascendant: chart.ascendant,
            midheaven: chart.midheaven,
            dominantElement: chart.dominantElement,
            dominantModality: chart.dominantModality,
            elementCounts: chart.elementCounts,
            modalityCounts: chart.modalityCounts
        )
    }
}
