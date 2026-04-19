import Foundation
import Testing
@testable import bttfclock

struct TimeReadoutTests {
    @Test func bttfClassicDateOctober26_1985_LosAngeles() {
        let components = DateComponents(
            calendar: Calendar(identifier: .gregorian),
            timeZone: TimeZone(identifier: "America/Los_Angeles"),
            year: 1985, month: 10, day: 26, hour: 1, minute: 21
        )
        let instant = components.date!
        let readout = TimeReadout.make(for: instant, in: TimeZone(identifier: "America/Los_Angeles")!)
        #expect(readout.month == "OCT")
        #expect(readout.day == 26)
        #expect(readout.year == 1985)
        #expect(readout.hour12 == 1)
        #expect(readout.minute == 21)
        #expect(readout.isAM == true)
    }

    @Test func midnightReadsAs12AM() {
        let c = DateComponents(calendar: .init(identifier: .gregorian),
                               timeZone: .gmt,
                               year: 2000, month: 1, day: 1, hour: 0, minute: 0)
        let r = TimeReadout.make(for: c.date!, in: .gmt)
        #expect(r.hour12 == 12)
        #expect(r.isAM == true)
    }

    @Test func noonReadsAs12PM() {
        let c = DateComponents(calendar: .init(identifier: .gregorian),
                               timeZone: .gmt,
                               year: 2000, month: 1, day: 1, hour: 12, minute: 0)
        let r = TimeReadout.make(for: c.date!, in: .gmt)
        #expect(r.hour12 == 12)
        #expect(r.isAM == false)
    }

    @Test func sameInstant_differentTimezones_differentReadouts() {
        let instant = Date(timeIntervalSince1970: 1_700_000_000)
        let london = TimeReadout.make(for: instant, in: TimeZone(identifier: "Europe/London")!)
        let ny = TimeReadout.make(for: instant, in: TimeZone(identifier: "America/New_York")!)
        let hk = TimeReadout.make(for: instant, in: TimeZone(identifier: "Asia/Hong_Kong")!)
        #expect(london != ny)
        #expect(ny != hk)
    }

    @Test func digitFormatting_zeroPads() {
        let r = TimeReadout(month: "JAN", day: 3, year: 42, hour12: 7, minute: 5, isAM: true)
        #expect(r.dayDigits == "03")
        #expect(r.yearDigits == "0042")
        #expect(r.hourDigits == "07")
        #expect(r.minuteDigits == "05")
    }

    @Test func yearClampsAtBoundaries() {
        let low = TimeReadout(month: "JAN", day: 1, year: -100, hour12: 12, minute: 0, isAM: true)
        #expect(low.yearDigits == "0000")
        let high = TimeReadout(month: "JAN", day: 1, year: 99999, hour12: 12, minute: 0, isAM: true)
        #expect(high.yearDigits == "9999")
    }

    @Test func monthAbbreviationsAreExactlyThreeLetters() {
        for m in TimeReadout.monthAbbreviations {
            #expect(m.count == 3)
            #expect(m == m.uppercased())
        }
    }
}
