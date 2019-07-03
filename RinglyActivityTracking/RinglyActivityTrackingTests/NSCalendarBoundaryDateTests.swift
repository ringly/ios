import RinglyActivityTracking
import XCTest

final class NSCalendarBoundaryDateTests: XCTestCase
{
    let calendar = { () -> Calendar in
        var calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }()

    func testNormalDay()
    {
        var startComponents = DateComponents()
        startComponents.year = 2016
        startComponents.month = 1
        startComponents.day = 1

        var endComponents = DateComponents()
        endComponents.year = 2016
        endComponents.month = 1
        endComponents.day = 2

        let boundaries = calendar.boundaryDatesForHours(
            from: calendar.date(from: startComponents)!,
            to: calendar.date(from: endComponents)!
        )

        XCTAssertEqual(boundaries, [
            BoundaryDates(
                start: Date(timeIntervalSince1970: 1451624400),
                end: Date(timeIntervalSince1970: 1451628000)
            ),
            BoundaryDates(
                start: Date(timeIntervalSince1970: 1451628000),
                end: Date(timeIntervalSince1970: 1451631600)
            ),
            BoundaryDates(
                start: Date(timeIntervalSince1970: 1451631600),
                end: Date(timeIntervalSince1970: 1451635200)
            ),
            BoundaryDates(
                start: Date(timeIntervalSince1970: 1451635200),
                end: Date(timeIntervalSince1970: 1451638800)
            ),
            BoundaryDates(
                start: Date(timeIntervalSince1970: 1451638800),
                end: Date(timeIntervalSince1970: 1451642400)
            ),
            BoundaryDates(
                start: Date(timeIntervalSince1970: 1451642400),
                end: Date(timeIntervalSince1970: 1451646000)
            ),
            BoundaryDates(
                start: Date(timeIntervalSince1970: 1451646000),
                end: Date(timeIntervalSince1970: 1451649600)
            ),
            BoundaryDates(
                start: Date(timeIntervalSince1970: 1451649600),
                end: Date(timeIntervalSince1970: 1451653200)
            ),
            BoundaryDates(
                start: Date(timeIntervalSince1970: 1451653200),
                end: Date(timeIntervalSince1970: 1451656800)
            ),
            BoundaryDates(
                start: Date(timeIntervalSince1970: 1451656800),
                end: Date(timeIntervalSince1970: 1451660400)
            ),
            BoundaryDates(
                start: Date(timeIntervalSince1970: 1451660400),
                end: Date(timeIntervalSince1970: 1451664000)
            ),
            BoundaryDates(
                start: Date(timeIntervalSince1970: 1451664000),
                end: Date(timeIntervalSince1970: 1451667600)
            ),
            BoundaryDates(
                start: Date(timeIntervalSince1970: 1451667600),
                end: Date(timeIntervalSince1970: 1451671200)
            ),
            BoundaryDates(
                start: Date(timeIntervalSince1970: 1451671200),
                end: Date(timeIntervalSince1970: 1451674800)
            ),
            BoundaryDates(
                start: Date(timeIntervalSince1970: 1451674800),
                end: Date(timeIntervalSince1970: 1451678400)
            ),
            BoundaryDates(
                start: Date(timeIntervalSince1970: 1451678400),
                end: Date(timeIntervalSince1970: 1451682000)
            ),
            BoundaryDates(
                start: Date(timeIntervalSince1970: 1451682000),
                end: Date(timeIntervalSince1970: 1451685600)
            ),
            BoundaryDates(
                start: Date(timeIntervalSince1970: 1451685600),
                end: Date(timeIntervalSince1970: 1451689200)
            ),
            BoundaryDates(
                start: Date(timeIntervalSince1970: 1451689200),
                end: Date(timeIntervalSince1970: 1451692800)
            ),
            BoundaryDates(
                start: Date(timeIntervalSince1970: 1451692800),
                end: Date(timeIntervalSince1970: 1451696400)
            ),
            BoundaryDates(
                start: Date(timeIntervalSince1970: 1451696400),
                end: Date(timeIntervalSince1970: 1451700000)
            ),
            BoundaryDates(
                start: Date(timeIntervalSince1970: 1451700000),
                end: Date(timeIntervalSince1970: 1451703600)
            ),
            BoundaryDates(
                start: Date(timeIntervalSince1970: 1451703600),
                end: Date(timeIntervalSince1970: 1451707200)
            ),
            BoundaryDates(
                start: Date(timeIntervalSince1970: 1451707200),
                end: Date(timeIntervalSince1970: 1451710800)
            )
        ])
    }

    func testDSTForwardDay()
    {
        var startComponents = DateComponents()
        startComponents.year = 2016
        startComponents.month = 3
        startComponents.day = 13

        var endComponents = DateComponents()
        endComponents.year = 2016
        endComponents.month = 3
        endComponents.day = 14

        let boundaries = calendar.boundaryDatesForHours(
            from: calendar.date(from: startComponents)!,
            to: calendar.date(from: endComponents)!
        )

        XCTAssertEqual(boundaries.count, 23)
    }

    func testDSTBackwardDay()
    {
        var startComponents = DateComponents()
        startComponents.year = 2016
        startComponents.month = 11
        startComponents.day = 6

        var endComponents = DateComponents()
        endComponents.year = 2016
        endComponents.month = 11
        endComponents.day = 7

        let boundaries = calendar.boundaryDatesForHours(
            from: calendar.date(from: startComponents)!,
            to: calendar.date(from: endComponents)!
        )

        let intervals = boundaries.map({ $0.end.timeIntervalSince($0.start) })
        XCTAssertEqual(intervals, [3600.0, 7200.0] + Array(repeating: 3600.0, count: 22))
    }
}
