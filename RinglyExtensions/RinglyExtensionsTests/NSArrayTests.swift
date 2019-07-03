import RinglyExtensions
import XCTest

class RinglyNSArrayTests: XCTestCase
{
    // MARK:- Array Functional
    func testMapToCount() {
        let mapped = NSArray.rly_map(toCount: 4, with: { (index) -> AnyObject! in
            return index as NSNumber
        }) as NSArray
        
        let expected = NSArray(array: [0, 1, 2, 3])
        XCTAssertEqual(mapped, expected, "Arrays should be equal")
    }
    
    func testMapToCountEmpty() {
        let mapped = NSArray.rly_map(toCount: 0, with: { (index) -> AnyObject! in
            return index as NSNumber
        }) as NSArray
        
        let expected = NSArray(array: [])
        XCTAssertEqual(mapped, expected, "Arrays should be equal")
    }
}
