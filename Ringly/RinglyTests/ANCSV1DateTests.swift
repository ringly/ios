@testable import Ringly
import XCTest

private let date = Date()

final class ANCSV1DateTests: XCTestCase
{
    fileprivate let notification = RLYANCSNotification(
        version: .version1,
        category: .other,
        applicationIdentifier: "test",
        title: "test",
        date: date,
        message: nil,
        flagsValue: nil
    )

    func testTooOld()
    {
        let tooOld = notification.dateTest(
            currentDate: date.addingTimeInterval(10),
            pastCutoffInterval: 1,
            futureCutoffInterval: 1
        )

        XCTAssertEqual(tooOld, .tooOld(notificationDate: date, cutoffDate: date.addingTimeInterval(9)))
    }

    func testTooNew()
    {
        let tooNew = notification.dateTest(
            currentDate: date.addingTimeInterval(-10),
            pastCutoffInterval: 1,
            futureCutoffInterval: 1
        )

        XCTAssertEqual(tooNew, .tooNew(notificationDate: date, cutoffDate: date.addingTimeInterval(-9)))
    }

    func testAcceptable()
    {
        let acceptable = notification.dateTest(
            currentDate: date,
            pastCutoffInterval: 1,
            futureCutoffInterval: 1
        )

        XCTAssertNil(acceptable)
    }
}
