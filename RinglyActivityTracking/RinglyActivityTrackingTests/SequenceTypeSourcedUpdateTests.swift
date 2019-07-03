@testable import RinglyActivityTracking
import RinglyKit
import XCTest

final class SequenceTypeSourcedUpdateTests: XCTestCase
{
    fileprivate let updates = [
        SourcedUpdate(
            macAddress: 1,
            update: RLYActivityTrackingUpdate(
                date: try! RLYActivityTrackingDate(minute: 10),
                walkingSteps: 10,
                runningSteps: 10
            )
        ),
        SourcedUpdate(
            macAddress: 1,
            update: RLYActivityTrackingUpdate(
                date: try! RLYActivityTrackingDate(minute: 11),
                walkingSteps: 10,
                runningSteps: 10
            )
        ),
        SourcedUpdate(
            macAddress: 1,
            update: RLYActivityTrackingUpdate(
                date: try! RLYActivityTrackingDate(minute: 12),
                walkingSteps: 10,
                runningSteps: 10
            )
        ),
        SourcedUpdate(
            macAddress: 1,
            update: RLYActivityTrackingUpdate(
                date: try! RLYActivityTrackingDate(minute: 13),
                walkingSteps: 10,
                runningSteps: 10
            )
        )
    ]

    func testBucket()
    {
        let bucketed = updates.bucketed(minutesDenominator: 1)

        XCTAssertEqual(bucketed.count, 4)
        XCTAssertEqual(bucketed[10], [updates[0]])
        XCTAssertEqual(bucketed[11], [updates[1]])
        XCTAssertEqual(bucketed[12], [updates[2]])
        XCTAssertEqual(bucketed[13], [updates[3]])
    }

    func testBucketWithDenominator()
    {
        let bucketed = updates.bucketed(minutesDenominator: 2)

        XCTAssertEqual(bucketed.count, 2)
        XCTAssertEqual(bucketed[5], [updates[0], updates[1]])
        XCTAssertEqual(bucketed[6], [updates[2], updates[3]])
    }
}
