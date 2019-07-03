#if DEBUG || FUTURE

import MessageUI
import ReactiveSwift
import RealmSwift
import RinglyActivityTracking
import UIKit
import enum Result.NoError

final class LogsViewController: ServicesViewController
{
    // MARK: - View Loading
    fileprivate let measurementCell = LogMessageCell()
    private let tableView = UITableView.newAutoLayout()
    private let toolbar = UIToolbar.newAutoLayout()

    override func loadView()
    {
        let view = UIView()
        self.view = view

        tableView.registerCellType(LogMessageCell.self)
        tableView.allowsSelection = false
        tableView.estimatedRowHeight = 44
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.autoPinEdgesToSuperviewEdges(excluding: .bottom)

        view.addSubview(toolbar)
        toolbar.autoPin(edge: .top, to: .bottom, of: tableView)
        toolbar.autoPinEdgesToSuperviewEdges(excluding: .top)
        toolbar.autoSet(dimension: .height, to: 44)
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        // add toolbar items
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(
                title: "Filter",
                style: .plain,
                target: self,
                action: #selector(LogsViewController.filterAction)
            ),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(
                barButtonSystemItem: .action,
                target: self,
                action: #selector(LogsViewController.shareAction)
            ),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        ]

        let configuration = services.logging!.configuration

        let predicateProducer = logTypes.producer.map({ types -> NSPredicate? in
            var predicates: [NSPredicate] = []

            RLogEnumerateTypes({ type in
                if types.contains(type)
                {
                    predicates.append(NSPredicate(format: "_type == %d", type.rawValue))
                }
            })

            return predicates.count > 0
                ? NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
                : nil
        })

        predicateProducer
            .flatMap(.latest, transform: { optionalPredicate in
                return configuration.realmResultsProducer { realm -> Results<LoggingMessage> in
                    let sorted = realm.objects(LoggingMessage.self).sorted(byKeyPath: "date", ascending: false)
                    return optionalPredicate.map({ sorted.filter($0) }) ?? sorted
                }.resultify()
            })
            .take(until: reactive.lifetime.ended)
            .startWithValues({ [weak self] result in
                switch result
                {
                case let .success(results):
                    self?.results.value = Array(results)
                    self?.tableView.reloadData()

                case let .failure(error):
                    print("Log fetch error", error)
                    self?.results.value = nil
                    self?.tableView.reloadData()
                }
            })

        logTypes.producer.skip(first: 1).startWithValues({
            UserDefaults.standard.set($0.rawValue, forKey: RLogTypeDefaultsKey)
        })
    }

    private let logTypes = MutableProperty(
        (UserDefaults.standard.object(forKey: RLogTypeDefaultsKey) as? Int)
            .flatMap(RLogType.init) ?? RLogType.all
    )

    fileprivate let results = MutableProperty([LoggingMessage]?.none)

    // MARK: - Toolbar Actions
    @objc private func filterAction()
    {
        let controller = LogTypesViewController()
        controller.selectedLogTypes = logTypes.value
        controller.completion = { [weak self] done in
            self?.logTypes.value = done.selectedLogTypes
            done.parent?.dismiss(animated: true, completion: nil)
        }

        let navigation = UINavigationController(rootViewController: controller)
        present(navigation, animated: true, completion: nil)
    }

    @objc private func shareAction()
    {
        guard MFMailComposeViewController.canSendMail() else {
            presentAlert(title: "No Mail account", message: "Configure an Apple Mail account to send logs")
            return
        }

        guard let logging = services.logging else {
            presentAlert(title: "Missing Logging", message: "No logging service")
            return
        }

        let alert = AlertViewController()
        alert.content = AlertActivityContent(text: "Collecting Logs", activityIndicatorType: .ui)
        alert.present(above: self)

        logging.csvProducer.observe(on: UIScheduler()).startWithResult({ [weak self] result in
            alert.dismiss()

            switch result
            {
            case let .success(csv):
                let mail = MFMailComposeViewController()
                mail.mailComposeDelegate = self
                mail.setSubject("Ringly iOS Logs")

                let bundle = Bundle.main
                mail.setMessageBody(
                    "Using version \(bundle.shortVersion ?? ""), build \(bundle.version ?? "").",
                    isHTML: false
                )

                mail.addAttachmentData(
                    csv.data(using: String.Encoding.utf8) ?? Data(),
                    mimeType: "text/csv",
                    fileName: "log-\(Date()).csv"
                )

                self?.present(mail, animated: true, completion: nil)

            case let .failure(error):
                self?.presentError(error)
            }
        })
    }
}

extension LogsViewController: MFMailComposeViewControllerDelegate
{
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?)
    {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension LogsViewController: UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return results.value?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueCellOfType(LogMessageCell.self, forIndexPath: indexPath)
        cell.message = results.value?[safe: indexPath.row]
        return cell
    }
}

extension LogsViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        guard tableView.bounds.size.width > 0 else { return 0 }
        measurementCell.message = results.value?[safe: indexPath.row]
        return measurementCell.sizeThatFits(CGSize(width: tableView.bounds.size.width, height: .greatestFiniteMagnitude)).height
    }
}

private let RLogTypeDefaultsKey = "LogsViewControllerRLogType"

extension RLogType
{
    static var all: RLogType
    {
        var types: RLogType = []
        RLogEnumerateTypes({ types.insert($0) })
        return types
    }
}

#endif
