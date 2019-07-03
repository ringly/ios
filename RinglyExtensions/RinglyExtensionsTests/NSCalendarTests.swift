import ReactiveSwift
import RinglyExtensions
import XCTest

final class NSCalendarDailyTimerTests: XCTestCase
{
    func testTimer()
    {
        var calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        var components = DateComponents()
        components.minute = 30
        components.hour = 8
        components.day = 10
        components.month = 3
        components.year = 2016

        let scheduler = TestScheduler(startDate: calendar.date(from: components)!)
        var dates: [Date] = []

        calendar.dailyTimer(on: scheduler).startWithValues({ dates.append($0) })
        XCTAssertEqual(dates.count, 0)

        components.hour = 18
        components.minute = 0
        scheduler.advance(to: calendar.date(from: components)!)
        XCTAssertEqual(dates.count, 0)

        components.day = 11
        components.hour = 0
        components.minute = 30
        scheduler.advance(to: calendar.date(from: components)!)
        XCTAssertEqual(dates.count, 1)
    }

    func testImmediateTimer()
    {
        var calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        var components = DateComponents()
        components.minute = 30
        components.hour = 8
        components.day = 10
        components.month = 3
        components.year = 2016

        let scheduler = TestScheduler(startDate: calendar.date(from: components)!)
        var dates: [Date] = []

        calendar.immediateDailyTimer(on: scheduler).startWithValues({ dates.append($0) })
        XCTAssertEqual(dates.count, 1)

        components.hour = 18
        components.minute = 0
        scheduler.advance(to: calendar.date(from: components)!)
        XCTAssertEqual(dates.count, 1)

        components.day = 11
        components.hour = 0
        components.minute = 30
        scheduler.advance(to: calendar.date(from: components)!)
        XCTAssertEqual(dates.count, 2)
    }
}
