import Foundation
import Testing
@testable import bttfclock

struct SegmentMapsTests {
    @Test func sevenSegmentZero_litsAllSegmentsExceptMiddle() {
        let mask = SevenSegmentMap.mask(for: "0")
        #expect(SevenSegmentMap.isSegmentOn(mask, index: 0))
        #expect(SevenSegmentMap.isSegmentOn(mask, index: 1))
        #expect(SevenSegmentMap.isSegmentOn(mask, index: 2))
        #expect(SevenSegmentMap.isSegmentOn(mask, index: 3))
        #expect(SevenSegmentMap.isSegmentOn(mask, index: 4))
        #expect(SevenSegmentMap.isSegmentOn(mask, index: 5))
        #expect(SevenSegmentMap.isSegmentOn(mask, index: 6) == false)
    }

    @Test func sevenSegmentOne_onlyRightVerticals() {
        let mask = SevenSegmentMap.mask(for: "1")
        #expect(SevenSegmentMap.isSegmentOn(mask, index: 1))
        #expect(SevenSegmentMap.isSegmentOn(mask, index: 2))
        for i in [0, 3, 4, 5, 6] {
            #expect(SevenSegmentMap.isSegmentOn(mask, index: i) == false, "seg \(i) should be off for '1'")
        }
    }

    @Test func sevenSegmentBlank_isZero() {
        #expect(SevenSegmentMap.mask(for: " ") == 0)
        #expect(SevenSegmentMap.mask(for: "_") == 0)
    }

    @Test func sevenSegmentAllDigitsMapped() {
        for ch in "0123456789" {
            #expect(SevenSegmentMap.mask(for: ch) != 0, "digit \(ch) should have segments")
        }
    }

    @Test func fourteenSegmentZero_hasDiagonalsForSlash() {
        let mask = FourteenSegmentMap.mask(for: "0")
        #expect(FourteenSegmentMap.isSegmentOn(mask, index: 10), "J (upper-right diag) should be on")
        #expect(FourteenSegmentMap.isSegmentOn(mask, index: 13), "M (lower-left diag) should be on")
    }

    @Test func fourteenSegmentO_letterIsFullBorder() {
        let mask = FourteenSegmentMap.mask(for: "O")
        for i in 0..<6 {
            #expect(FourteenSegmentMap.isSegmentOn(mask, index: i), "border seg \(i) should be on for O")
        }
        #expect(FourteenSegmentMap.isSegmentOn(mask, index: 10) == false, "O has no diagonals")
        #expect(FourteenSegmentMap.isSegmentOn(mask, index: 13) == false, "O has no diagonals")
    }

    @Test func fourteenSegmentCaseInsensitive() {
        #expect(FourteenSegmentMap.mask(for: "c") == FourteenSegmentMap.mask(for: "C"))
        #expect(FourteenSegmentMap.mask(for: "t") == FourteenSegmentMap.mask(for: "T"))
    }

    @Test func fourteenSegmentAllMonthLettersMapped() {
        for ch in "JANFEBMARPYULGSOCTVD" {
            #expect(FourteenSegmentMap.mask(for: ch) != 0, "letter \(ch) must be mapped")
        }
    }
}
