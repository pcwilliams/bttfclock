import SwiftUI

/// Shared palette for non-LED chrome — the painted metal plates and their
/// text colour. These are intentionally the same across all three rows
/// (regardless of row colour) because on the screen prop they are physical
/// DYMO-tape labels and silk-screened faceplate text, not LEDs.
enum Palette {
    /// Colour of the small DYMO-tape-style rectangles that back each field
    /// caption (MONTH / DAY / YEAR / HOUR / MIN) and each AM/PM lamp label.
    /// A slightly desaturated brick red, matching the dull-red tape used on
    /// the screen-used Time Circuits prop.
    static let captionPlateRed = Color(red: 0.60, green: 0.10, blue: 0.09)

    /// Off-white grey used for all chrome text (field captions, AM/PM
    /// letters, city names). Not pure white — the prop's silk-screen has
    /// a slightly worn cream look that reads as grey against the warm
    /// reds.
    static let chromeTextGrey = Color(red: 0.78, green: 0.78, blue: 0.75)

    /// Near-black background of the city-name plate at the bottom of each
    /// row. Slightly lifted off pure black so it still registers as a
    /// separate plate against the darker enclosure chassis.
    static let cityPlateBlack = Color(red: 0.04, green: 0.04, blue: 0.04)
}
