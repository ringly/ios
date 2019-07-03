#if DEBUG || FUTURE

import ReactiveSwift
import RinglyDFU
import UIKit

final class DeveloperPeripheralsViewController: DeveloperTableViewController
{
    // MARK: - Peripherals
    private let peripherals = MutableProperty<[RLYPeripheral]>([])

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        peripherals <~ services.peripherals.peripherals.producer.observe(on: UIScheduler())
        peripherals.producer.startWithValues({ [weak tableView] _ in tableView?.reloadData() })
    }

    // MARK: - Table View Data Source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return peripherals.value.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = subtitleCell()
        let peripheral = peripherals.value[indexPath.row]
        cell.textLabel?.text = peripheral.name

        if let label = cell.detailTextLabel
        {
            label.reactive.text <~ peripheral.reactive.state
                .map({ $0.logDescription })
                .take(until: cell.reactive.prepareForReuse)
        }

        return cell
    }

    // MARK: - Table View Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let controller = DeveloperServicesViewController(services: services)
        controller.peripheral.value = peripherals.value[indexPath.row]
        present(UINavigationController(rootViewController: controller), animated: true, completion: nil)
    }
}

#endif
