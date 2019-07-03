@testable import Ringly
import Nimble
import XCTest

class NSUUIDCodableTests: XCTestCase
{
    func testCoding()
    {
        let uuid = UUID()
        expect(try UUID.decode(uuid.encoded)) == uuid
    }

    func testInvalidEncoded()
    {
        expect(try UUID.decode("not-a-valid-uuid")).to(throwError())
    }
}
