import SwiftUI

/// Outer chassis of the Time Circuits unit — the darker grey panel that
/// holds the three row tiles, with rivets at the corners and a soft drop
/// shadow under the whole thing.
///
/// `.fixedSize(horizontal: false, vertical: true)` lets the enclosure
/// expand horizontally to fill offered width while sizing its height to
/// its content (three `RowPanel`s plus padding).
struct DashboardEnclosureView<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    // Tighter chassis padding on macOS so the clock can fill the
    // window with minimal frame around it. iOS keeps the original
    // roomier values that look right against the phone's edges.
    #if os(macOS)
    private let rowSpacing: CGFloat = 3
    private let paddingH: CGFloat = 2
    private let paddingV: CGFloat = 3
    #else
    private let rowSpacing: CGFloat = 6
    private let paddingH: CGFloat = 8
    private let paddingV: CGFloat = 10
    #endif

    var body: some View {
        ZStack {
            backgroundPanel
            VStack(spacing: rowSpacing) {
                content()
            }
            .padding(.horizontal, paddingH)
            .padding(.vertical, paddingV)
            rivets
        }
        #if os(iOS)
        // On iOS the enclosure sits in a Spacer-sandwich and must not
        // stretch vertically. On macOS it fills the window, so leaving
        // this unset lets the rows expand to whatever height is offered.
        .fixedSize(horizontal: false, vertical: true)
        #endif
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.9), lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.55), radius: 16, y: 8)
    }

    private var backgroundPanel: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.10, blue: 0.09),
                    Color(red: 0.06, green: 0.06, blue: 0.05),
                    Color(red: 0.04, green: 0.04, blue: 0.04),
                    Color(red: 0.08, green: 0.08, blue: 0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            BrushedMetalOverlay(brightnessMax: 0.05)
                .opacity(0.6)
                .blendMode(.overlay)
        }
    }

    private var rivets: some View {
        GeometryReader { geo in
            let inset: CGFloat = 10
            let positions: [CGPoint] = [
                CGPoint(x: inset, y: inset),
                CGPoint(x: geo.size.width - inset, y: inset),
                CGPoint(x: inset, y: geo.size.height - inset),
                CGPoint(x: geo.size.width - inset, y: geo.size.height - inset)
            ]
            ForEach(positions.indices, id: \.self) { i in
                Rivet().position(positions[i])
            }
        }
        .allowsHitTesting(false)
    }
}

/// Lighter grey brushed-metal tile that sits inside the enclosure and
/// hosts one `TimeCircuitRowView`. The subtle bright strip along the top
/// edge is a bevel highlight that mimics the machined lip of the prop's
/// individual display housings.
struct RowPanel<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    // Same rationale as the enclosure — tighter insets on macOS give the
    // rows more room within a compact window, while iOS keeps the
    // original phone-sized breathing space.
    #if os(macOS)
    private let contentPadH: CGFloat = 4
    private let contentPadV: CGFloat = 3
    #else
    private let contentPadH: CGFloat = 8
    private let contentPadV: CGFloat = 6
    #endif

    var body: some View {
        ZStack {
            panelBackground
            content()
                .padding(.horizontal, contentPadH)
                .padding(.vertical, contentPadV)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(Color.black.opacity(0.65), lineWidth: 1)
        )
        .overlay(alignment: .top) {
            Rectangle().fill(Color.white.opacity(0.05)).frame(height: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
    }

    private var panelBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.32, green: 0.32, blue: 0.30),
                    Color(red: 0.23, green: 0.23, blue: 0.22),
                    Color(red: 0.18, green: 0.18, blue: 0.17),
                    Color(red: 0.26, green: 0.26, blue: 0.24)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            BrushedMetalOverlay(brightnessMax: 0.08)
                .opacity(0.45)
                .blendMode(.overlay)
        }
    }
}

/// A single corner rivet — a radial-gradient disc that reads as a
/// recessed metal fastener.
struct Rivet: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [
                        Color(red: 0.50, green: 0.50, blue: 0.48),
                        Color(red: 0.20, green: 0.20, blue: 0.18),
                        Color(red: 0.10, green: 0.10, blue: 0.09)
                    ],
                    center: .init(x: 0.35, y: 0.35),
                    startRadius: 0.5,
                    endRadius: 5
                ))
                .frame(width: 10, height: 10)
            Circle()
                .stroke(Color.black.opacity(0.6), lineWidth: 0.5)
                .frame(width: 10, height: 10)
        }
    }
}

/// Procedural brushed-metal texture rendered into a `Canvas`. Draws
/// horizontal stripes at random alphas so adjacent row panels don't look
/// identical and the overall surface feels like a machined metal plate.
///
/// Random noise is re-seeded on every redraw, which is fine for a static
/// background but means snapshot tests will differ. If that becomes a
/// problem, seed from a constant `SystemRandomNumberGenerator`.
struct BrushedMetalOverlay: View {
    var brightnessMax: CGFloat = 0.08

    var body: some View {
        Canvas { ctx, size in
            let step: CGFloat = 1.5
            var y: CGFloat = 0
            while y < size.height {
                let alpha = CGFloat.random(in: 0.02...brightnessMax)
                let color = CGFloat.random(in: 0...1) > 0.5
                    ? Color.white.opacity(alpha)
                    : Color.black.opacity(alpha)
                let rect = CGRect(x: 0, y: y, width: size.width, height: step)
                ctx.fill(Path(rect), with: .color(color))
                y += step
            }
        }
    }
}
