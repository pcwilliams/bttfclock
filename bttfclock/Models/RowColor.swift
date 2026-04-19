import SwiftUI

/// The three colours of the Time Circuits rows, in fixed top-to-bottom
/// order matching the screen-used prop: red (destination time), green
/// (present time), amber (last time departed).
///
/// Each case carries five tints that together produce the LED-behind-gel
/// look: `lit` (saturated core), `litCore` (pale bright centre), `bloom`
/// (semi-transparent halo used as a `.shadow` colour), `ghost` (dim
/// unlit-segment colour visible through the window gel), and `windowTint`
/// (very dark tint behind the digits).
///
/// Colour is derived from the row's *slot index*, not from the selected
/// city — so moving a city to a new slot also changes its LED colour.
enum RowColor: Int, CaseIterable, Codable {
    case red = 0
    case green = 1
    case amber = 2

    /// Maps a 0-based row slot to its colour. Index 2 and above collapse
    /// to `.amber` so `CityStore.maxCities = 3` is never violated even if
    /// callers pass an out-of-range index.
    static func forIndex(_ index: Int) -> RowColor {
        switch index {
        case 0: return .red
        case 1: return .green
        default: return .amber
        }
    }

    /// Saturated row colour used for the colon dots, AM/PM lamps, and any
    /// non-segment element that needs to read unambiguously as red / green
    /// / amber.
    var lit: Color {
        switch self {
        case .red:   return Color(red: 1.00, green: 0.16, blue: 0.16)
        case .green: return Color(red: 0.20, green: 1.00, blue: 0.35)
        case .amber: return Color(red: 1.00, green: 0.70, blue: 0.00)
        }
    }

    /// Pale, light-tinted version of `lit` used as the fill for the lit
    /// segments of a character. The segments themselves are near-white;
    /// the surrounding glow provides the row colour.
    var litCore: Color {
        switch self {
        case .red:   return Color(red: 1.00, green: 0.55, blue: 0.45)
        case .green: return Color(red: 0.70, green: 1.00, blue: 0.75)
        case .amber: return Color(red: 1.00, green: 0.90, blue: 0.55)
        }
    }

    /// Semi-transparent row colour used for the `.shadow` bloom that
    /// surrounds each lit segment. 55% alpha is tuned so three stacked
    /// shadows add up to a visible halo without blowing out the digit.
    var bloom: Color {
        switch self {
        case .red:   return Color(red: 1.00, green: 0.16, blue: 0.10).opacity(0.55)
        case .green: return Color(red: 0.23, green: 1.00, blue: 0.30).opacity(0.55)
        case .amber: return Color(red: 1.00, green: 0.70, blue: 0.10).opacity(0.55)
        }
    }

    /// Very dim row-tinted fill used for *unlit* segments. On a real LED
    /// display the off segments are faintly visible through the coloured
    /// plexi gel; this tint reproduces that effect.
    var ghost: Color {
        switch self {
        case .red:   return Color(red: 0.22, green: 0.04, blue: 0.04)
        case .green: return Color(red: 0.04, green: 0.16, blue: 0.06)
        case .amber: return Color(red: 0.20, green: 0.12, blue: 0.02)
        }
    }

    /// Near-black row tint applied to the background of each per-field
    /// black window. Gives each display window a subtle colour cast that
    /// matches its row without competing with the lit segments.
    var windowTint: Color {
        switch self {
        case .red:   return Color(red: 0.08, green: 0.01, blue: 0.01)
        case .green: return Color(red: 0.01, green: 0.06, blue: 0.02)
        case .amber: return Color(red: 0.07, green: 0.04, blue: 0.00)
        }
    }
}
