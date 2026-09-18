import Foundation
import Supabase

struct ProfileSnapshot: Equatable, Sendable {
    var userId: String
    var displayName: String
    var age: Int
    var gender: Gender
    var bio: String
    var city: String?
    /// Owner-only — pulled from `birth_data.city`, which stores the
    /// neighbourhood/district (see `District`), not the metropolitan city.
    var district: String?
    var sunSign: ZodiacSign?
    var moonSign: ZodiacSign?
    var risingSign: ZodiacSign?
    var photoURL: String?
    var cartoonAvatarId: String?
    var birthDate: Date?
    var hasBirthData: Bool
    var timeKnown: Bool
    var timeHour: Int
    var timeMinute: Int
    var latitude: Double?
    var longitude: Double?
    var utcOffset: Double?
    var country: String?

    /// "İstanbul, Kadıköy" when both are known, else whatever is available.
    var placeLabel: String? {
        switch (city, district) {
        case let (c?, d?) where !d.isEmpty && d != c: return "\(c), \(d)"
        case let (c?, _): return c
        case let (_, d?): return d
        default: return nil
        }
    }
}

enum ProfileServiceError: LocalizedError {
    case network(String)
    var errorDescription: String? {
        switch self {
        case .network(let m): return m
        }
    }
}

final class ProfileService: Sendable {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientProvider.shared.client) {
        self.client = client
    }

    func fetchSnapshot(userId: String) async throws -> ProfileSnapshot? {
        struct Row: Decodable {
            let id: String
            let displayName: String
            let age: Int?
            let gender: String
            let bio: String?
            let city: String?
            let sunSign: String?
            let moonSign: String?
            let risingSign: String?
            let photoURL: String?
            let cartoonAvatarId: String?
            enum CodingKeys: String, CodingKey {
                case id, age, gender, city, bio
                case displayName = "display_name"
                case sunSign = "sun_sign"
                case moonSign = "moon_sign"
                case risingSign = "rising_sign"
                case photoURL = "profile_photo_url"
                case cartoonAvatarId = "cartoon_avatar_id"
            }
        }
        struct BirthRow: Decodable {
            let userId: String
            let dateOfBirth: String?
            let city: String?
            let country: String?
            let timeHour: Int?
            let timeMinute: Int?
            let timeKnown: Bool?
            let latitude: Double?
            let longitude: Double?
            let utcOffset: Double?
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case dateOfBirth = "date_of_birth"
                case city, country, latitude, longitude
                case timeHour = "time_hour"
                case timeMinute = "time_minute"
                case timeKnown = "time_known"
                case utcOffset = "utc_offset"
            }
        }

        do {
            let profiles: [Row] = try await client.from("profiles")
                .select("id,display_name,age,gender,bio,city,sun_sign,moon_sign,rising_sign,profile_photo_url,cartoon_avatar_id")
                .eq("id", value: userId)
                .execute()
                .value
            guard let p = profiles.first else { return nil }

            // birth_data is owner-only (RLS); this call only succeeds for the
            // signed-in user's own id, which is the only caller today.
            let births: [BirthRow] = try await client.from("birth_data")
                .select("user_id,date_of_birth,city,country,time_hour,time_minute,time_known,latitude,longitude,utc_offset")
                .eq("user_id", value: userId)
                .execute()
                .value

            let df = DateFormatter()
            df.calendar = Calendar(identifier: .gregorian)
            df.locale = Locale(identifier: "en_US_POSIX")
            df.timeZone = TimeZone(secondsFromGMT: 0)
            df.dateFormat = "yyyy-MM-dd"
            let birthDate = births.first?.dateOfBirth.flatMap { df.date(from: $0) }

            return ProfileSnapshot(
                userId: p.id.lowercased(),
                displayName: p.displayName,
                age: p.age ?? 18,
                gender: Gender.fromStableName(p.gender),
                bio: p.bio ?? "",
                city: p.city,
                district: births.first?.city,
                sunSign: ZodiacSign.fromEnglishName(p.sunSign),
                moonSign: ZodiacSign.fromEnglishName(p.moonSign),
                risingSign: ZodiacSign.fromEnglishName(p.risingSign),
                photoURL: p.photoURL,
                cartoonAvatarId: p.cartoonAvatarId,
                birthDate: birthDate,
                hasBirthData: !births.isEmpty && !p.displayName.trimmingCharacters(in: .whitespaces).isEmpty,
                timeKnown: births.first?.timeKnown ?? false,
                timeHour: births.first?.timeHour ?? 12,
                timeMinute: births.first?.timeMinute ?? 0,
                latitude: births.first?.latitude,
                longitude: births.first?.longitude,
                utcOffset: births.first?.utcOffset,
                country: births.first?.country
            )
        } catch {
            throw ProfileServiceError.network(error.localizedDescription)
        }
    }

    func updateProfile(
        userId: String,
        displayName: String,
        bio: String,
        city: CityOption,
        district: District,
        birthDate: Date?,
        cartoonAvatarId: String? = nil
    ) async throws {
        let cal = Calendar.current
        let age: Int
        let sun: ZodiacSign
        if let birthDate {
            age = max(18, cal.dateComponents([.year], from: birthDate, to: Date()).year ?? 18)
            let md = cal.dateComponents([.month, .day], from: birthDate)
            sun = ZodiacSign.sunSign(month: md.month ?? 1, day: md.day ?? 1)
        } else {
            age = 18
            sun = .aries
        }

        struct ProfilePatch: Encodable {
            let display_name: String
            let age: Int
            let bio: String
            let city: String
            let sun_sign: String
            let cartoon_avatar_id: String?
        }

        do {
            try await client.from("profiles")
                .update(ProfilePatch(
                    display_name: displayName,
                    age: age,
                    bio: bio,
                    city: city.name,
                    sun_sign: sun.englishName,
                    cartoon_avatar_id: cartoonAvatarId
                ))
                .eq("id", value: userId)
                .execute()

            struct BirthPatch: Encodable {
                let city: String
                let country: String
                let latitude: Double
                let longitude: Double
                let utc_offset: Double
                let date_of_birth: String?
            }
            let df = DateFormatter()
            df.calendar = Calendar(identifier: .gregorian)
            df.locale = Locale(identifier: "en_US_POSIX")
            df.timeZone = TimeZone(secondsFromGMT: 0)
            df.dateFormat = "yyyy-MM-dd"
            try await client.from("birth_data")
                .update(BirthPatch(
                    city: district.name,
                    country: city.country,
                    latitude: district.latitude,
                    longitude: district.longitude,
                    utc_offset: city.utcOffset,
                    date_of_birth: birthDate.map { df.string(from: $0) }
                ))
                .eq("user_id", value: userId)
                .execute()

            if let birthDate {
                let existing = try? await ChartService.shared.fetchBirthData(userId: userId)
                let time = existing?.timeOfBirth ?? .unknown
                let birth = BirthData(
                    dateOfBirth: birthDate,
                    timeOfBirth: time,
                    location: BirthLocation(
                        city: district.name,
                        country: city.country,
                        latitude: district.latitude,
                        longitude: district.longitude,
                        utcOffset: city.utcOffset
                    )
                )
                _ = try await ChartService.shared.calculateAndSave(userId: userId, birthData: birth)
            }
        } catch {
            throw ProfileServiceError.network(error.localizedDescription)
        }
    }

    func setFrozen(userId: String, frozen: Bool) async throws {
        struct FrozenAtUpdate: Encodable {
            let frozen_at: String?
        }
        do {
            let value: String?
            if frozen {
                let iso = ISO8601DateFormatter()
                iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                value = iso.string(from: Date())
            } else {
                value = nil
            }
            try await client.from("profiles")
                .update(FrozenAtUpdate(frozen_at: value))
                .eq("id", value: userId)
                .execute()
        } catch {
            throw ProfileServiceError.network(error.localizedDescription)
        }
    }

    func completeOnboarding(
        userId: String,
        displayName: String,
        gender: Gender,
        birthDate: Date,
        timeKnown: Bool,
        hour: Int,
        minute: Int,
        city: CityOption,
        district: District,
        genderPrefs: [Gender],
        cartoonAvatarId: String
    ) async throws -> NatalChart {
        let cal = Calendar.current
        let age = max(18, cal.dateComponents([.year], from: birthDate, to: Date()).year ?? 18)
        let md = cal.dateComponents([.month, .day], from: birthDate)
        let sun = ZodiacSign.sunSign(month: md.month ?? 1, day: md.day ?? 1)

        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd"

        struct ProfileUpsert: Encodable {
            let id: String
            let display_name: String
            let age: Int
            let gender: String
            let bio: String
            let city: String
            let sun_sign: String
            let moon_sign: String
            let rising_sign: String
            let cartoon_avatar_id: String
        }
        struct BirthUpsert: Encodable {
            let user_id: String
            let date_of_birth: String
            let time_hour: Int
            let time_minute: Int
            let time_known: Bool
            let city: String
            let country: String
            let latitude: Double
            let longitude: Double
            let utc_offset: Double
            let match_preferences: MatchPrefsJSON
        }
        struct MatchPrefsJSON: Encodable {
            let genderPreferences: [String]
            let ageMin: Int
            let ageMax: Int
        }

        let prefs = MatchPrefsJSON(
            genderPreferences: genderPrefs.map(\.stableName),
            ageMin: 18,
            ageMax: 99
        )

        do {
            try await client.from("profiles").upsert(
                ProfileUpsert(
                    id: userId,
                    display_name: displayName,
                    age: age,
                    gender: gender.stableName,
                    bio: "",
                    city: city.name,
                    sun_sign: sun.englishName,
                    moon_sign: sun.englishName,
                    rising_sign: sun.englishName,
                    cartoon_avatar_id: cartoonAvatarId
                )
            ).execute()

            try await client.from("birth_data").upsert(
                BirthUpsert(
                    user_id: userId,
                    date_of_birth: df.string(from: birthDate),
                    time_hour: timeKnown ? hour : 12,
                    time_minute: timeKnown ? minute : 0,
                    time_known: timeKnown,
                    city: district.name,
                    country: city.country,
                    latitude: district.latitude,
                    longitude: district.longitude,
                    utc_offset: city.utcOffset,
                    match_preferences: prefs
                )
            ).execute()

            let birth = BirthData(
                dateOfBirth: birthDate,
                timeOfBirth: timeKnown ? .known(hour: hour, minute: minute) : .unknown,
                location: BirthLocation(
                    city: district.name,
                    country: city.country,
                    latitude: district.latitude,
                    longitude: district.longitude,
                    utcOffset: city.utcOffset
                )
            )
            return try await ChartService.shared.calculateAndSave(userId: userId, birthData: birth)
        } catch {
            throw ProfileServiceError.network(error.localizedDescription)
        }
    }
}
