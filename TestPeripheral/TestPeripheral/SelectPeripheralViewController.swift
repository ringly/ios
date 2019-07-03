import ReactiveSwift
import ReactiveRinglyKit
import Result
import RinglyKit
import UIKit

final class SelectPeripheralViewController: UIViewController
{
    // MARK: - Subviews
    @IBOutlet var tableView: UITableView?

    // MARK: - Peripherals
    fileprivate var central: RLYCentral?
    fileprivate var peripherals: [RLYPeripheral] = []
    {
        didSet { tableView?.reloadData() }
    }

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        title = "Select Peripheral"
        central = RLYCentral()

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(SelectPeripheralViewController.reloadAction)
        )
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        reloadAction()

        tableView?.indexPathsForVisibleRows?.forEach({ tableView?.deselectRow(at: $0, animated: animated) })
    }

    // MARK: - Actions
    @objc fileprivate func reloadAction()
    {
        peripherals = central?.retrieveConnectedPeripherals() ?? []
    }
}

extension SelectPeripheralViewController
{
    // MARK: - Presenting Tests
    fileprivate func presentTests(peripheral: RLYPeripheral, knownHardwareVersion: RLYKnownHardwareVersion)
    {
        if let central = self.central
        {
            let controller = TestViewController()

            controller.configuration.value = (
                central: central,
                peripheral: peripheral,
                hardwareVersion: knownHardwareVersion
            )

            navigationController?.pushViewController(controller, animated: true)
        }
    }

    fileprivate func discoverVersionAndPresentTests(peripheral: RLYPeripheral)
    {
        enum LoaderError: Error
        {
            case cancel
            case error(NSError)
        }

        central?.connect(to: peripheral)

        // wait until the peripheral is connected before reading data
        let connectedProducer = peripheral.reactive.validated
            .filter({ $0 })
            .take(first: 1)
            .promoteErrors(NSError.self)
            .timeout(
                after: 10,
                raising: NSError(domain: "Timeout", code: 0, userInfo: nil),
                on: QueueScheduler.main
            )

        // read the peripheral's device information characteristics, which include the hardware version
        let readProducer = connectedProducer.flatMap(.latest, transform: { _ -> SignalProducer<(), NSError> in
            let readResult = Result<(), NSError>(attempt: { try peripheral.readDeviceInformationCharacteristics() })
            return SignalProducer(result: readResult)
        })

        // read the hardware version
        let readHardwareProducer = readProducer
            .flatMapError({ error in SignalProducer(error: LoaderError.error(error)) })
            .then(peripheral.reactive.knownHardwareVersionProducer.skipNil().promoteErrors(LoaderError.self))

        // display an alert while hardware information is loaded
        let alert = SignalProducer<(), LoaderError> { [weak self] observer, disposable in
            let controller = UIAlertController(
                title: "Loading Hardware Information",
                message: nil,
                preferredStyle: .alert
            )

            controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                observer.send(error: .cancel)
            }))

            disposable += ActionDisposable {
                controller.dismiss(animated: true, completion: nil)
            }

            self?.present(controller, animated: true, completion: nil)
        }

        let alertProducer = alert.map({ _ in RLYKnownHardwareVersion?.none }).skipNil()
            .take(untilReplacement: readHardwareProducer)
            .take(first: 1)
            .timeout(
                after: 10,
                raising: .error(NSError(domain: "Timeout", code: 0, userInfo: nil)),
                on: QueueScheduler.main
            )

        alertProducer.startWithResult({ [weak self] result in
            switch result
            {
            case let .success(version):
                self?.presentTests(peripheral: peripheral, knownHardwareVersion: version)
            case let .failure(loaderError):
                if case let .error(error) = loaderError
                {
                    let controller = UIAlertController(
                        title: error.localizedDescription,
                        message: error.localizedFailureReason,
                        preferredStyle: .alert
                    )

                    controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

                    self?.present(controller, animated: true, completion: nil)
                }
            }
        })
    }

}

extension SelectPeripheralViewController: UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return peripherals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let identifier = "cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: identifier)

        cell.textLabel?.text = RLYPeripheralStyleName(peripherals[indexPath.row].style) ?? "Ringly"
        cell.detailTextLabel?.text = peripherals[indexPath.row].name

        return cell
    }
}

extension SelectPeripheralViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let peripheral = peripherals[indexPath.row]

        if let knownVersion = peripheral.knownHardwareVersion?.value
        {
            presentTests(peripheral: peripheral, knownHardwareVersion: knownVersion)
        }
        else
        {
            discoverVersionAndPresentTests(peripheral: peripheral)
        }
    }
}
