import RinglyDFU
import RinglyExtensions
import ReactiveSwift
import Result
import RinglyAPI
import UIKit

#if DEBUG || FUTURE

/// Presents an interface for creating DFU packages.
final class DFUPackageBuilderViewController: ServicesViewController, UITableViewDataSource, UITableViewDelegate
{
    // MARK: - Input
    let peripheral = MutableProperty(RLYPeripheral?.none)

    // MARK: - Completion
    
    /// Called when the user confirms a firmware result.
    var completed: ((DFUPackageBuilderViewController, FirmwareResult) -> ())?
    
    /// Called when the user cancels the view controller.
    var cancelled: ((DFUPackageBuilderViewController) -> ())?
     
    // MARK: - Data
    
    /// The currently selected firmwares.
    private let firmwares = MutableProperty<FirmwareResult?>(nil)
    
    /**
     Returns the firmware array for the specified section.
     
     - parameter section: The section.
     */
    private func arrayForSection(_ section: Int) -> [Firmware]?
    {
        switch section
        {
        case 0:
            return firmwares.value?.applications
        case 1:
            return firmwares.value?.bootloaders
        default:
            return nil
        }
    }
    
    /// Returns the current firmware values for the selected rows.
    private var firmwareForSelectedRows: [Firmware]
    {
        return tableView.indexPathsForSelectedRows?.reduce([], { firmware, indexPath -> [Firmware] in
            if let array = arrayForSection(indexPath.section)
            {
                return firmware + [array[indexPath.row]]
            }
            else
            {
                return firmware
            }
        }) ?? []
    }
     
    // MARK: - View
    private let tableView = UITableView(frame: .zero, style: .grouped)
     
    override func loadView()
    {
        let view = UIView()
         
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsMultipleSelection = true
         
        view.addSubview(tableView)
        tableView.autoPinEdgesToSuperviewEdges()
         
        self.view = view
    }
     
    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
         
        title = "Packages"
        
        let cancelItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(DFUPackageBuilderViewController.cancelAction))
        navigationItem.leftBarButtonItem = cancelItem
         
        let doneItem = UIBarButtonItem(title: "DFU", style: .plain, target: self, action: #selector(DFUPackageBuilderViewController.DFUAction))
        navigationItem.rightBarButtonItem = doneItem
         
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        let api = services.api

        let hardwareVersion = peripheral.producer.flatMapOptionalFlat(.latest, transform: { peripheral in
            peripheral.reactive.hardwareVersion
        }).skipRepeats(==)

        firmwares <~ hardwareVersion
            .flatMapOptional(.latest, transform: { hardware -> SignalProducer<FirmwareResult, NoError> in
                api.resultProducer(for: FirmwareRequest.all(hardware: hardware))
                    .flatMapError({ [weak self] error in
                        self?.presentErrorProducer(error).ignoreValues(FirmwareResult.self) ?? SignalProducer.empty
                    })
            })

        tableView.reactive.reloadData <~ firmwares.producer.skip(first: 1).void
    }
     
    // MARK: - Actions
    @objc private func DFUAction()
    {
        let firmware = firmwareForSelectedRows
        
        completed?(self, FirmwareResult(
            applications: firmware.filter({ $0.type == .application }),
            bootloaders: firmware.filter({ $0.type == .bootloader })
        ))
    }
    
    @objc private func cancelAction()
    {
        cancelled?(self)
    }
     
    // MARK: - Table View Data Source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 2
    }
     
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return arrayForSection(section)?.count ?? 0
    }
     
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
         
        if let array = arrayForSection(indexPath.section)
        {
            cell.textLabel?.text = array[indexPath.row].version
        }
         
        return cell
    }
     
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        switch section
        {
        case 0:
            return "Application"
        case 1:
            return "Bootloader"
        default:
            return "Unknown"
        }
    }
     
    // MARK: - Table View Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if let paths = self.tableView.indexPathsForSelectedRows
        {
            for path in paths
            {
                if path.section == indexPath.section && path.row != indexPath.row
                {
                    tableView.deselectRow(at: path, animated: false)
                }
            }
        }
    }
}

#endif
