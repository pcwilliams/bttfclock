import Foundation

/// The six values a single Time Circuits row displays for one city, at
/// one instant, in that city's local time: 3-letter month, day, 4-digit
/// year, 12-hour hour, minute, and whether it's AM or PM.
///
/// Rendered as a plain struct (not an ObservableObject) because rows are
/// recomputed from scratch on every clock tick — there's no state to
/// mutate.
struct TimeReadout: Equatable {
    let month: String
    let day: Int
    let year: Int
    let hour12: Int
    let minute: Int
    let isAM: Bool

    /// Uppercase three-letter month abbreviations, in calendar order.
    static let monthAbbreviations = [
        "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
        "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
    ]

    /// Projects a UTC `instant` into its Gregorian-calendar representation
    /// in `timezone`, normalised for the Time Circuits display.
    ///
    /// - 24h → 12h conversion: `0` and `12` both render as `12`,
    ///   matching the convention that midnight is "12 AM" and noon is
    ///   "12 PM".
    /// - Month index is clamped to [0, 11] before looking up the
    ///   abbreviation so a malformed component never crashes.
    static func make(for instant: Date, in timezone: TimeZone) -> TimeReadout {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezone
        let comps = calendar.dateComponents([.month, .day, .year, .hour, .minute], from: instant)
        let monthIndex = (comps.month ?? 1) - 1
        let month = monthAbbreviations[max(0, min(11, monthIndex))]
        let rawHour = comps.hour ?? 0
        let isAM = rawHour < 12
        var hour12 = rawHour % 12
        if hour12 == 0 { hour12 = 12 }
        return TimeReadout(
            month: month,
            day: comps.day ?? 1,
            year: comps.year ?? 1985,
            hour12: hour12,
            minute: comps.minute ?? 0,
            isAM: isAM
        )
    }

    /// Display strings, each zero-padded to the fixed number of digits
    /// the LED panels hold so the displays never change width as the
    /// value changes.
    var dayDigits: String { String(format: "%02d", day) }
    var yearDigits: String { String(format: "%04d", max(0, min(9999, year))) }
    var hourDigits: String { String(format: "%02d", hour12) }
    var minuteDigits: String { String(format: "%02d", minute) }
}
