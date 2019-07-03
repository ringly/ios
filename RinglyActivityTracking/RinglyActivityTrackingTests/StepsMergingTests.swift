@testable import RinglyActivityTracking
import Nimble
import XCTest

final class StepsMergingTests: XCTestCase
{
    // MARK: - Basic Cases
    func testEmptyStepsAreZero()
    {
        expect(Steps(timestampGroupedSteps: [TimestampedSteps]())) == Steps.zero
    }

    func testMergingNonDuplicateSteps()
    {
        let steps = [
            TimestampedSteps(timestamp: 0, walkingStepCount: 10, runningStepCount: 10),
            TimestampedSteps(timestamp: 1, walkingStepCount: 10, runningStepCount: 10),
            TimestampedSteps(timestamp: 2, walkingStepCount: 10, runningStepCount: 10)
        ]

        expect(Steps(timestampGroupedSteps: steps)) == Steps(walkingStepCount: 30, runningStepCount: 30)
    }

    // MARK: - Overlapping at Start
    func testMergingOverlappingStepsAtStartWithFirstMax()
    {
        let steps = [
            TimestampedSteps(timestamp: 0, walkingStepCount: 15, runningStepCount: 15),
            TimestampedSteps(timestamp: 0, walkingStepCount: 10, runningStepCount: 10),
            TimestampedSteps(timestamp: 2, walkingStepCount: 10, runningStepCount: 10)
        ]

        expect(Steps(timestampGroupedSteps: steps)) == Steps(walkingStepCount: 25, runningStepCount: 25)
    }

    func testMergingOverlappingStepsAtStartWithMiddleMax()
    {
        let steps = [
            TimestampedSteps(timestamp: 0, walkingStepCount: 10, runningStepCount: 10),
            TimestampedSteps(timestamp: 0, walkingStepCount: 15, runningStepCount: 15),
            TimestampedSteps(timestamp: 0, walkingStepCount: 10, runningStepCount: 10),
            TimestampedSteps(timestamp: 2, walkingStepCount: 10, runningStepCount: 10)
        ]

        expect(Steps(timestampGroupedSteps: steps)) == Steps(walkingStepCount: 25, runningStepCount: 25)
    }

    func testMergingOverlappingStepsAtStartWithLastMax()
    {
        let steps = [
            TimestampedSteps(timestamp: 0, walkingStepCount: 10, runningStepCount: 10),
            TimestampedSteps(timestamp: 0, walkingStepCount: 15, runningStepCount: 15),
            TimestampedSteps(timestamp: 2, walkingStepCount: 10, runningStepCount: 10)
        ]

        expect(Steps(timestampGroupedSteps: steps)) == Steps(walkingStepCount: 25, runningStepCount: 25)
    }

    // MARK: - Overlapping in Middle
    func testMergingOverlappingStepsInMiddleWithFirstMax()
    {
        let steps = [
            TimestampedSteps(timestamp: 1, walkingStepCount: 10, runningStepCount: 10),
            TimestampedSteps(timestamp: 0, walkingStepCount: 15, runningStepCount: 15),
            TimestampedSteps(timestamp: 0, walkingStepCount: 10, runningStepCount: 10),
            TimestampedSteps(timestamp: 2, walkingStepCount: 10, runningStepCount: 10)
        ]

        expect(Steps(timestampGroupedSteps: steps)) == Steps(walkingStepCount: 35, runningStepCount: 35)
    }

    func testMergingOverlappingStepsInMiddleWithMiddleMax()
    {
        let steps = [
            TimestampedSteps(timestamp: 1, walkingStepCount: 10, runningStepCount: 10),
            TimestampedSteps(timestamp: 0, walkingStepCount: 10, runningStepCount: 10),
            TimestampedSteps(timestamp: 0, walkingStepCount: 15, runningStepCount: 15),
            TimestampedSteps(timestamp: 0, walkingStepCount: 10, runningStepCount: 10),
            TimestampedSteps(timestamp: 2, walkingStepCount: 10, runningStepCount: 10)
        ]

        expect(Steps(timestampGroupedSteps: steps)) == Steps(walkingStepCount: 35, runningStepCount: 35)
    }

    func testMergingOverlappingStepsInMiddleWithLastMax()
    {
        let steps = [
            TimestampedSteps(timestamp: 1, walkingStepCount: 10, runningStepCount: 10),
            TimestampedSteps(timestamp: 0, walkingStepCount: 10, runningStepCount: 10),
            TimestampedSteps(timestamp: 0, walkingStepCount: 15, runningStepCount: 15),
            TimestampedSteps(timestamp: 2, walkingStepCount: 10, runningStepCount: 10)
        ]

        expect(Steps(timestampGroupedSteps: steps)) == Steps(walkingStepCount: 35, runningStepCount: 35)
    }

    // MARK: - Overlapping at End
    func testMergingOverlappingStepsAtEndWithFirstMax()
    {
        let steps = [
            TimestampedSteps(timestamp: 2, walkingStepCount: 10, runningStepCount: 10),
            TimestampedSteps(timestamp: 0, walkingStepCount: 15, runningStepCount: 15),
            TimestampedSteps(timestamp: 0, walkingStepCount: 10, runningStepCount: 10)
        ]

        expect(Steps(timestampGroupedSteps: steps)) == Steps(walkingStepCount: 25, runningStepCount: 25)
    }

    func testMergingOverlappingStepsAtEndWithMiddleMax()
    {
        let steps = [
            TimestampedSteps(timestamp: 2, walkingStepCount: 10, runningStepCount: 10),
            TimestampedSteps(timestamp: 0, walkingStepCount: 10, runningStepCount: 10),
            TimestampedSteps(timestamp: 0, walkingStepCount: 15, runningStepCount: 15),
            TimestampedSteps(timestamp: 0, walkingStepCount: 10, runningStepCount: 10)
        ]

        expect(Steps(timestampGroupedSteps: steps)) == Steps(walkingStepCount: 25, runningStepCount: 25)
    }

    func testMergingOverlappingStepsAtEndWithLastMax()
    {
        let steps = [
            TimestampedSteps(timestamp: 2, walkingStepCount: 10, runningStepCount: 10),
            TimestampedSteps(timestamp: 0, walkingStepCount: 10, runningStepCount: 10),
            TimestampedSteps(timestamp: 0, walkingStepCount: 15, runningStepCount: 15)
        ]

        expect(Steps(timestampGroupedSteps: steps)) == Steps(walkingStepCount: 25, runningStepCount: 25)
    }
}

private struct TimestampedSteps: TimestampedStepsData
{
    let timestamp: Int32
    let walkingStepCount: Int
    let runningStepCount: Int
}
