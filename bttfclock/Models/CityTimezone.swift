import Foundation

/// A selectable city and the IANA timezone its clock is rendered in.
///
/// `id` is our own short slug (used as the persistence key), not the
/// IANA identifier — so we can rename or remap underlying timezones
/// without breaking users' saved selections.
struct CityTimezone: Codable, Equatable, Identifiable, Hashable {
    let id: String
    let displayName: String
    let timezoneIdentifier: String

    /// Resolved `TimeZone`. Falls back to GMT if the IANA identifier is
    /// somehow unknown on the running OS — never force-unwrap, a missing
    /// tzdata entry shouldn't crash the clock.
    var timezone: TimeZone {
        TimeZone(identifier: timezoneIdentifier) ?? .gmt
    }
}

/// The curated list of cities offered in the settings picker.
///
/// The catalog is deliberately small (~40 entries) rather than exposing
/// the full IANA tzdata list: most IANA zones are redundant aliases
/// (`Etc/GMT-4`, `America/Fort_Wayne`, …) and a short, recognisable list
/// is easier to scan through when adding a new city.
///
/// `hill_valley` is an easter-egg alias for `America/Los_Angeles`.
enum CityCatalog {
    static let all: [CityTimezone] = [
        CityTimezone(id: "london", displayName: "LONDON", timezoneIdentifier: "Europe/London"),
        CityTimezone(id: "new_york", displayName: "NEW YORK", timezoneIdentifier: "America/New_York"),
        CityTimezone(id: "hong_kong", displayName: "HONG KONG", timezoneIdentifier: "Asia/Hong_Kong"),
        CityTimezone(id: "los_angeles", displayName: "LOS ANGELES", timezoneIdentifier: "America/Los_Angeles"),
        CityTimezone(id: "chicago", displayName: "CHICAGO", timezoneIdentifier: "America/Chicago"),
        CityTimezone(id: "toronto", displayName: "TORONTO", timezoneIdentifier: "America/Toronto"),
        CityTimezone(id: "mexico_city", displayName: "MEXICO CITY", timezoneIdentifier: "America/Mexico_City"),
        CityTimezone(id: "sao_paulo", displayName: "SAO PAULO", timezoneIdentifier: "America/Sao_Paulo"),
        CityTimezone(id: "buenos_aires", displayName: "BUENOS AIRES", timezoneIdentifier: "America/Argentina/Buenos_Aires"),
        CityTimezone(id: "reykjavik", displayName: "REYKJAVIK", timezoneIdentifier: "Atlantic/Reykjavik"),
        CityTimezone(id: "dublin", displayName: "DUBLIN", timezoneIdentifier: "Europe/Dublin"),
        CityTimezone(id: "paris", displayName: "PARIS", timezoneIdentifier: "Europe/Paris"),
        CityTimezone(id: "berlin", displayName: "BERLIN", timezoneIdentifier: "Europe/Berlin"),
        CityTimezone(id: "madrid", displayName: "MADRID", timezoneIdentifier: "Europe/Madrid"),
        CityTimezone(id: "rome", displayName: "ROME", timezoneIdentifier: "Europe/Rome"),
        CityTimezone(id: "amsterdam", displayName: "AMSTERDAM", timezoneIdentifier: "Europe/Amsterdam"),
        CityTimezone(id: "stockholm", displayName: "STOCKHOLM", timezoneIdentifier: "Europe/Stockholm"),
        CityTimezone(id: "athens", displayName: "ATHENS", timezoneIdentifier: "Europe/Athens"),
        CityTimezone(id: "istanbul", displayName: "ISTANBUL", timezoneIdentifier: "Europe/Istanbul"),
        CityTimezone(id: "moscow", displayName: "MOSCOW", timezoneIdentifier: "Europe/Moscow"),
        CityTimezone(id: "cairo", displayName: "CAIRO", timezoneIdentifier: "Africa/Cairo"),
        CityTimezone(id: "lagos", displayName: "LAGOS", timezoneIdentifier: "Africa/Lagos"),
        CityTimezone(id: "johannesburg", displayName: "JOHANNESBURG", timezoneIdentifier: "Africa/Johannesburg"),
        CityTimezone(id: "dubai", displayName: "DUBAI", timezoneIdentifier: "Asia/Dubai"),
        CityTimezone(id: "tehran", displayName: "TEHRAN", timezoneIdentifier: "Asia/Tehran"),
        CityTimezone(id: "karachi", displayName: "KARACHI", timezoneIdentifier: "Asia/Karachi"),
        CityTimezone(id: "mumbai", displayName: "MUMBAI", timezoneIdentifier: "Asia/Kolkata"),
        CityTimezone(id: "bangkok", displayName: "BANGKOK", timezoneIdentifier: "Asia/Bangkok"),
        CityTimezone(id: "singapore", displayName: "SINGAPORE", timezoneIdentifier: "Asia/Singapore"),
        CityTimezone(id: "beijing", displayName: "BEIJING", timezoneIdentifier: "Asia/Shanghai"),
        CityTimezone(id: "tokyo", displayName: "TOKYO", timezoneIdentifier: "Asia/Tokyo"),
        CityTimezone(id: "seoul", displayName: "SEOUL", timezoneIdentifier: "Asia/Seoul"),
        CityTimezone(id: "sydney", displayName: "SYDNEY", timezoneIdentifier: "Australia/Sydney"),
        CityTimezone(id: "melbourne", displayName: "MELBOURNE", timezoneIdentifier: "Australia/Melbourne"),
        CityTimezone(id: "auckland", displayName: "AUCKLAND", timezoneIdentifier: "Pacific/Auckland"),
        CityTimezone(id: "honolulu", displayName: "HONOLULU", timezoneIdentifier: "Pacific/Honolulu"),
        CityTimezone(id: "anchorage", displayName: "ANCHORAGE", timezoneIdentifier: "America/Anchorage"),
        CityTimezone(id: "denver", displayName: "DENVER", timezoneIdentifier: "America/Denver"),
        CityTimezone(id: "vancouver", displayName: "VANCOUVER", timezoneIdentifier: "America/Vancouver"),
        CityTimezone(id: "hill_valley", displayName: "HILL VALLEY", timezoneIdentifier: "America/Los_Angeles")
    ]

    /// O(n) lookup by slug. n ≤ 40, so the linear scan is fine.
    static func city(withId id: String) -> CityTimezone? {
        all.first { $0.id == id }
    }

    /// Default selection on first launch and after Reset. Deliberately
    /// time-ordered across GMT offsets so each hour rolls down the
    /// display top-to-bottom (NY → London → HK).
    static let defaultSelection: [CityTimezone] = [
        city(withId: "new_york")!,
        city(withId: "london")!,
        city(withId: "hong_kong")!
    ]
}
