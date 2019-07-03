import RinglyExtensions
import XCTest

final class DeviceScreenHeightSelectTests: XCTestCase
{
    func testFour()
    {
        let height = DeviceScreenHeight.four

        XCTAssertEqual(height.select(
            four: 1,
            five: 2,
            six: 3,
            sixPlus: 4,
            preferred: 5
        ), 1)

        XCTAssertEqual(height.select(
            five: 2,
            six: 3,
            sixPlus: 4,
            preferred: 5
        ), 2)

        XCTAssertEqual(height.select(
            six: 3,
            sixPlus: 4,
            preferred: 5
        ), 3)

        XCTAssertEqual(height.select(
            sixPlus: 4,
            preferred: 5
        ), 4)

        XCTAssertEqual(height.select(
            preferred: 5
        ), 5)
    }

    func testFive()
    {
        let height = DeviceScreenHeight.five

        XCTAssertEqual(height.select(
            four: 1,
            five: 2,
            six: 3,
            sixPlus: 4,
            preferred: 5
        ), 2)

        XCTAssertEqual(height.select(
            five: 2,
            six: 3,
            sixPlus: 4,
            preferred: 5
        ), 2)

        XCTAssertEqual(height.select(
            six: 3,
            sixPlus: 4,
            preferred: 5
        ), 3)

        XCTAssertEqual(height.select(
            sixPlus: 4,
            preferred: 5
        ), 4)

        XCTAssertEqual(height.select(
            preferred: 5
        ), 5)
    }

    func testSix()
    {
        let height = DeviceScreenHeight.six

        XCTAssertEqual(height.select(
            four: 1,
            five: 2,
            six: 3,
            sixPlus: 4,
            preferred: 5
        ), 3)

        XCTAssertEqual(height.select(
            five: 2,
            six: 3,
            sixPlus: 4,
            preferred: 5
        ), 3)

        XCTAssertEqual(height.select(
            six: 3,
            sixPlus: 4,
            preferred: 5
        ), 3)

        XCTAssertEqual(height.select(
            sixPlus: 4,
            preferred: 5
        ), 4)

        XCTAssertEqual(height.select(
            preferred: 5
        ), 5)
    }

    func testSixPlus()
    {
        let height = DeviceScreenHeight.sixPlus

        XCTAssertEqual(height.select(
            four: 1,
            five: 2,
            six: 3,
            sixPlus: 4,
            preferred: 5
        ), 4)

        XCTAssertEqual(height.select(
            five: 2,
            six: 3,
            sixPlus: 4,
            preferred: 5
        ), 4)

        XCTAssertEqual(height.select(
            six: 3,
            sixPlus: 4,
            preferred: 5
        ), 4)

        XCTAssertEqual(height.select(
            sixPlus: 4,
            preferred: 5
        ), 4)

        XCTAssertEqual(height.select(
            preferred: 5
        ), 5)
    }

    func testPad()
    {
        let height = DeviceScreenHeight.pad

        XCTAssertEqual(height.select(
            four: 1,
            five: 2,
            six: 3,
            sixPlus: 4,
            preferred: 5
        ), 5)

        XCTAssertEqual(height.select(
            five: 2,
            six: 3,
            sixPlus: 4,
            preferred: 5
        ), 5)

        XCTAssertEqual(height.select(
            six: 3,
            sixPlus: 4,
            preferred: 5
        ), 5)

        XCTAssertEqual(height.select(
            sixPlus: 4,
            preferred: 5
        ), 5)

        XCTAssertEqual(height.select(
            preferred: 5
        ), 5)
    }
}
