#if DEBUG || FUTURE

import ReactiveSwift
import UIKit

final class DeveloperServicesViewController: DeveloperTableViewController
{
    let peripheral = MutableProperty(RLYPeripheral?.none)
    private let peripheralServices = MutableProperty<[CBService]>([])

    override func viewDidLoad()
    {
        super.viewDidLoad()

        peripheral.producer.startWithValues({ [weak self] in self?.title = $0?.name })

        peripheralServices <~ peripheral.producer.flatMapOptionalFlat(.latest, transform: { $0.reactive.ready })
            .map({ ($0?.value(forKey: "CBPeripheral") as? CBPeripheral)?.services ?? [] })
            .observe(on: UIScheduler())

        peripheralServices.producer.startWithValues({ [weak tableView] _ in
            tableView?.reloadData()
        })

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(DeveloperTableViewController.dismissAction(_:))
        )
    }

    // MARK: - Table View Data Source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return peripheralServices.value.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = subtitleCell()

        let service = peripheralServices.value[indexPath.row]
        cell.textLabel?.text = service.uuid.uuidString
        cell.detailTextLabel?.text = RLYPeripheral.descriptionForService(with: service.uuid)

        return cell
    }

    // MARK: - Table View Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let controller = DeveloperCharacteristicsViewController(services: services)
        controller.service.value = peripheralServices.value[indexPath.row]
        controller.peripheral.value = peripheral.value
        present(UINavigationController(rootViewController: controller), animated: true, completion: nil)
    }
}

#endif
