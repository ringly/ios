@testable import Ringly
import ReactiveSwift
import XCTest

final class StartUpdatingReviewsStateTests: XCTestCase
{
    // MARK: - Setup
    var disposable: Disposable?
    var property: MutableProperty<ReviewsState?>!
    var scheduler: TestScheduler!

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

    // MARK: - Cases
//    func testModifiesAfterDateWhenStarted()
//    {
//        property.value = .displayAfter(Date(timeIntervalSinceReferenceDate: 0))
//        scheduler.advance(to: Date(timeIntervalSinceReferenceDate: 1))
//        disposable = property.startUpdatingReviewsState(on: scheduler, defaultAfterDuration: 1)
//        XCTAssertEqual(property.value, .display(.prompt))
//    }
//
//    func testDoesNotModifyBeforeDateWhenStarted()
//    {
//        let date = Date(timeIntervalSinceReferenceDate: 1)
//        property.value = .displayAfter(date)
//        scheduler.advance(to: Date(timeIntervalSinceReferenceDate: 0))
//        disposable = property.startUpdatingReviewsState(on: scheduler, defaultAfterDuration: 1)
//        XCTAssertEqual(property.value, .displayAfter(date))
//    }
//
//    func testModifiesWhenDatePassed()
//    {
//        property.value = .displayAfter(Date(timeIntervalSinceReferenceDate: 1))
//        scheduler.advance(to: Date(timeIntervalSinceReferenceDate: 0))
//        disposable = property.startUpdatingReviewsState(on: scheduler, defaultAfterDuration: 1)
//        scheduler.advance(to: Date(timeIntervalSinceReferenceDate: 2))
//        XCTAssertEqual(property.value, .display(.prompt))
//    }
//
//    func testSetsDefaultAfterDuration()
//    {
//        scheduler.advance(to: Date(timeIntervalSinceReferenceDate: 0))
//        disposable = property.startUpdatingReviewsState(on: scheduler, defaultAfterDuration: 1)
//        XCTAssertEqual(property.value, .displayAfter(Date(timeIntervalSinceReferenceDate: 1)))
//    }
//
//    func testDoesNotModifyAfterDuration()
//    {
//        let date = Date(timeIntervalSinceReferenceDate: 1)
//        property.value = .displayAfter(date)
//        scheduler.advance(to: Date(timeIntervalSinceReferenceDate: 0))
//        disposable = property.startUpdatingReviewsState(on: scheduler, defaultAfterDuration: 2)
//
//        XCTAssertEqual(property.value, .displayAfter(date))
//    }
}
