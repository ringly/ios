import RinglyActivityTracking
import XCTest

final class CalendarBoundaryDatesTests: XCTestCase
{
    func testEquality()
    {
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)

        var componentsStart1 = DateComponents()
        componentsStart1.day = 1
        componentsStart1.month = 1
        componentsStart1.year = 2016
        componentsStart1.hour = 10
        componentsStart1.minute = 20

        var componentsStart2 = DateComponents()
        componentsStart2.day = 1
        componentsStart2.month = 1
        componentsStart2.year = 2016
        componentsStart2.hour = 9
        componentsStart2.minute = 30

        var componentsEnd1 = DateComponents()
        componentsEnd1.day = 1
        componentsEnd1.month = 2
        componentsEnd1.year = 2016
        componentsEnd1.hour = 10
        componentsEnd1.minute = 20

        var componentsEnd2 = DateComponents()
        componentsEnd2.day = 1
        componentsEnd2.month = 2
        componentsEnd2.year = 2016
        componentsEnd2.hour = 9
        componentsEnd2.minute = 30

        XCTAssertEqual(
            CalendarBoundaryDates(
                calendar: calendar,
                fromMidnightBefore: calendar.date(from: componentsStart1)!,
                toMidnightAfter: calendar.date(from: componentsEnd1)!
            ),
            CalendarBoundaryDates(
                calendar: calendar,
                fromMidnightBefore: calendar.date(from: componentsStart2)!,
                toMidnightAfter: calendar.date(from: componentsEnd2)!
            ),
            ""
        )
    }
}
