@testable import Ringly
import RinglyExtensions
import RinglyKit
import XCTest

struct MockDataSource
{
    let identifier: String
    let names: [String]
    let image = UIImage?.none
}

extension MockDataSource: ContactDataSource
{
    var displayName: String { return names[0] }
    var dictionaryRepresentation: [String:AnyObject] { return [:] }
}

@available(iOS 9.0, *)
final class ANCSV1ContactsTest: XCTestCase
{
    fileprivate let contacts: [ContactConfiguration] = [
        MockDataSource(identifier: "1", names: ["Foo"]),
        MockDataSource(identifier: "2", names: ["Bar"])
    ].map({ ContactConfiguration(dataSource: $0, color: .red) })

    func testContactPresentWithInnerRing()
    {
        let notification = RLYANCSNotification(
            version: .version1,
            category: .incomingCall,
            applicationIdentifier: "com.apple.mobilephone",
            title: "Foo",
            date: nil,
            message: "Bar",
            flagsValue: nil
        )

        let result = notification.contactsTest(configurations: contacts, innerRingEnabled: true)
        XCTAssertNil(result.error)
        XCTAssertNotNil(result.value.flatten())
    }

    func testContactPresentWithoutInnerRing()
    {
        let notification = RLYANCSNotification(
            version: .version1,
            category: .incomingCall,
            applicationIdentifier: "com.apple.mobilephone",
            title: "Foo",
            date: nil,
            message: nil,
            flagsValue: nil
        )

        let result = notification.contactsTest(configurations: contacts, innerRingEnabled: false)
        XCTAssertNil(result.error)
        XCTAssertNotNil(result.value.flatten())
    }

    func testContactNotPresentWithInnerRing()
    {
        let notification = RLYANCSNotification(
            version: .version1,
            category: .incomingCall,
            applicationIdentifier: "com.apple.mobilephone",
            title: "Baz",
            date: nil,
            message: "Foo",
            flagsValue: nil
        )

        let result = notification.contactsTest(configurations: contacts, innerRingEnabled: true)
        XCTAssertEqual(result.error, .contacts)
        XCTAssertNil(result.value.flatten())
    }

    func testContactNotPresentWithoutInnerRing()
    {
        let notification = RLYANCSNotification(
            version: .version1,
            category: .incomingCall,
            applicationIdentifier: "com.apple.mobilephone",
            title: "Baz",
            date: nil,
            message: "test",
            flagsValue: nil
        )

        let result = notification.contactsTest(configurations: contacts, innerRingEnabled: false)
        XCTAssertNil(result.error)
        XCTAssertNil(result.value.flatten())
    }

    func testNonInnerRingApp()
    {
        let notification = RLYANCSNotification(
            version: .version1,
            category: .incomingCall,
            applicationIdentifier: "test",
            title: "Baz",
            date: nil,
            message: nil,
            flagsValue: nil
        )

        let result = notification.contactsTest(configurations: contacts, innerRingEnabled: false)
        XCTAssertNil(result.error)
        XCTAssertNil(result.value.flatten())
    }
}
