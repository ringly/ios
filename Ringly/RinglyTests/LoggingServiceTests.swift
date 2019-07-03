@testable import Ringly
import Nimble
import RealmSwift
import ReactiveSwift
import XCTest

final class LoggingServiceTests: XCTestCase
{
    // MARK: - Setup
    fileprivate var logging: LoggingService!
    fileprivate var scheduler: TestScheduler!

    override func setUp()
    {
        super.setUp()

        scheduler = TestScheduler()

        // logging service setup
        let path = "log-test-\(getpid())-\(UUID().uuidString)"
        let temporary = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(path)
        logging = try! LoggingService(storeURL: temporary, cutoff: 0.8, dateScheduler: scheduler)
    }

    // MARK: - Cases
    func testLogging()
    {
        logging.log("Test", type: .analytics)

        let messages = (try? logging.messages()) ?? []
        expect(messages) == [LoggingMessage(text: "Test", type: .analytics, date: scheduler.currentDate)]
    }

    func testNoExpirationWithoutLog()
    {
        let date = scheduler.currentDate
        logging.log("Expired", type: .analytics)
        scheduler.advance(by: .seconds(1))

        let messages = (try? logging.messages()) ?? []
        expect(messages) == [LoggingMessage(text: "Expired", type: .analytics, date: date)]
    }

    func testExpirationWithLog()
    {
        logging.log("Expired", type: .analytics)
        scheduler.advance(by: .seconds(1))
        logging.log("Test", type: .analytics)

        let messages = (try? logging.messages()) ?? []
        expect(messages) == [LoggingMessage(text: "Test", type: .analytics, date: scheduler.currentDate)]
    }
}
