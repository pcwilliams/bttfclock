import Foundation

/// Character-to-bitmask lookup for a 7-segment numeric display.
///
/// Segment layout (the traditional "A–G" naming, matched to bit index):
/// ```
///      ─A─
///     │   │
///     F   B
///     │   │
///      ─G─
///     │   │
///     E   C
///     │   │
///      ─D─
/// ```
/// Bit 0=A (top), 1=B (top-right), 2=C (bottom-right), 3=D (bottom),
/// 4=E (bottom-left), 5=F (top-left), 6=G (middle).
enum SevenSegmentMap {
    static func mask(for char: Character) -> UInt8 {
        switch char {
        case "0": return 0b0011_1111    // A B C D E F
        case "1": return 0b0000_0110    // B C
        case "2": return 0b0101_1011    // A B D E G
        case "3": return 0b0100_1111    // A B C D G
        case "4": return 0b0110_0110    // B C F G
        case "5": return 0b0110_1101    // A C D F G
        case "6": return 0b0111_1101    // A C D E F G
        case "7": return 0b0000_0111    // A B C
        case "8": return 0b0111_1111    // all
        case "9": return 0b0110_1111    // A B C D F G
        case "-": return 0b0100_0000    // G only
        case " ", "_": return 0
        default: return 0
        }
    }

    /// Test helper: extract a single segment bit from a mask.
    static func isSegmentOn(_ mask: UInt8, index: Int) -> Bool {
        (mask >> index) & 1 == 1
    }
}

/// Character-to-bitmask lookup for a 14-segment alphanumeric display.
///
/// Layout: six outer bars (A top, B upper-right, C lower-right, D bottom,
/// E lower-left, F upper-left), two half-middle horizontals (G1 left,
/// G2 right), two centre verticals (I upper, L lower), and four diagonals
/// spanning each quadrant from the centre outward (H upper-left, J
/// upper-right, K lower-right, M lower-left).
///
/// Bit indices: 0=A, 1=B, 2=C, 3=D, 4=E, 5=F, 6=G1, 7=G2, 8=H, 9=I, 10=J,
/// 11=K, 12=L, 13=M.
///
/// The letter set covers A–Z plus digits 0–9 and space/hyphen — enough
/// for every 3-letter month abbreviation that the clock will ever render.
enum FourteenSegmentMap {
    private static let table: [Character: UInt16] = [
        "A": 0b0000_0000_1111_0111, // A B C E F G1 G2
        "B": 0b0001_0010_1000_1111, // A B C D G2 I L
        "C": 0b0000_0000_0011_1001, // A D E F
        "D": 0b0001_0010_0000_1111, // A B C D I L
        "E": 0b0000_0000_1111_1001, // A D E F G1 G2
        "F": 0b0000_0000_1111_0001, // A E F G1 G2
        "G": 0b0000_0000_1011_1101, // A C D E F G2
        "H": 0b0000_0000_1111_0110, // B C E F G1 G2
        "I": 0b0001_0010_0000_1001, // A D I L
        "J": 0b0000_0000_0001_1110, // B C D E
        "K": 0b0000_1100_0111_0000, // E F G1 J K
        "L": 0b0000_0000_0011_1000, // D E F
        "M": 0b0000_0101_0011_0110, // B C E F H J
        "N": 0b0000_1001_0011_0110, // B C E F H K
        "O": 0b0000_0000_0011_1111, // A B C D E F
        "P": 0b0000_0000_1111_0011, // A B E F G1 G2
        "Q": 0b0000_1000_0011_1111, // A B C D E F K
        "R": 0b0000_1000_1111_0011, // A B E F G1 G2 K
        "S": 0b0000_0000_1110_1101, // A C D F G1 G2
        "T": 0b0001_0010_0000_0001, // A I L
        "U": 0b0000_0000_0011_1110, // B C D E F
        "V": 0b0010_1000_0010_0010, // B F K M
        "W": 0b0010_1000_0011_0110, // B C E F K M
        "X": 0b0010_1101_0000_0000, // H J K M
        "Y": 0b0001_0101_0000_0000, // H J L
        "Z": 0b0010_0100_0000_1001, // A D J M
        "0": 0b0010_0100_0011_1111, // A B C D E F J M (slashed zero)
        "1": 0b0000_0100_0000_0110, // B C J
        "2": 0b0000_0000_1101_1011, // A B D E G1 G2
        "3": 0b0000_0000_1000_1111, // A B C D G2
        "4": 0b0000_0000_1110_0110, // B C F G1 G2
        "5": 0b0000_0000_1110_1101, // A C D F G1 G2
        "6": 0b0000_0000_1111_1101, // A C D E F G1 G2
        "7": 0b0000_0000_0000_0111, // A B C
        "8": 0b0000_0000_1111_1111, // all outer + G1 G2
        "9": 0b0000_0000_1110_1111, // A B C D F G1 G2
        "-": 0b0000_0000_1100_0000, // G1 G2
        " ": 0,
        "_": 0
    ]

    /// Looks up the segment bitmask for `char`, case-insensitively.
    /// Returns 0 (all segments off) for any character not in the table.
    static func mask(for char: Character) -> UInt16 {
        table[Character(String(char).uppercased())] ?? 0
    }

    /// Test helper: extract a single segment bit from a mask.
    static func isSegmentOn(_ mask: UInt16, index: Int) -> Bool {
        (mask >> index) & 1 == 1
    }
}
