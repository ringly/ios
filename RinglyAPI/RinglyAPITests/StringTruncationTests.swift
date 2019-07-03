@testable import RinglyAPI
import XCTest

final class StringTruncationTests: XCTestCase
{
    func testOverLength()
    {
        XCTAssertEqual("test".truncate(utf8: 10), "test")
    }
    
    func testEmojiOverLength()
    {
        XCTAssertEqual("test😄".truncate(utf8: 10), "test😄")
    }

    func testUnderLength()
    {
        XCTAssertEqual("test".truncate(utf8: 2), "te")
    }

    func testEmojiUnderLength()
    {
        XCTAssertEqual("test😄".truncate(utf8: 2), "te")
    }

    func testEmojiUnderLengthCutoff()
    {
        XCTAssertEqual("test😄".truncate(utf8: 5), "test")
    }

    func testEmojiUnderLengthEmpty()
    {
        XCTAssertEqual("😄".truncate(utf8: 2), "")
    }
}
