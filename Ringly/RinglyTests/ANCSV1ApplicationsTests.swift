@testable import Ringly
import RinglyKit
import XCTest

final class ANCSV1ApplicationsTests: XCTestCase
{
    fileprivate let configurations = [
        ApplicationConfiguration(
            application: SupportedApplication(name: "On", scheme: "on", identifiers: ["on"], analyticsName: "On"),
            color: .blue,
            vibration: .onePulse,
            activated: true
        ),
        ApplicationConfiguration(
            application: SupportedApplication(name: "Off", scheme: "off", identifiers: ["off"], analyticsName: "Off"),
            color: .blue,
            vibration: .onePulse,
            activated: false
        )
    ]

    func testActivatedApplication()
    {
        let notification = RLYANCSNotification(
            version: .version1,
            category: .other,
            applicationIdentifier: "on",
            title: "Title",
            date: nil,
            message: "Message",
            flagsValue: nil
        )

        let result = notification.applicationsTest(configurations: configurations)
        XCTAssertEqual(result.value, configurations[0])
        XCTAssertNil(result.error)
    }

    func testNonActivatedApplication()
    {
        let notification = RLYANCSNotification(
            version: .version1,
            category: .other,
            applicationIdentifier: "off",
            title: "Title",
            date: nil,
            message: nil,
            flagsValue: nil
        )

        let result = notification.applicationsTest(configurations: configurations)
        XCTAssertEqual(result.error, .applicationNotActivated)
        XCTAssertNil(result.value)
    }

    func testNoApplicationConfiguration()
    {
        let notification = RLYANCSNotification(
            version: .version1,
            category: .other,
            applicationIdentifier: "fake",
            title: "Title",
            date: nil,
            message: "Message",
            flagsValue: nil
        )

        let result = notification.applicationsTest(configurations: configurations)
        XCTAssertEqual(result.error, .noApplicationConfiguration)
        XCTAssertNil(result.value)
    }
}
