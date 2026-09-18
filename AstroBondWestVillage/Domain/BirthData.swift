import Foundation

nonisolated struct BirthLocation: Equatable, Hashable, Codable, Sendable {
    let city: String
    let country: String
    let latitude: Double
    let longitude: Double
    let utcOffset: Double

    static let unknown = BirthLocation(
        city: "Bilinmiyor", country: "", latitude: 0, longitude: 0, utcOffset: 0
    )
}

nonisolated struct BirthData: Equatable, Hashable, Codable, Sendable {
    let dateOfBirth: Date
    let timeOfBirth: BirthTime
    let location: BirthLocation

    nonisolated struct BirthTime: Equatable, Hashable, Codable, Sendable {
        let hour: Int
        let minute: Int
        let isKnown: Bool

        static let unknown = BirthTime(hour: 12, minute: 0, isKnown: false)

        static func known(hour: Int, minute: Int) -> BirthTime {
            BirthTime(hour: hour, minute: minute, isKnown: true)
        }

        var fractionalHour: Double {
            Double(hour) + Double(minute) / 60.0
        }
    }

    /// Local Julian Day Number including time — Universal Time = local birth time − UTC offset.
    func julianDay() -> Double {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = calendar.dateComponents([.year, .month, .day], from: dateOfBirth)
        let year = components.year ?? 2000
        let month = components.month ?? 1
        let day = components.day ?? 1
        let utHour = timeOfBirth.fractionalHour - location.utcOffset
        return julianDayNumber(year: year, month: month, day: day, hour: utHour)
    }
}

nonisolated func julianDayNumber(year: Int, month: Int, day: Int, hour: Double) -> Double {
    var y = year, m = month
    if m <= 2 { y -= 1; m += 12 }
    let a = Int(Double(y) / 100.0)
    let b = 2 - a + Int(Double(a) / 4.0)
    let jdBase = Double(Int(365.25 * Double(y + 4716)))
        + Double(Int(30.6001 * Double(m + 1)))
        + Double(day) + Double(b) - 1524.5
    return jdBase + hour / 24.0
}
