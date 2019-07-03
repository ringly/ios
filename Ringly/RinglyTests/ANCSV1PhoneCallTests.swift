@testable import Ringly
import RinglyKit
import XCTest

final class ANCSV1PhoneCallTests: XCTestCase
{
    fileprivate let applicationConfigurations = SupportedApplication.all.map({ app in
        ApplicationConfiguration(application: app, color: .blue, vibration: .onePulse, activated: true)
    })

    fileprivate let contactConfigurations: [ContactConfiguration] = [
        MockDataSource(identifier: "1", names: ["Foo"]),
        MockDataSource(identifier: "2", names: ["Bar"])
    ].map({ ContactConfiguration(dataSource: $0, color: .red) })

    func testPhoneCall()
    {
        let notification = RLYANCSNotification(
            version: .version1,
            category: .incomingCall,
            applicationIdentifier: "com.apple.mobilephone",
            title: "Test",
            date: nil,
            message: "Message",
            flagsValue: nil
        )

        let result = notification.ANCSV1TestResult(
            sentSignatures: [],
            applicationConfigurations: applicationConfigurations,
            contactConfigurations: [],
            innerRingEnabled: false
        )

        XCTAssertNotNil(result.value)
    }

    func testMissedCallMatchingInnerRing()
    {
        let notification = RLYANCSNotification(
            version: .version1,
            category: .missedCall,
            applicationIdentifier: "com.apple.mobilephone",
            title: "Foo",
            date: Date(),
            message: nil,
            flagsValue: nil
        )

        let result = notification.ANCSV1TestResult(
            sentSignatures: [],
            applicationConfigurations: applicationConfigurations,
            contactConfigurations: contactConfigurations,
            innerRingEnabled: true
        )

        XCTAssertNotNil(result.value)
    }

    func testMissedCallNotMatchingInnerRing()
    {
        let notification = RLYANCSNotification(
            version: .version1,
            category: .missedCall,
            applicationIdentifier: "com.apple.mobilephone",
            title: "Test",
            date: Date(),
            message: "Message",
            flagsValue: nil
        )

        let result = notification.ANCSV1TestResult(
            sentSignatures: [],
            applicationConfigurations: applicationConfigurations,
            contactConfigurations: contactConfigurations,
            innerRingEnabled: true
        )

        XCTAssertNil(result.value)
        XCTAssertEqual(result.error?.reason, .contacts)
    }
}
