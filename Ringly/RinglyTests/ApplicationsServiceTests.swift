@testable import Ringly
import XCTest

final class ApplicationsServiceTests: XCTestCase
{
    func testDefaultActivatedConfigurations()
    {
        let applications = SupportedApplication.all

        let service = ApplicationsService(
            configurations: ApplicationConfiguration.loaded(
                from: nil,
                supportedApplications: applications,
                makeNewConfiguration: ApplicationConfiguration.defaultMakeNewConfiguration
            ).configurations,
            supportedApplications: applications
        )

        XCTAssertEqual(
            service.activatedConfigurations.value,
            ApplicationConfiguration.defaultActivatedConfigurations(for: applications)
        )
    }
}
