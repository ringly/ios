@testable import Ringly
import XCTest

final class SequenceTypeTests: XCTestCase
{
    let configurations = SupportedApplication.all.map({ app in
        ApplicationConfiguration(application: app, color: .blue, vibration: .none, activated: true)
    })

    func testApplicationConfigurationCropping()
    {
        XCTAssertNotNil(
            configurations.configurationMatching(
                applicationIdentifier: "com.newtoyinc.NewWordsWithFrien",
                trimLengthToMatch: true
            )
        )

        XCTAssertNil(
            configurations.configurationMatching(
                applicationIdentifier: "com.newtoyinc.NewWordsWithFrien",
                trimLengthToMatch: false
            )
        )
    }
}
