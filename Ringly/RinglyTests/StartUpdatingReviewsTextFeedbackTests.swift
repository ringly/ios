@testable import Ringly
import ReactiveSwift
import XCTest

final class StartUpdatingReviewsTextFeedbackTests: XCTestCase
{
    // MARK: - Setup
    fileprivate var disposable: Disposable?
    fileprivate var property: MutableProperty<ReviewsTextFeedback?>!
    fileprivate var scheduler: TestScheduler!
    fileprivate let defaultValue = ReviewsTextFeedback(feedback: .positive, text: nil)

    override func setUp()
    {
        super.setUp()
        property = MutableProperty(nil)
        scheduler = TestScheduler()
    }

    override func tearDown()
    {
        super.tearDown()
        disposable?.dispose()
        disposable = nil
    }

    // MARK: - Tests
    func testModifiesAfterSuccess()
    {
        property.value = defaultValue

        disposable = property.startUpdating(makeProducer: { feedback -> SignalProducer<(), TestError> in
            SignalProducer.empty.observe(on: self.scheduler)
        })

        scheduler.advance()

        XCTAssertNil(property.value)
    }

    func testDoesNotModifyAfterFailure()
    {
        property.value = defaultValue

        disposable = property.startUpdating(makeProducer: { feedback -> SignalProducer<(), TestError> in
            SignalProducer(error: TestError()).observe(on: self.scheduler)
        })

        scheduler.advance()

        XCTAssertEqual(property.value, defaultValue)
    }

    func testDoesNotModifyUntilSchedulerAdvances()
    {
        let value = ReviewsTextFeedback(feedback: .positive, text: nil)
        property.value = value

        disposable = property.startUpdating(makeProducer: { feedback -> SignalProducer<(), TestError> in
            SignalProducer.empty.observe(on: self.scheduler)
        })

        XCTAssertEqual(property.value, defaultValue)
    }
}

private struct TestError: Error {}
