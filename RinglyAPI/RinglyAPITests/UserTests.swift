import RinglyAPI
import XCTest

final class UserCodingTests: XCTestCase
{
    func testFirstAndLastName()
    {
        let user = User(identifier: "1", email: "test", firstName: "Foo", lastName: "Bar", receiveUpdates: false)
        XCTAssertEqual(try? User.decode(user.encoded), user)
    }

    func testFirstNameOnly()
    {
        let user = User(identifier: "1", email: "test", firstName: "Foo", lastName: nil, receiveUpdates: false)
        XCTAssertEqual(try? User.decode(user.encoded), user)
    }

    func testLastNameOnly()
    {
        let user = User(identifier: "1", email: "test", firstName: nil, lastName: "Bar", receiveUpdates: false)
        XCTAssertEqual(try? User.decode(user.encoded), user)
    }

    func testNeitherName()
    {
        let user = User(identifier: "1", email: "test", firstName: nil, lastName: nil, receiveUpdates: false)
        XCTAssertEqual(try? User.decode(user.encoded), user)
    }
}

final class UserNameTests: XCTestCase
{
    func testFullFirstAndFullLastName()
    {
        XCTAssertEqual(
            User(identifier: "1", email: "test", firstName: "Foo", lastName: "Bar", receiveUpdates: false).name,
            "Foo Bar"
        )
    }

    func testFullFirstAndNullLastName()
    {
        XCTAssertEqual(
            User(identifier: "1", email: "test", firstName: "Foo", lastName: nil, receiveUpdates: false).name,
            "Foo"
        )
    }

    func testNullFirstAndFullLastName()
    {
        XCTAssertEqual(
            User(identifier: "1", email: "test", firstName: nil, lastName: "Bar", receiveUpdates: false).name,
            "Bar"
        )
    }

    func testFullFirstAndEmptyLastName()
    {
        XCTAssertEqual(
            User(identifier: "1", email: "test", firstName: "Foo", lastName: "", receiveUpdates: false).name,
            "Foo"
        )
    }

    func testEmptyFirstAndFullLastName()
    {
        XCTAssertEqual(
            User(identifier: "1", email: "test", firstName: "", lastName: "Bar", receiveUpdates: false).name,
            "Bar"
        )
    }

    func testEmptyFirstAndEmptyLastName()
    {
        XCTAssertNil(
            User(identifier: "1", email: "test", firstName: "", lastName: "", receiveUpdates: false).name
        )
    }

    func testNullFirstAndNullLastName()
    {
        XCTAssertNil(
            User(identifier: "1", email: "test", firstName: nil, lastName: nil, receiveUpdates: false).name
        )
    }

    func testNullFirstAndEmptyLastName()
    {
        XCTAssertNil(
            User(identifier: "1", email: "test", firstName: nil, lastName: "", receiveUpdates: false).name
        )
    }

    func testEmptyFirstAndNullLastName()
    {
        XCTAssertNil(
            User(identifier: "1", email: "test", firstName: "", lastName: nil, receiveUpdates: false).name
        )
    }
}
