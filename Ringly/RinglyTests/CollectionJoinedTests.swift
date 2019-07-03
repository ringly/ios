@testable import Ringly
import Nimble
import XCTest

final class CollectionJoinedTests: XCTestCase
{
    func testEmptyReturnsNil()
    {
        expect([String]().joined(singleSeparator: "1", initialSeparators: "2", lastSeparator: "3")).to(beNil())
    }

    func testSingleEchoes()
    {
        expect(["test"].joined(singleSeparator: "1", initialSeparators: "2", lastSeparator: "3")) == "test"
    }

    func testSingleSeparatorUsedForTwo()
    {
        expect(["a", "b"].joined(singleSeparator: "1", initialSeparators: "2", lastSeparator: "3")) == "a1b"
    }

    func testOtherSeparatorsUsedForThree()
    {
        expect(["a", "b", "c"].joined(singleSeparator: "1", initialSeparators: "2", lastSeparator: "3")) == "a2b3c"
    }

    func testOtherSeparatorsUsedCorrectlyForMore()
    {
        expect(["a", "b", "c", "d", "e", "f"].joined(singleSeparator: "1", initialSeparators: "2", lastSeparator: "3"))
            == "a2b2c2d2e3f"
    }
}
