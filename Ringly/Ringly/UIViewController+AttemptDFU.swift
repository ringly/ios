import ReactiveSwift
import Result
import RinglyAPI
import RinglyExtensions
import RinglyKit
import UIKit

extension UIViewController
{
    /// Attempts to launch application-only DFU for a specific firmware version.
    ///
    /// - Parameters:
    ///   - services: The services to use for DFU.
    ///   - hardwareVersions: The hardware versions to look up application firmware for.
    ///   - applicationVersion: The application version to look up.
    @nonobjc func attemptDFU(services: Services, hardwareVersions: [String], applicationVersion: String)
    {
        // prompt the user to select a peripheral (or don't, if there's only one to choose from)
        let selectPeripheral = selectDFUPeripheral(services: services, hardwareVersions: hardwareVersions)

        // download all firmware versions, and select the one matching the requested version
        let firmware = selectPeripheral.flatMap(.concat, transform: { peripheral, hardwareVersion in
            services.api.firmwareResult(forHardware: hardwareVersion, matchingApplication: applicationVersion)
                .map({ (peripheral: peripheral, firmware: $0) })
        })

        // present the result on the view controller
        firmware.observe(on: UIScheduler()).startWithResult({ [weak self] result in
            switch result
            {
            case let .success(peripheral, firmwareResult):
                self?.presentDFU(
                    services: services,
                    peripheral: peripheral,
                    firmwareResult: firmwareResult
                )

            case let .failure(error):
                self?.presentError(error)
            }
        })
    }

    /// Presents a selection interface for a peripheral of a specific firmware version.
    ///
    /// - Parameters:
    ///   - services: The services to retrieve peripherals from.
    ///   - hardwareVersions: The hardware versions to permit.
    @nonobjc private func selectDFUPeripheral(services: Services, hardwareVersions: [String])
        -> SignalProducer<(peripheral: RLYPeripheral, hardwareVersion: String), NSError>
    {
        // select only peripherals that have hardware versions matching the acceptable values
        let peripherals = services.peripherals.peripherals.value.flatMap({ peripheral in
            peripheral.hardwareVersion.flatMap({ version in
                hardwareVersions.contains(version)
                    ? (peripheral: peripheral, hardwareVersion: version)
                    : nil
            })
        })

        // show different interfaces (or fail) depending on
        switch peripherals.count
        {
        case 0:
            return SignalProducer(
                error: AttemptDFUError.noPeripheralsMatching(hardwareVersions: hardwareVersions) as NSError
            )

        case 1:
            return SignalProducer(value: peripherals[0])

        default:
            return UIAlertController.choose(
                preferredStyle: .alert,
                inViewController: self,
                choices: peripherals.map({ AlertControllerChoice(title: $0.peripheral.displayName, value: $0) })
            ).promoteErrors(NSError.self)
        }
    }
}

extension APIService
{
    fileprivate func firmwareResult(forHardware hardware: String, matchingApplication application: String)
        -> SignalProducer<FirmwareResult, NSError>
    {
        return resultProducer(for: FirmwareRequest.all(hardware: hardware)).attemptMap({ result in
            Result(
                result.applications.first(where: { $0.version == application }),
                failWith: AttemptDFUError.noApplicationMatching(applicationVersion: application) as NSError
            ).map({ FirmwareResult(applications: [$0], bootloaders: []) })
        })
    }
}

enum AttemptDFUError: Error
{
    case noApplicationMatching(applicationVersion: String)
    case noPeripheralsMatching(hardwareVersions: [String])
}

extension AttemptDFUError: CustomNSError
{
    static let errorDomain = "AttemptDFUError"

    var errorCode: Int
    {
        switch self
        {
        case .noApplicationMatching:
            return 0
        case .noPeripheralsMatching:
            return 1
        }
    }
}

extension AttemptDFUError: LocalizedError
{
    var errorDescription: String? { return "Update Error" }

    var failureReason: String?
    {
        switch self
        {
        case let .noApplicationMatching(version):
            return "No application version matching “\(version)” found."
        case let .noPeripheralsMatching(versions):
            return "No peripherals with matching hardware versions found: \(versions)"
        }
    }
}
