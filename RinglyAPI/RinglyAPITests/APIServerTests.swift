import RinglyAPI
import XCTest

final class APIServerCodingTests: XCTestCase
{
    func testProduction()
    {
        XCTAssertEqual(try APIServer.decode(APIServer.production.encoded), APIServer.production)
    }

    func testStaging()
    {
        XCTAssertEqual(try APIServer.decode(APIServer.staging.encoded), APIServer.staging)
    }

    func testCustom()
    {
        let server = APIServer.custom(appToken: "test", baseURL: URL(string: "http://test.com")!)
        XCTAssertEqual(try APIServer.decode(server.encoded), server)
    }
}
