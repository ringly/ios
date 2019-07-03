#if DEBUG || FUTURE

import UIKit

final class RemoveAppsViewController: ServicesViewController
{
    private let tableView = UITableView.newAutoLayout()

    override func loadView()
    {
        let view = UIView()
        self.view = view

        tableView.allowsMultipleSelection = true
        tableView.dataSource = self
        view.addSubview(tableView)
        tableView.autoPinEdgesToSuperviewEdges()
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        title = "Remove Apps"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(RemoveAppsViewController.cancel)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .trash,
            target: self,
            action: #selector(RemoveAppsViewController.removeAndCrash)
        )
    }

    @objc private func cancel()
    {
        dismiss(animated: true, completion: nil)
    }

    @objc private func removeAndCrash()
    {
        guard let indexPaths = tableView.indexPathsForSelectedRows else { return }

        // disallow repeated taps
        navigationItem.leftBarButtonItem?.isEnabled = false
        navigationItem.rightBarButtonItem?.isEnabled = false
        view.isUserInteractionEnabled = false

        // remove selected configurations
        indexPaths.map({ services.applications.configurations.value[$0.row] })
            .forEach(services.applications.removeConfiguration)

        // kill the app after waiting for configurations to be written
        RLYDispatchAfterMain(4, { kill(getpid(), SIGKILL) })
    }
}

extension RemoveAppsViewController: UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return services.applications.configurations.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "identifier")
            ?? UITableViewCell(style: .default, reuseIdentifier: "identifier")

        cell.textLabel?.text = services.applications.configurations.value[indexPath.row].application.name

        return cell
    }
}

#endif
