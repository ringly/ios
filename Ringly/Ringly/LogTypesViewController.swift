import ReactiveSwift
import UIKit

final class LogTypesViewController: UIViewController
{
    // MARK: - Log Types

    /// The log types that are currently selected.
    var selectedLogTypes: RLogType = []

    /// All log types, initialized in `viewDidLoad`.
    fileprivate var logTypes: [RLogType] = []

    // MARK: - View Loading
    fileprivate let tableView = UITableView.newAutoLayout()
    fileprivate let toolbar = UIToolbar.newAutoLayout()

    override func loadView()
    {
        let view = UIView()
        self.view = view

        tableView.registerCellType(UITableViewCell.self)
        tableView.allowsMultipleSelection = true
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.autoPinEdgesToSuperviewEdges(excluding: .bottom)

        view.addSubview(toolbar)
        toolbar.autoSet(dimension: .height, to: 44)
        toolbar.autoPin(edge: .top, to: .bottom, of: tableView)
        toolbar.autoPinEdgesToSuperviewEdges(excluding: .top)
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        // navigation bar setup
        title = "Filter Logs"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(LogTypesViewController.doneAction)
        )

        // toolbar actions
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(
                title: "All",
                style: .plain,
                target: self,
                action: #selector(LogTypesViewController.selectAllAction)
            ),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(
                title: "None",
                style: .plain,
                target: self,
                action: #selector(LogTypesViewController.selectNoneAction)
            ),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        ]

        // load the table view
        RLogEnumerateTypes({ self.logTypes.append($0) })
        tableView.reloadData()

        // select currently-selected rows
        logTypes.enumerated().forEach({ index, type in
            if selectedLogTypes.contains(type)
            {
                let path = IndexPath(row: index, section: 0)
                tableView.selectRow(at: path, animated: false, scrollPosition: .none)
            }
        })
    }

    // MARK: - Toolbar Actions
    @objc fileprivate func selectAllAction()
    {
        logTypes.enumerated().forEach({ index, type in
            selectedLogTypes.insert(type)

            let path = IndexPath(row: index, section: 0)
            tableView.selectRow(at: path, animated: true, scrollPosition: .none)
        })
    }

    @objc fileprivate func selectNoneAction()
    {
        logTypes.forEach({ selectedLogTypes.remove($0) })
        tableView.indexPathsForSelectedRows?.forEach({ tableView.deselectRow(at: $0, animated: true) })
    }

    // MARK: - Completion
    @objc fileprivate func doneAction()
    {
        completion?(self)
    }

    var completion: ((LogTypesViewController) -> ())?
}

extension LogTypesViewController: UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return logTypes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueCellOfType(UITableViewCell.self, forIndexPath: indexPath)
        cell.textLabel?.text = RLogTypeToString(logTypes[indexPath.row])
        return cell
    }
}

extension LogTypesViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        selectedLogTypes.insert(logTypes[indexPath.row])
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
    {
        selectedLogTypes.remove(logTypes[indexPath.row])
    }
}

extension RLogType: Hashable
{
    public var hashValue: Int { return rawValue }
}
