import Nimble
import XCTest

final class ArrayDeduplicateTests: XCTestCase
{
    func testDuplicatesRemoved()
    {
        expect([1, 2, 2, 3, 4].deduplicateWithKeyFunction({ $0 })) == [1, 2, 3, 4]
    }

    func testNoDuplicatesNotRemoved()
    {
        let array = [1, 2, 3, 4]
        expect(array.deduplicateWithKeyFunction({ $0 })) == array
    }

    func testKeyFunctionOrder()
    {
        expect(["hello", "world", "foo", "bar"].deduplicateWithKeyFunction({ $0.characters.count })) == ["hello", "foo"]
    }
}

final class ArrayShiftTests: XCTestCase
{
    fileprivate let base = [1, 2, 3, 4, 5]

    func testShiftForward()
    {
        expect(self.base.shift(by: 2)) == [4, 5, 1, 2, 3]
    }

    func testShiftBackwards()
    {
        expect(self.base.shift(by: -2)) == [3, 4, 5, 1, 2]
    }

    func testZeroShift()
    {
        expect(self.base.shift(by: 0)) == base
    }
}
