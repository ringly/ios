@testable import RinglyAPI
import XCTest

class RESTRequestTests: XCTestCase
{
    func testUsers()
    {
        let baseURL = URL(string: "http://api.test/")!

        XCTAssertEqual(
            RESTGetRequest<User>(identifier: "me").request(for: baseURL),
            URLRequest(url: URL(string: "http://api.test/users/me")!)
        )
    }
}
