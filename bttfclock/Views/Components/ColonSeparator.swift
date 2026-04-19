import SwiftUI

/// The pulsing colon dots between HOUR and MIN.
///
/// Each dot is rendered with the same visual treatment as the AM/PM
/// indicator lamps — small (5pt) circle, row-colour fill, bloom halo,
/// and a white hot-spot that reads as the filament of a real LED. The
/// state switches *instantly* (no fade) at each half-second boundary so
/// you can see the seconds ticking, but unlit dots stay faintly visible
/// as the row-tinted ghost circle so the switch feels subtle rather than
/// a flash.
///
/// Lit / unlit state is derived directly from `context.date` via
/// `TimelineView(.animation)`, so the toggle stays phase-locked to
/// wall-clock seconds: the dots come on at every `:00`, `:01`, `:02` …
/// and go off at `:00.5`, `:01.5`, … regardless of when the view first
/// appeared.
struct ColonSeparator: View {
    let color: RowColor
    /// When `true`, the colon ticks in sync with wall-clock seconds.
    /// When `false`, holds steady in the lit state (useful for snapshot
    /// tests and any settings preview).
    var blinking: Bool = false

    var body: some View {
        if blinking {
            TimelineView(.animation) { context in
                dotStack(lit: Self.isLit(at: context.date))
            }
        } else {
            dotStack(lit: true)
        }
    }

    /// Step function driving the colon. Lit for the first half of each
    /// wall-clock second, unlit for the second half.
    ///
    /// Extracted as `internal static` so tests can probe the timing
    /// without instantiating a SwiftUI view.
    static func isLit(at date: Date) -> Bool {
        let t = date.timeIntervalSince1970
        let phase = t - floor(t)
        return phase < 0.5
    }

    @ViewBuilder
    private func dotStack(lit: Bool) -> some View {
        VStack(spacing: 4) {
            dot(lit: lit)
            dot(lit: lit)
        }
    }

    /// One colon dot. Mirrors the AM/PM lamp: ghost circle always
    /// visible beneath, lit core + bloom + white hot-spot added on top
    /// when lit.
    @ViewBuilder
    private func dot(lit: Bool) -> some View {
        ZStack {
            Circle().fill(color.ghost).frame(width: 5, height: 5)
            if lit {
                Circle()
                    .fill(color.lit)
                    .frame(width: 5, height: 5)
                    .shadow(color: color.bloom, radius: 1.2)
                    .shadow(color: color.bloom, radius: 3)
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.white.opacity(0.85), color.lit.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 2.5
                    ))
                    .frame(width: 2.5, height: 2.5)
            }
        }
    }
}

/// AM / PM indicator stacked above the HOUR field.
///
/// Each pair (letter plate + lamp) mirrors the DYMO-tape style of the
/// field captions: the letter sits on a small red plate with grey text,
/// and a row-coloured LED lamp below it lights when that half of the day
/// is active. AM is stacked over PM so the whole block takes roughly the
/// same vertical space as a single digit.
struct AmPmIndicator: View {
    let isAM: Bool
    let color: RowColor

    var body: some View {
        VStack(spacing: 1.5) {
            stack(letter: "AM", lit: isAM)
            stack(letter: "PM", lit: !isAM)
        }
    }

    @ViewBuilder
    private func stack(letter: String, lit: Bool) -> some View {
        VStack(spacing: 0.5) {
            Text(letter)
                .font(.system(size: 6, weight: .heavy).width(.expanded))
                .kerning(0)
                .foregroundStyle(Palette.chromeTextGrey)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 2)
                .padding(.vertical, 0.3)
                .background(Palette.captionPlateRed)
                .overlay(
                    RoundedRectangle(cornerRadius: 1, style: .continuous)
                        .stroke(Color.black.opacity(0.55), lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 1, style: .continuous))
            lamp(lit: lit)
        }
    }

    @ViewBuilder
    private func lamp(lit: Bool) -> some View {
        ZStack {
            Circle().fill(color.ghost).frame(width: 5, height: 5)
            if lit {
                Circle()
                    .fill(color.lit)
                    .frame(width: 5, height: 5)
                    .shadow(color: color.bloom, radius: 1.2)
                    .shadow(color: color.bloom, radius: 3)
                // Bright white hot-spot radial gradient at the centre
                // reads as the filament of a real LED through frosted
                // plastic.
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.white.opacity(0.85), color.lit.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 2.5
                    ))
                    .frame(width: 2.5, height: 2.5)
            }
        }
    }
}
