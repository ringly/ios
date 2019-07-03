#if DEBUG || FUTURE

import ReactiveSwift
import UIKit

final class DeveloperCharacteristicsViewController: DeveloperTableViewController
{
    let peripheral = MutableProperty(RLYPeripheral?.none)
    let service = MutableProperty(CBService?.none)

    override func viewDidLoad()
    {
        super.viewDidLoad()

        service.producer.startWithValues({ [weak self] in
            self?.title = ($0?.uuid).map(RLYPeripheral.descriptionForService) ?? $0?.uuid.uuidString
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
        return service.value?.characteristics?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = subtitleCell()

        if let characteristic = service.value?.characteristics?[indexPath.row]
        {
            cell.textLabel?.text = characteristic.uuid.uuidString
            cell.detailTextLabel?.text = RLYPeripheral.descriptionForCharacteristic(with: characteristic.uuid)
        }

        return cell
    }

    // MARK: - Table View Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let write = DeveloperWriteViewController(
            services: services,
            peripheral: peripheral.value!,
            characteristic: service.value!.characteristics![indexPath.item]
        )

        present(UINavigationController(rootViewController: write), animated: true, completion: nil)
    }
}

#endif
