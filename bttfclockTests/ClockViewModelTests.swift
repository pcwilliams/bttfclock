import Foundation
import Testing
@testable import bttfclock

@MainActor
struct ClockViewModelTests {
    @Test func frozenDate_producesDeterministicReadouts() {
        let frozen = DateComponents(
            calendar: .init(identifier: .gregorian),
            timeZone: TimeZone(identifier: "America/Los_Angeles"),
            year: 1985, month: 10, day: 26, hour: 1, minute: 21
        ).date!
        let vm = ClockViewModel(frozenDate: frozen)
        let cities = [
            CityCatalog.city(withId: "london")!,
            CityCatalog.city(withId: "new_york")!,
            CityCatalog.city(withId: "hong_kong")!
        ]
        let readouts = vm.readouts(for: cities)
        #expect(readouts.count == 3)
        #expect(vm.isFrozen)
    }

    @Test func unfrozen_reportsNotFrozen() {
        let vm = ClockViewModel()
        #expect(vm.isFrozen == false)
    }

    @Test func frozenDate_doesNotAdvanceOverTime() async throws {
        let fixed = Date(timeIntervalSince1970: 123_456_789)
        let vm = ClockViewModel(frozenDate: fixed)
        let first = vm.now
        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(vm.now == first)
    }
}
