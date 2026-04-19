import Foundation
import Testing
@testable import bttfclock

struct ColonPulseTests {
    @Test func litOnExactSecondBoundary() {
        let d = Date(timeIntervalSince1970: 1_700_000_000)
        #expect(ColonSeparator.isLit(at: d))
    }

    @Test func litThroughFirstHalfOfSecond() {
        for offset in stride(from: 0.0, through: 0.49, by: 0.05) {
            let d = Date(timeIntervalSince1970: 1_700_000_000 + offset)
            #expect(ColonSeparator.isLit(at: d), "should be lit at +\(offset)s")
        }
    }

    @Test func unlitThroughSecondHalfOfSecond() {
        for offset in stride(from: 0.5, through: 0.99, by: 0.05) {
            let d = Date(timeIntervalSince1970: 1_700_000_000 + offset)
            #expect(!ColonSeparator.isLit(at: d), "should be unlit at +\(offset)s")
        }
    }

    @Test func togglesAtHalfSecondBoundary() {
        let justBefore = Date(timeIntervalSince1970: 1_700_000_000.499)
        let justAfter = Date(timeIntervalSince1970: 1_700_000_000.501)
        #expect(ColonSeparator.isLit(at: justBefore))
        #expect(!ColonSeparator.isLit(at: justAfter))
    }
}
