import ReactiveSwift
import RinglyExtensions
import XCTest
import enum Result.NoError

final class SignalProducerTimerUntilTests: XCTestCase
{
    var scheduler: TestScheduler!
    var disposable: Disposable?

    let startDate = Date(timeIntervalSince1970: 1000)
    let fireDate = Date(timeIntervalSince1970: 2000)

    var events: [Event<Date, NoError>] = []

    func addEvent(_ event: Event<Date, NoError>)
    {
        events.append(event)
    }

    override func setUp()
    {
        super.setUp()
        scheduler = TestScheduler(startDate: startDate)
    }

    override func tearDown()
    {
        super.tearDown()
        disposable?.dispose()
        disposable = nil
        events = []
    }

    func testDoNotSendIfDateUnpassed()
    {
        disposable = timerUntil(date: fireDate, on: scheduler).start(addEvent)
        XCTAssertEqual(events.count, 0)
    }

    func testSendIfDatePassedAfterStarted()
    {
        disposable = timerUntil(date: fireDate, on: scheduler).start(addEvent)
        scheduler.advance(to: fireDate)

        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events.first?.value, fireDate)
        XCTAssertTrue(events[safe: 1].map({ $0 == Event.completed }) ?? false)
    }

    func testSendIfDatePassedInitially()
    {
        scheduler.advance(to: fireDate)
        disposable = timerUntil(date: fireDate, on: scheduler).start(addEvent)
        scheduler.advance()

        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events.first?.value, fireDate)
        XCTAssertTrue(events[safe: 1].map({ $0 == Event.completed }) ?? false)
    }
}
