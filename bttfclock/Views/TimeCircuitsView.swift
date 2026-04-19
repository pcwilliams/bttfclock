import SwiftUI

/// Top-level view of the Time Circuits display: the chassis containing
/// three colour-coded row panels.
///
/// Receives pre-computed `readouts` from `ContentView` — one per city in
/// the same order — rather than computing them itself, so testing
/// against a fixed clock doesn't require stubbing a timer.
struct TimeCircuitsView: View {
    let cities: [CityTimezone]
    let readouts: [TimeReadout]

    var body: some View {
        DashboardEnclosureView {
            if cities.isEmpty {
                emptyState
            } else {
                ForEach(0..<min(cities.count, 3), id: \.self) { idx in
                    RowPanel {
                        TimeCircuitRowView(
                            cityLabel: cities[idx].displayName,
                            color: RowColor.forIndex(idx),
                            readout: idx < readouts.count ? readouts[idx] : Self.blankReadout
                        )
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            FaceplateCaption(text: "NO CITIES SELECTED", size: 12, weight: .heavy, kerning: 2)
            FaceplateCaption(
                text: "TAP THE GEAR ICON TO ADD UP TO 3",
                color: Color(red: 0.7, green: 0.7, blue: 0.68),
                size: 9,
                weight: .semibold,
                kerning: 1.2
            )
        }
        .padding(.vertical, 20)
    }

    /// Placeholder readout for the defensive `idx < readouts.count`
    /// branch. Shouldn't appear in normal use — `ContentView` always
    /// builds `readouts` from the same `cities` array.
    private static let blankReadout = TimeReadout(
        month: "   ", day: 0, year: 0, hour12: 0, minute: 0, isAM: true
    )
}
