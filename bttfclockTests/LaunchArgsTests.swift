import Foundation
import Testing
@testable import bttfclock

struct LaunchArgsTests {
    @Test func rowColor_indicesMap() {
        #expect(RowColor.forIndex(0) == .red)
        #expect(RowColor.forIndex(1) == .green)
        #expect(RowColor.forIndex(2) == .amber)
        #expect(RowColor.forIndex(99) == .amber)
    }

    @Test func cityCatalog_hasLondonNewYorkHongKong() {
        #expect(CityCatalog.city(withId: "london") != nil)
        #expect(CityCatalog.city(withId: "new_york") != nil)
        #expect(CityCatalog.city(withId: "hong_kong") != nil)
    }

    @Test func cityCatalog_defaultSelectionIsThree() {
        #expect(CityCatalog.defaultSelection.count == 3)
    }

    @Test func cityCatalog_hasHillValleyEasterEgg() {
        let hillValley = CityCatalog.city(withId: "hill_valley")
        #expect(hillValley != nil)
        #expect(hillValley?.displayName == "HILL VALLEY")
    }
}
