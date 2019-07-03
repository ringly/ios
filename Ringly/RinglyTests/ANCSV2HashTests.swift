@testable import Ringly
import XCTest

class ANCSV2HashTests: XCTestCase
{
    // MARK: - String Hashes
    func testStringHashEquality()
    {
        XCTAssertEqual("ABCD".ANCSV2HashValue, "ABCD".ANCSV2HashValue)
        XCTAssertNotEqual("ABCDE".ANCSV2HashValue, "ABCD".ANCSV2HashValue)
        XCTAssertNotEqual("ABDD".ANCSV2HashValue, "ABCD".ANCSV2HashValue)
        XCTAssertNotEqual("".ANCSV2HashValue, "A".ANCSV2HashValue)
    }
    
    // MARK: - Packing
    func testHashPacking()
    {
        let first = "ABCD".ANCSV2HashValue
        let second = "EFGHIJK".ANCSV2HashValue
        
        let unpacked = ANCSV2PackedHash(packed: ANCSV2PackedHash(first: first, second: second).packed)
        
        XCTAssertEqual(first, unpacked.first)
        XCTAssertEqual(second, unpacked.second)
    }

    func testUInt32Rotate()
    {
        let value: UInt32 = 123456
        XCTAssertEqual(value, value.rotate(16).rotate(16))
    }
}
