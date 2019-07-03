import RinglyAPI
import XCTest

final class AuthenticationCodingTests: XCTestCase
{
    func testUnauthenticated()
    {
        let authentication = Authentication(user: nil, token: nil, server: .production)
        XCTAssertEqual(try Authentication.decode(authentication.encoded), authentication)
    }

    func testAuthenticated()
    {
        let authentication = Authentication(
            user: User(identifier: "1", email: "test", firstName: "Foo", lastName: "Bar", receiveUpdates: false),
            token: "test",
            server: .production
        )

        XCTAssertEqual(try Authentication.decode(authentication.encoded), authentication)
    }
}
