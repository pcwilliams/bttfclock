import SwiftUI

/// A small piece of silk-screen-style chrome text used for loose labels
/// that aren't part of a red caption plate or the main city plate.
///
/// Currently the only consumer is the empty-state message in
/// `TimeCircuitsView` ("NO CITIES SELECTED"); the actual Time Circuits
/// captions are inlined in `TimeCircuitRowView` because they need tight
/// per-field styling that this generic helper doesn't expose.
///
/// Pass a `glow` colour to add a bloom halo (used when the text sits on
/// top of a brushed-metal surface and needs to pop); otherwise the text
/// gets a subtle dark drop-shadow so it reads as engraved.
struct FaceplateCaption: View {
    let text: String
    var color: Color = Color(red: 0.92, green: 0.92, blue: 0.88)
    var size: CGFloat = 8
    var weight: Font.Weight = .heavy
    var kerning: CGFloat = 1.2
    var glow: Color? = nil

    var body: some View {
        let t = Text(text)
            .font(.system(size: size, weight: weight, design: .default).width(.expanded))
            .kerning(kerning)
            .foregroundStyle(color)
            .lineLimit(1)
            .fixedSize()
        if let glow {
            t.shadow(color: glow.opacity(0.65), radius: 2)
                .shadow(color: glow.opacity(0.35), radius: 5)
        } else {
            t.shadow(color: .black.opacity(0.6), radius: 0.5, y: 0.5)
        }
    }
}
