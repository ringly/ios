@testable import Ringly
import Nimble
import XCTest

final class ApplicationConfigurationLoadingTests: XCTestCase
{
    func testLoadingSavedConfigurations()
    {
        expect(ApplicationConfiguration.loaded(
            from: encoded,
            supportedApplications: applications,
            makeNewConfiguration: ApplicationConfiguration.defaultMakeNewConfiguration
        )) == ApplicationConfiguration.LoadResult(configurations: configurations, newApplications: [])
    }

    func testLoadingSavedConfigurationsWithNewApplication()
    {
        expect(ApplicationConfiguration.loaded(
            from: encoded,
            supportedApplications: applications + [newApplication],
            makeNewConfiguration: { app, _ in
                ApplicationConfiguration(
                    application: app,
                    color: .red,
                    vibration: .twoPulses,
                    activated: false
                )
            }
        )) == ApplicationConfiguration.LoadResult(
            configurations: configurations + [ApplicationConfiguration(
                application: newApplication,
                color: .red,
                vibration: .twoPulses,
                activated: false
            )],
            newApplications: [newApplication]
        )
    }

    func testLoadingNilSavedConfigurations()
    {
        expect(ApplicationConfiguration.loaded(
            from: nil,
            supportedApplications: applications,
            makeNewConfiguration: { app, index in
                ApplicationConfiguration(
                    application: app,
                    color: DefaultColorFromIndex(UInt(index)),
                    vibration: RLYVibration(index: index),
                    activated: index % 2 == 0
                )
            }
        )) == ApplicationConfiguration.LoadResult(configurations: configurations, newApplications: [])
    }
}

private let applications: [SupportedApplication] = (0..<4).map({
    let name = "Test\($0)"
    return SupportedApplication(name: name, scheme: name, identifiers: [name], analyticsName: name)
})

private let configurations: [ApplicationConfiguration] = applications.enumerated().map({ index, application in
    ApplicationConfiguration(
        application: application,
        color: DefaultColorFromIndex(UInt(index)),
        vibration: RLYVibration(index: index),
        activated: index % 2 == 0
    )
})

private let encoded = configurations.map({ $0.encoded })

private let newApplication = SupportedApplication(name: "New", scheme: "new", identifiers: ["new"], analyticsName: "new")
