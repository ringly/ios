import RinglyExtensions
import XCTest

final class SequenceTypeUnwrapTests: XCTestCase
{
    func testAllSome()
    {
        XCTAssertTrue([Optional.some(1), 2, 3].unwrapped.map({ $0 == [1, 2, 3] }) ?? false)
    }

    func testAllNone()
    {
        XCTAssertNil([Optional<Int>.none, nil, nil].unwrapped)
    }

    func testFirstNone()
    {
        XCTAssertNil([Optional<Int>.none, 2, 3].unwrapped)
    }

    func testMiddleNone()
    {
        XCTAssertNil([1, Optional<Int>.none, 3].unwrapped)
    }

    func testLastNone()
    {
        XCTAssertNil([1, 2, Optional<Int>.none].unwrapped)
    }

    func testEmpty()
    {
        XCTAssertTrue(Array<Int?>().unwrapped.map({ $0 == [] }) ?? false)
    }
}
