import SwiftUI

/// A single Time Circuits row — one city's readout plus its black-on-dark
/// name plate. Given to a `RowPanel`, three of these stacked form the
/// complete display.
///
/// Scales as a unit: the whole `VStack(displayRow, cityPlate)` is
/// rendered at its fixed natural size, then a `GeometryReader` +
/// `.scaleEffect` scales it up or down to fit the offered space while
/// `.aspectRatio` preserves the row's proportions. This means the
/// caption plates, digits, AM/PM block and city plate all scale together
/// without any one component drifting out of proportion when the parent
/// is resized (iPhone → iPad → Mac Catalyst window).
struct TimeCircuitRowView: View {
    let cityLabel: String
    let color: RowColor
    let readout: TimeReadout

    // MARK: - Layout constants
    //
    // These drive `intrinsicRowWidth()` and the per-field sizing.
    // Numbers are tuned against the reference photo of the screen-used
    // prop; changing any of them ripples through the aspect ratio.

    /// Height of a single LED digit (7-seg or 14-seg).
    private let digitHeight: CGFloat = 28
    /// Gap between adjacent digits within a field (e.g. between the two
    /// digits of DAY).
    private let charGap: CGFloat = 5
    /// Gap between adjacent fields that belong to the same group
    /// (MONTH→DAY, DAY→YEAR, AM/PM→HOUR, HOUR→:, :→MIN).
    private let fieldGap: CGFloat = 4
    /// Larger gap between YEAR and AM/PM — separates the date group from
    /// the time group.
    private let dateTimeGap: CGFloat = 9
    /// Width of the AM/PM block (two stacked text+lamp pairs).
    private let amPmWidth: CGFloat = 18
    /// Width of the pulsing colon column.
    private let colonWidth: CGFloat = 12
    /// Extra vertical slack above the digits to leave room for the
    /// red caption plates (MONTH / DAY / YEAR / HOUR / MIN).
    private let rowExtraHeight: CGFloat = 22
    /// Natural height of the city plate (Text + padding + stroke). Kept
    /// proportionally small relative to `rowHeight` so that at large
    /// parent scales (wide Catalyst / macOS windows) the label doesn't
    /// dominate the row.
    private let cityPlateHeight: CGFloat = 18
    /// Gap between the display row and the city plate below it.
    private let cityPlateSpacing: CGFloat = 3

    // MARK: - Body

    var body: some View {
        let nat = naturalContentSize()
        GeometryReader { geo in
            let scale = min(geo.size.width / nat.width, geo.size.height / nat.height)
            VStack(spacing: cityPlateSpacing) {
                displayRow
                    .frame(width: nat.width, height: rowHeight)
                cityPlate
            }
            .fixedSize()
            .scaleEffect(scale, anchor: .center)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
        }
        .aspectRatio(nat.width / nat.height, contentMode: .fit)
    }

    // MARK: - Sizing

    private var rowHeight: CGFloat { digitHeight + rowExtraHeight }

    /// Computes the unscaled bounding size of `displayRow + cityPlate`.
    /// Scaling is applied externally so the natural size is
    /// deterministic — no GeometryReader involved at this level.
    private func naturalContentSize() -> CGSize {
        CGSize(
            width: intrinsicRowWidth(),
            height: rowHeight + cityPlateSpacing + cityPlateHeight
        )
    }

    /// Sum of every HStack child's intrinsic width. Driven by the segment
    /// aspect ratios so changing `digitHeight` also changes the row's
    /// aspect ratio — callers needn't recompute manually.
    private func intrinsicRowWidth() -> CGFloat {
        let digitW = digitHeight * SegmentAspect.sevenSeg
        let charW = digitHeight * SegmentAspect.fourteenSeg
        let windowPadH: CGFloat = 8        // 4pt horizontal inside each blackWindow
        let monthW = charW * 3 + charGap * 2 + windowPadH
        let dayW = digitW * 2 + charGap + windowPadH
        let yearW = digitW * 4 + charGap * 3 + windowPadH
        let hourW = digitW * 2 + charGap + windowPadH
        let minW = digitW * 2 + charGap + windowPadH
        return monthW + dayW + yearW + amPmWidth + hourW + colonWidth + minW
            + fieldGap * 5 + dateTimeGap
    }

    // MARK: - Display row

    private var displayRow: some View {
        HStack(alignment: .bottom, spacing: 0) {
            fieldBlock(caption: "MONTH") { monthStrip }
            gap(fieldGap)
            fieldBlock(caption: "DAY") { digitStrip(readout.dayDigits) }
            gap(fieldGap)
            fieldBlock(caption: "YEAR") { digitStrip(readout.yearDigits) }
            gap(dateTimeGap)
            amPmBlock
            gap(fieldGap)
            fieldBlock(caption: "HOUR") { digitStrip(readout.hourDigits) }
            gap(fieldGap)
            colonBlock
            gap(fieldGap)
            fieldBlock(caption: "MIN") { digitStrip(readout.minuteDigits) }
        }
    }

    @ViewBuilder
    private func gap(_ w: CGFloat) -> some View {
        Spacer().frame(width: w)
    }

    // MARK: - Field components

    @ViewBuilder
    private func fieldBlock<Content: View>(caption: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 2) {
            captionPlate(caption)
            blackWindow { content() }
        }
    }

    @ViewBuilder
    private func captionPlate(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .heavy).width(.expanded))
            .kerning(0.1)
            .foregroundStyle(Palette.chromeTextGrey)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(Palette.captionPlateRed)
            .overlay(
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .stroke(Color.black.opacity(0.55), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 1.5, style: .continuous))
    }

    /// Recessed black window with a subtle row-tinted gradient — the
    /// "gel" behind each LED group that gives it a coloured cast matching
    /// its row.
    @ViewBuilder
    private func blackWindow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 4)
            .padding(.vertical, 3)
            .background(windowFill)
            .overlay(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .stroke(Color.black, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
    }

    private var windowFill: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, color.windowTint, Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            Color.black.opacity(0.35)
        }
    }

    /// AM/PM block, aligned to the bottom of the same vertical space as a
    /// caption+digits field, then nudged up 5pt so its bottom lamp sits
    /// just above the digit baseline (matches the reference photo).
    /// The 11pt spacer corresponds to the caption plate's approximate
    /// height so the AM/PM top aligns with the other fields' digit tops.
    private var amPmBlock: some View {
        VStack(spacing: 0) {
            Color.clear.frame(width: 1, height: 11)
            Spacer(minLength: 0)
            AmPmIndicator(isAM: readout.isAM, color: color)
                .frame(width: amPmWidth)
        }
        .frame(height: 11 + 2 + digitHeight, alignment: .bottom)
        .offset(y: -5)
    }

    private var colonBlock: some View {
        VStack(spacing: 2) {
            Color.clear.frame(width: 1, height: 11)
            ColonSeparator(color: color, blinking: true)
                .frame(width: colonWidth, height: digitHeight)
        }
    }

    // MARK: - City plate

    private var cityPlate: some View {
        Text(cityLabel)
            .font(.system(size: 11, weight: .black).width(.expanded))
            .kerning(0.3)
            .foregroundStyle(Palette.chromeTextGrey)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 10)
            .padding(.vertical, 2)
            .background(Palette.cityPlateBlack)
            .overlay(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .stroke(Color.black.opacity(0.9), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
    }

    // MARK: - Digit strips

    /// Three 14-segment characters rendering the month abbreviation.
    /// `paddedMonth` guarantees three characters so a malformed readout
    /// doesn't break the layout.
    private var monthStrip: some View {
        HStack(spacing: charGap) {
            ForEach(Array(paddedMonth.enumerated()), id: \.offset) { _, ch in
                FourteenSegmentChar(character: ch, color: color)
                    .frame(width: digitHeight * SegmentAspect.fourteenSeg, height: digitHeight)
            }
        }
    }

    private func digitStrip(_ digits: String) -> some View {
        HStack(spacing: charGap) {
            ForEach(Array(digits.enumerated()), id: \.offset) { _, ch in
                SevenSegmentDigit(character: ch, color: color)
                    .frame(width: digitHeight * SegmentAspect.sevenSeg, height: digitHeight)
            }
        }
    }

    private var paddedMonth: String {
        let m = readout.month
        if m.count >= 3 { return String(m.prefix(3)) }
        return m.padding(toLength: 3, withPad: " ", startingAt: 0)
    }
}
