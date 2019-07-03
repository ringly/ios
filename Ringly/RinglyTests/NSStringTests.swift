import Nimble
import RinglyExtensions
import XCTest

class RinglyNSStringTests: XCTestCase
{    
    func testNames()
    {
        XCTAssertEqual("Foo Bar".rly_firstName, "Foo", "")
        XCTAssertEqual("Foo Bar".rly_lastName, "Bar", "")
        
        XCTAssertEqual("Foo Bar Baz".rly_firstName, "Foo", "")
        XCTAssertEqual("Foo Bar Baz".rly_lastName, "Bar Baz", "")
        
        XCTAssertEqual("Foo".rly_firstName, "Foo", "")
        XCTAssertNil("Foo".rly_lastName, "")

        expect("Foo Bar".rly_firstAndLastName as? [String]) == ["Foo", "Bar"]
    }
    
    func testVersionComparison()
    {
        XCTAssertEqual("1.0".rly_compareVersionNumbers("1.0"), ComparisonResult.orderedSame, "")
        XCTAssertEqual("1.0".rly_compareVersionNumbers("0.9"), ComparisonResult.orderedDescending, "")
        XCTAssertEqual("1.0".rly_compareVersionNumbers("1.1"), ComparisonResult.orderedAscending, "")
        XCTAssertEqual("1.0".rly_compareVersionNumbers("1.0.1"), ComparisonResult.orderedAscending, "")
        XCTAssertEqual("1.1".rly_compareVersionNumbers("1.0.1"), ComparisonResult.orderedDescending, "")
        XCTAssertEqual("1.3.2-9".rly_compareVersionNumbers("1.3.2"), ComparisonResult.orderedDescending, "")
    }
    
    func testVersionConversion()
    {
        XCTAssertEqual("1.0".rly_versionNumber(withSeparator: "-"), "1-0", "")
        XCTAssertEqual("1.3.2-9".rly_versionNumber(withSeparator: "."), "1.3.2.9", "")
    }
    
    func testTrimmedToLengthOfString()
    {
        XCTAssertEqual("loooooooong".trimmedTo(length: 5), "loooo")
        XCTAssertEqual("short".trimmedTo(length: 10), "short")
        XCTAssertEqual("same".trimmedTo(length: 4), "same")
    }

    func testVersionNumberIsBetween()
    {
        expect("2.1".versionNumberIs(after: "2.0", before: "2.2")) == true
    }

    func testVersionNumberIsAfter()
    {
        expect("2.3".versionNumberIs(after: "2.0", before: "2.2")) == false
    }

    func testVersionNumberIsBefore()
    {
        expect("1.0".versionNumberIs(after: "2.0", before: "2.2")) == false
    }

    func testVersionNumberIsOnLowerBound()
    {
        expect("2.0".versionNumberIs(after: "2.0", before: "2.2")) == false
    }

    func testVersionNumberIsOnUpperBound()
    {
        expect("2.2".versionNumberIs(after: "2.0", before: "2.2")) == false
    }
}
