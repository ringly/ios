@testable import Ringly
import RinglyKit
import XCTest

final class RLYVibrationIndexTests: XCTestCase
{
    func testVibrationFromIndices()
    {
        XCTAssertEqual(RLYVibration(index: 0), RLYVibration.onePulse)
        XCTAssertEqual(RLYVibration(index: 1), RLYVibration.twoPulses)
        XCTAssertEqual(RLYVibration(index: 2), RLYVibration.threePulses)
        XCTAssertEqual(RLYVibration(index: 3), RLYVibration.fourPulses)
        XCTAssertEqual(RLYVibration(index: 4), RLYVibration.none)
        XCTAssertEqual(RLYVibration(index: 5), RLYVibration.none)
    }

    func testVibrationToIndices()
    {
        XCTAssertEqual(RLYVibration.onePulse.index, 0)
        XCTAssertEqual(RLYVibration.twoPulses.index, 1)
        XCTAssertEqual(RLYVibration.threePulses.index, 2)
        XCTAssertEqual(RLYVibration.fourPulses.index, 3)
        XCTAssertEqual(RLYVibration.none.index, 4)
    }
}
