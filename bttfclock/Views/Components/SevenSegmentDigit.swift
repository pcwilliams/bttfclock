import SwiftUI

/// A single 7-segment numeric digit rendered from hand-drawn SwiftUI paths.
///
/// Stacks three layers inside a `ZStack`:
/// 1. **Ghost** — all seven segments filled with `color.ghost` so the unlit
///    segments are faintly visible, matching a real LED-behind-gel display.
/// 2. **Lit core** — only the segments active for this character, filled
///    with `color.litCore` (a pale bright tint).
/// 3. **Glow** — three stacked `.shadow` modifiers at increasing radii
///    produce the characteristic LED bloom.
///
/// The view is intrinsically aspect-ratio-constrained so it renders crisply
/// at any frame size.
struct SevenSegmentDigit: View {
    let character: Character
    let color: RowColor
    var italic: Bool = true

    var body: some View {
        let mask = SevenSegmentMap.mask(for: character)
        ZStack {
            SevenSegmentShape(mask: SevenSegmentShape.allOnMask, italic: italic)
                .fill(color.ghost)
            SevenSegmentShape(mask: mask, italic: italic)
                .fill(color.litCore)
                .shadow(color: color.bloom, radius: 2)
                .shadow(color: color.bloom, radius: 5)
                .shadow(color: color.lit.opacity(0.35), radius: 11)
        }
        .aspectRatio(SegmentAspect.sevenSeg, contentMode: .fit)
    }
}

/// A single 14-segment alphanumeric character (used for the 3-letter month
/// abbreviation). Same three-layer ghost/lit/glow composition as
/// `SevenSegmentDigit` but using the wider 14-segment grid so letters like
/// `M`, `N`, `V`, `W` render with their diagonal strokes.
struct FourteenSegmentChar: View {
    let character: Character
    let color: RowColor
    var italic: Bool = true

    var body: some View {
        let mask = FourteenSegmentMap.mask(for: character)
        ZStack {
            FourteenSegmentShape(mask: FourteenSegmentShape.allOnMask, italic: italic)
                .fill(color.ghost)
            FourteenSegmentShape(mask: mask, italic: italic)
                .fill(color.litCore)
                .shadow(color: color.bloom, radius: 2)
                .shadow(color: color.bloom, radius: 5)
                .shadow(color: color.lit.opacity(0.35), radius: 11)
        }
        .aspectRatio(SegmentAspect.fourteenSeg, contentMode: .fit)
    }
}
