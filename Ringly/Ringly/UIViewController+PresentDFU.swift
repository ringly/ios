import ReactiveSwift
import Result
import RinglyAPI
import RinglyDFU
import RinglyKit

extension UIViewController
{
    /// Presents a DFU controller from the view controller.
    ///
    /// - Parameters:
    ///   - services: The services to use for DFU.
    ///   - peripheral: The peripheral to update.
    ///   - packageSource: The package source to retrieve the DFU package from.
    @nonobjc private func presentDFU(services: Services, peripheral: RLYPeripheral, packageSource: PackageSource)
    {
        services.analytics.track(AnalyticsDFUEvent.bannerTapped)

        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.switchTab(tab: .connection)
            
            let DFU = DFUViewController(services: services)
            DFU.transitioningDelegate = SlideTransitionController.sharedDelegate.vertical
            DFU.configure(mode: .Peripheral(peripheral: peripheral), packageSource: packageSource)
            
            DFU.completion = { $0.dismiss(animated: true, completion: nil) }
            
            DFU.failed = { controller in
                controller.dismiss(animated: true, completion: nil)
                let add = AddPeripheralViewController(services: services)
                // access navigation controller of PeripheralController
                let peripheralVC = appDelegate.window?.rootViewController?
                    .childViewControllers.first?.childViewControllers.first?
                    .childViewControllers.first?.childViewControllers.first as? PeripheralsViewController
                peripheralVC?.navigation.pushViewController(add, animated: true)
            }
            
            appDelegate.window?.rootViewController?.childViewControllers.first?.present(DFU, animated: true, completion: nil)
        }
    }

    /// Presents a DFU controller from the view controller.
    ///
    /// - Parameters:
    ///   - services: The services to use for DFU.
    ///   - peripheral: The peripheral to update.
    ///   - firmwareResult: The firmware result to use.
    @nonobjc func presentDFU(services: Services, peripheral: RLYPeripheral, firmwareResult: FirmwareResult)
    {
        presentDFU(
            services: services,
            peripheral: peripheral,
            packageSource: .firmwareResult(result: firmwareResult, APIService: services.api)
        )
    }

    /// Presents a DFU controller from the view controller, after loading a firmware result from `services`.
    ///
    /// - Parameters:
    ///   - services: The services to use for DFU.
    ///   - peripheral: The peripheral to load a firmware update for and update.
    @nonobjc func presentDFU(services: Services, peripheral: RLYPeripheral)
    {
        let identifier = peripheral.identifier

        presentDFU(
            services: services,
            peripheral: peripheral,
            packageSource: .futureFirmwareResult(
                producer: services.updates.firmwareResults.producer
                    .map({ $0[identifier] })
                    .skipNil()
                    .deresultify()
                    .attemptMap({ Result($0, failWith: PresentDFUError.noUpdateAvailable as NSError) })
                    .timeout(after: 10, raising: PresentDFUError.timeout as NSError, on: QueueScheduler.main),
                APIService: services.api
            )
        )
    }
}

extension ServicesViewController
{
    /// Presents a DFU controller from the view controller, using the view controller's services.
    ///
    /// - Parameters:
    ///   - peripheral: The peripheral to update.
    ///   - firmwareResult: The firmware result to use.
    @nonobjc func presentDFU(peripheral: RLYPeripheral, firmwareResult: FirmwareResult)
    {
        presentDFU(services: services, peripheral: peripheral, firmwareResult: firmwareResult)
    }
}

enum PresentDFUError: Int, Error
{
    case noUpdateAvailable
    case timeout
}

extension PresentDFUError: CustomNSError
{
    static let domain = "PresentDFUError"
}

extension PresentDFUError: LocalizedError
{
    var localizedDescription: String { return tr(.uhOh) }

    var failureReason: String?
    {
        switch self
        {
        case .noUpdateAvailable:
            return "No update available."
        case .timeout:
            return "Timed out"
        }
    }
}
