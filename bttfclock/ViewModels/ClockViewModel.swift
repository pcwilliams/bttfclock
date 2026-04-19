import Foundation
import Combine

/// Publishes the current `Date` on a 1-second cadence, or holds a fixed
/// `frozenDate` for deterministic screenshot/UI testing.
///
/// Note that the colon pulse is NOT driven from this view model — it
/// reads the live wall clock via `TimelineView(.animation)` inside
/// `ColonSeparator` so it keeps pulsing smoothly even when `now` is
/// frozen.
@MainActor
final class ClockViewModel: ObservableObject {
    @Published private(set) var now: Date
    private let frozenDate: Date?
    private var timerCancellable: AnyCancellable?

    /// - Parameters:
    ///   - frozenDate: if non-nil, `now` stays pinned at this instant
    ///     and the ticking timer is never started. Used by the
    ///     `-frozendate` launch arg for byte-stable screenshots.
    ///   - clock: override for the initial `Date()` call. Production
    ///     passes the default; tests inject a fixed provider.
    init(frozenDate: Date? = nil, clock: @escaping () -> Date = { Date() }) {
        self.frozenDate = frozenDate
        self.now = frozenDate ?? clock()
        if frozenDate == nil {
            self.timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] date in
                    self?.now = date
                }
        }
    }

    /// Projects the current `now` through each city's timezone to produce
    /// the triple of readouts driving the three rows.
    func readouts(for cities: [CityTimezone]) -> [TimeReadout] {
        cities.map { TimeReadout.make(for: now, in: $0.timezone) }
    }

    var isFrozen: Bool { frozenDate != nil }
}
