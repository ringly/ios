#if DEBUG || FUTURE

import UIKit

class DeveloperTableViewController: ServicesViewController
{
    let tableView = UITableView.newAutoLayout()

    override func loadView()
    {
        tableView.dataSource = self
        tableView.delegate = self
        self.view = tableView
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        tableView.indexPathsForSelectedRows?.forEach({ tableView.deselectRow(at: $0, animated: animated) })
    }

    func subtitleCell() -> UITableViewCell
    {
        let identifier = "cell"
        return tableView.dequeueReusableCell(withIdentifier: identifier)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
    }

    func dismissAction(_ sender: AnyObject?)
    {
        dismiss(animated: true, completion: nil)
    }
}

extension DeveloperTableViewController: UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { fatalError() }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        fatalError()
    }
}

extension DeveloperTableViewController: UITableViewDelegate {}

#endif
