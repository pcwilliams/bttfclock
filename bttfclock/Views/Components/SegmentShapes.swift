import SwiftUI

/// Layout constants for the hand-drawn segment shapes. Kept private so
/// that geometry tweaks (bar thickness, italic lean, aspect ratios) live
/// in one place and callers use semantic helpers like `SegmentAspect`
/// instead of reaching into raw numbers.
private enum SegmentGeometry {
    /// Beveled-bar thickness as a fraction of the shorter side of the
    /// character box. 0.18 roughly matches the thickness of DSEG14 Classic
    /// Italic, the free font most builders of BTTF prop replicas use.
    static let thicknessRatio: CGFloat = 0.18

    /// Right-leaning x-shear applied to every segment point (as a fraction
    /// of character height). The real Time Circuits prop displays are
    /// italicised; 0.10 replicates that without the digits reading as
    /// "broken".
    static let italicSkew: CGFloat = 0.10

    /// Ratio of width / height for a single 7-segment digit. Matches the
    /// slim, slightly-taller-than-wide proportions of the prop's numeric
    /// LEDs.
    static let sevenSegAspect: CGFloat = 0.58

    /// Ratio of width / height for a single 14-segment letter. Wider than
    /// 7-segment because the letters need room for their diagonal strokes.
    static let fourteenSegAspect: CGFloat = 0.68

    /// Applies the italic x-shear to a point. `height` is the full
    /// character-box height, so the shear shifts the *top* of the
    /// character right and leaves the bottom fixed. This produces an
    /// italic lean without shifting the character's baseline.
    static func skew(_ point: CGPoint, height: CGFloat, italic: Bool) -> CGPoint {
        guard italic else { return point }
        let dx = italicSkew * (height - point.y)
        return CGPoint(x: point.x + dx, y: point.y)
    }
}

/// Builds the hexagonal-ended polygons that represent individual
/// LED segments. Every bar (horizontal, vertical, or diagonal) has beveled
/// tips where it narrows to a point — this matches the way real
/// multiplexed LED segments look and also how they render in the DSEG
/// font family the prop is traced from.
///
/// Italic skew is applied per-point at construction time rather than by
/// wrapping the whole Path in a `transform`, so the resulting geometry
/// stays predictable for gradients and strokes.
private struct PathBuilder {
    let italic: Bool
    let height: CGFloat

    /// Horizontal beveled bar centred on `cy`, spanning x = [x0, x1].
    func addHorizBar(to path: inout Path, cy: CGFloat, x0: CGFloat, x1: CGFloat, t: CGFloat) {
        let bevel = t * 0.5
        let points: [CGPoint] = [
            .init(x: x0, y: cy),
            .init(x: x0 + bevel, y: cy - t / 2),
            .init(x: x1 - bevel, y: cy - t / 2),
            .init(x: x1, y: cy),
            .init(x: x1 - bevel, y: cy + t / 2),
            .init(x: x0 + bevel, y: cy + t / 2)
        ]
        addClosed(&path, points: points)
    }

    /// Vertical beveled bar centred on `cx`, spanning y = [y0, y1].
    func addVertBar(to path: inout Path, cx: CGFloat, y0: CGFloat, y1: CGFloat, t: CGFloat) {
        let bevel = t * 0.5
        let points: [CGPoint] = [
            .init(x: cx, y: y0),
            .init(x: cx + t / 2, y: y0 + bevel),
            .init(x: cx + t / 2, y: y1 - bevel),
            .init(x: cx, y: y1),
            .init(x: cx - t / 2, y: y1 - bevel),
            .init(x: cx - t / 2, y: y0 + bevel)
        ]
        addClosed(&path, points: points)
    }

    /// Diagonal beveled bar from `p0` to `p1`, constructed by sweeping the
    /// perpendicular normal ±t/2 along the line so both ends pinch to a
    /// point like the other bar types.
    func addDiagonal(to path: inout Path, from p0: CGPoint, to p1: CGPoint, t: CGFloat) {
        let dx = p1.x - p0.x
        let dy = p1.y - p0.y
        let len = sqrt(dx * dx + dy * dy)
        guard len > 0 else { return }
        let ux = dx / len                    // unit vector along bar
        let uy = dy / len
        let nx = -uy                         // perpendicular (right-hand normal)
        let ny = ux
        let half = t / 2
        let bevel = t * 0.5
        let startOuter = CGPoint(x: p0.x + ux * bevel, y: p0.y + uy * bevel)
        let endOuter = CGPoint(x: p1.x - ux * bevel, y: p1.y - uy * bevel)
        let points: [CGPoint] = [
            p0,
            .init(x: startOuter.x + nx * half, y: startOuter.y + ny * half),
            .init(x: endOuter.x + nx * half, y: endOuter.y + ny * half),
            p1,
            .init(x: endOuter.x - nx * half, y: endOuter.y - ny * half),
            .init(x: startOuter.x - nx * half, y: startOuter.y - ny * half)
        ]
        addClosed(&path, points: points)
    }

    private func addClosed(_ path: inout Path, points: [CGPoint]) {
        guard let first = points.first else { return }
        path.move(to: SegmentGeometry.skew(first, height: height, italic: italic))
        for p in points.dropFirst() {
            path.addLine(to: SegmentGeometry.skew(p, height: height, italic: italic))
        }
        path.closeSubpath()
    }
}

/// A `Shape` that renders the union of one or more 7-segment bars.
///
/// Pass a bitmask from `SevenSegmentMap.mask(for:)` to light specific
/// segments, or `allOnMask` to draw the full character silhouette (used
/// for the "ghost" layer behind a lit character).
struct SevenSegmentShape: Shape {
    /// Bitmask selecting which of the seven segments to include.
    let mask: UInt8
    /// Whether to apply the right-leaning italic shear.
    var italic: Bool = true

    /// Bitmask that turns on every segment — used to render the dim
    /// "ghost" of all segments behind a lit character.
    static let allOnMask: UInt8 = 0b0111_1111

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let t = min(w, h) * SegmentGeometry.thicknessRatio
        let gap = t * 0.18                    // gap where two segments meet
        let midY = rect.minY + h / 2
        let leftX = rect.minX + t / 2
        let rightX = rect.maxX - t / 2
        let topY = rect.minY + t / 2
        let botY = rect.maxY - t / 2
        let builder = PathBuilder(italic: italic, height: h)

        // Segments are drawn in A–G order so bit index matches the table
        // in SegmentMaps.swift without mental translation.
        if (mask >> 0) & 1 == 1 {
            builder.addHorizBar(to: &path, cy: topY, x0: leftX + t, x1: rightX - t, t: t)
        }
        if (mask >> 1) & 1 == 1 {
            builder.addVertBar(to: &path, cx: rightX, y0: topY + gap, y1: midY - gap, t: t)
        }
        if (mask >> 2) & 1 == 1 {
            builder.addVertBar(to: &path, cx: rightX, y0: midY + gap, y1: botY - gap, t: t)
        }
        if (mask >> 3) & 1 == 1 {
            builder.addHorizBar(to: &path, cy: botY, x0: leftX + t, x1: rightX - t, t: t)
        }
        if (mask >> 4) & 1 == 1 {
            builder.addVertBar(to: &path, cx: leftX, y0: midY + gap, y1: botY - gap, t: t)
        }
        if (mask >> 5) & 1 == 1 {
            builder.addVertBar(to: &path, cx: leftX, y0: topY + gap, y1: midY - gap, t: t)
        }
        if (mask >> 6) & 1 == 1 {
            // Middle bar is inset slightly (× 0.7) to avoid touching the
            // ends of the side verticals at the beveled corners.
            builder.addHorizBar(to: &path, cy: midY, x0: leftX + t * 0.7, x1: rightX - t * 0.7, t: t)
        }
        return path
    }
}

/// A `Shape` that renders the union of one or more 14-segment bars.
///
/// See `FourteenSegmentMap` for the bit layout. Mirror of
/// `SevenSegmentShape` with an extra eight segments (two half-middles,
/// two centre verticals, four diagonals).
struct FourteenSegmentShape: Shape {
    let mask: UInt16
    var italic: Bool = true

    /// Bitmask that turns on all 14 segments — used for the ghost layer.
    static let allOnMask: UInt16 = 0x3FFF

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let t = min(w, h) * SegmentGeometry.thicknessRatio
        let gap = t * 0.18
        let midY = rect.minY + h / 2
        let midX = rect.minX + w / 2
        let leftX = rect.minX + t / 2
        let rightX = rect.maxX - t / 2
        let topY = rect.minY + t / 2
        let botY = rect.maxY - t / 2
        let builder = PathBuilder(italic: italic, height: h)

        // Diagonals are drawn slightly thinner (× 0.78) than the straight
        // bars because they cover more pixels at the same geometric
        // thickness and otherwise read as heavier.
        let diagThickness = t * 0.78

        // Outer six (A–F), identical to 7-segment but without the middle.
        if (mask >> 0) & 1 == 1 {
            builder.addHorizBar(to: &path, cy: topY, x0: leftX + t, x1: rightX - t, t: t)
        }
        if (mask >> 1) & 1 == 1 {
            builder.addVertBar(to: &path, cx: rightX, y0: topY + gap, y1: midY - gap, t: t)
        }
        if (mask >> 2) & 1 == 1 {
            builder.addVertBar(to: &path, cx: rightX, y0: midY + gap, y1: botY - gap, t: t)
        }
        if (mask >> 3) & 1 == 1 {
            builder.addHorizBar(to: &path, cy: botY, x0: leftX + t, x1: rightX - t, t: t)
        }
        if (mask >> 4) & 1 == 1 {
            builder.addVertBar(to: &path, cx: leftX, y0: midY + gap, y1: botY - gap, t: t)
        }
        if (mask >> 5) & 1 == 1 {
            builder.addVertBar(to: &path, cx: leftX, y0: topY + gap, y1: midY - gap, t: t)
        }
        // Middle horizontals (G1 left, G2 right) — each spans half the
        // char and meets at mid-X with a small gap so the centre verticals
        // can fit between them.
        if (mask >> 6) & 1 == 1 {
            builder.addHorizBar(to: &path, cy: midY, x0: leftX + t * 0.7, x1: midX - gap, t: t)
        }
        if (mask >> 7) & 1 == 1 {
            builder.addHorizBar(to: &path, cy: midY, x0: midX + gap, x1: rightX - t * 0.7, t: t)
        }
        // Upper-left diagonal (H): top-left corner down to centre.
        if (mask >> 8) & 1 == 1 {
            let p0 = CGPoint(x: leftX + t, y: topY + gap)
            let p1 = CGPoint(x: midX - gap, y: midY - gap * 0.3)
            builder.addDiagonal(to: &path, from: p0, to: p1, t: diagThickness)
        }
        // Upper centre vertical (I).
        if (mask >> 9) & 1 == 1 {
            builder.addVertBar(to: &path, cx: midX, y0: topY + gap, y1: midY - gap, t: t)
        }
        // Upper-right diagonal (J): top-right corner down to centre.
        if (mask >> 10) & 1 == 1 {
            let p0 = CGPoint(x: rightX - t, y: topY + gap)
            let p1 = CGPoint(x: midX + gap, y: midY - gap * 0.3)
            builder.addDiagonal(to: &path, from: p0, to: p1, t: diagThickness)
        }
        // Lower-right diagonal (K): centre down to bottom-right corner.
        if (mask >> 11) & 1 == 1 {
            let p0 = CGPoint(x: midX + gap, y: midY + gap * 0.3)
            let p1 = CGPoint(x: rightX - t, y: botY - gap)
            builder.addDiagonal(to: &path, from: p0, to: p1, t: diagThickness)
        }
        // Lower centre vertical (L).
        if (mask >> 12) & 1 == 1 {
            builder.addVertBar(to: &path, cx: midX, y0: midY + gap, y1: botY - gap, t: t)
        }
        // Lower-left diagonal (M): centre down to bottom-left corner.
        if (mask >> 13) & 1 == 1 {
            let p0 = CGPoint(x: midX - gap, y: midY + gap * 0.3)
            let p1 = CGPoint(x: leftX + t, y: botY - gap)
            builder.addDiagonal(to: &path, from: p0, to: p1, t: diagThickness)
        }
        return path
    }
}

/// Public face of the geometry constants — the width/height aspect
/// ratios needed by callers laying out grids of segment views.
enum SegmentAspect {
    static let sevenSeg = SegmentGeometry.sevenSegAspect
    static let fourteenSeg = SegmentGeometry.fourteenSegAspect
}
