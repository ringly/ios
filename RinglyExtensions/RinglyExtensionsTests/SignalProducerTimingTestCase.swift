import ReactiveSwift
import Result
import RinglyExtensions
import XCTest

class SignalProducerTimingTestCase: XCTestCase
{
    // MARK: - Properties

    /// The start date of `scheduler`.
    let schedulerStartDate = Date()

    /// A scheduler for use in timing tests.
    private(set) var scheduler: TestScheduler!

    /// A disposable that will be cleaned up when the test is torn down.
    var disposable: Disposable?

    // MARK: - Setup and Teardown
    override func setUp()
    {
        super.setUp()
        scheduler = TestScheduler(startDate: schedulerStartDate)
    }

    override func tearDown()
    {
        super.tearDown()
        disposable?.dispose()
        disposable = nil
        scheduler = nil
    }
}
