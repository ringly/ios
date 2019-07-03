import Contacts
import MessageUI
import PureLayout
import ReactiveSwift
import RealmSwift
import Result
import RinglyExtensions
import RinglyActivityTracking
import UIKit
import enum Result.NoError


final class NotificationAlertsViewController: ConfigurationsViewController
{
    fileprivate let results = MutableProperty(Results(pinned: [], unpinned: []))

    struct Results {
        let pinned : [NotificationAlert]
        let unpinned : [NotificationAlert]
    }
    
    // View Loading
    fileprivate let measurementCell = NotificationConfigurationCell()
    
    // Whether or not the notifications are being edited.
    fileprivate let editingProperty = MutableProperty(false)
    
    // A producer for the view controller's current editing state.
    var editingProducer: SignalProducer<Bool, NoError>
    {
        return editingProperty.producer
    }
    
    // Load background view for the notifications page
    override func loadView()
    {
        super.loadView()
        
        tableView.backgroundView = GradientView.pinkGradientView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor(white: 0.8, alpha: 1.0)
        tableView.separatorInset = .zero
        
        navigationBar.backgroundColor = .clear
        navigationBar.title.value = .text(trUpper(.notifications))
        
        navigationBar.action.value = .image(image: UIImage(asset: .preferencesActivityMinus), accessibilityLabel: "Delete All")
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // register cell classes
        tableView.registerCellType(NotificationConfigurationCell.self)
        
        // table view
        tableView.dataSource = self
        tableView.delegate = self
        
        // edit button
        editingProperty.producer.startWithValues({ [weak tableView] in tableView?.allowsSelection = $0 })
        editingProducer.producer.start(
            animationDuration: 0.25,
            action: { [weak navigationBar] in
                navigationBar?.actionButtonTransform = $0
                    ? CGAffineTransform(rotationAngle: CGFloat(M_PI_4))
                    : .identity
            }
        )
        
        // bind notifications
        results <~ services.notifications.configuration
            .realmResultsProducer(makeResults: { realm -> RealmSwift.Results<NotificationAlert> in
                realm.objects(NotificationAlert.self).sorted(byKeyPath: "date", ascending: false)
            })
            .map({ results in
                let arePinned = Array(results.filter({$0.pinned}))
                let areUnpinned = Array(results.filter({!$0.pinned}))
                return Results(pinned: arePinned, unpinned: areUnpinned)
            })
            .flatMapError({ _ in SignalProducer.empty })
        
        results.producer.startWithValues({ [weak self] _ in self?.tableView.reloadData() })

        actionProducer.startWithValues({ [weak self] _ in self?.deleteNotificationAction() })
    }

    @objc private func deleteNotificationAction()
    {
        services.notifications.clearLog()
        self.loadView()
    }

    fileprivate weak var deletingNotificationCell: NotificationConfigurationCell?
    
    // Transition Override
    override func containerViewController(
        containerViewController: ContainerViewController,
        animationControllerForTransitionFromViewController fromViewController: UIViewController?,
                                                           toViewController: UIViewController?)
        -> UIViewControllerAnimatedTransitioning?
    {
        // don't show a transition when moving away from onboarding, we already have a modal transition
        return toViewController != nil
            ? super.containerViewController(
                containerViewController: containerViewController,
                animationControllerForTransitionFromViewController: fromViewController,
                toViewController: toViewController
                )
            : nil
    }
}
    
extension NotificationAlertsViewController: UITableViewDataSource
{
    fileprivate enum Section: Int
    {
        case Pinned = 0
        case Notifications = 1
        case Invalid = 2
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        switch Section(rawValue: section) ?? .Invalid
        {
        case .Pinned:
            return results.value.pinned.count
        case .Notifications:
            return results.value.unpinned.count
        case .Invalid:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueCellOfType(NotificationConfigurationCell.self, forIndexPath: indexPath)

        cell.properties.value = getCellProperty(indexPath: indexPath)
        cell.delegate = self

        // ensure we only have one "deleting" cell at a time
        cell.deleting.producer
            .skip(first: 1)
            .skipRepeats(==)
            .take(until: cell.reactive.prepareForReuse)
            .startWithValues({ [weak self, weak cell] deleting in
                if deleting {
                    if let otherCell = self?.deletingNotificationCell {
                        UIView.animate(withDuration: 0.25, animations: {
                            otherCell.deleting.value = false
                            otherCell.layoutIfNeeded()
                        })
                    }
                    self?.deletingNotificationCell = cell
                } else {
                    if self?.deletingNotificationCell == cell && cell != nil
                    {
                        self?.deletingNotificationCell = nil
                    }
                }
            })
        return cell
    }
}
    
    
extension NotificationAlertsViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        
        let headerLabel = UILabel()
        headerLabel.font = UIFont.gothamBook(16)
        headerLabel.textColor = UIColor.white
        headerLabel.backgroundColor = UIColor.ringlyPurple.withAlphaComponent(0.4) //.clear
        headerLabel.textAlignment = .left
        headerLabel.translatesAutoresizingMaskIntoConstraints = false

        switch Section(rawValue: section) ?? .Invalid
        {
        case .Pinned:
            headerLabel.text = "  PINNED NOTIFICATIONS"
        case .Notifications:
            headerLabel.text = "  UNPINNED NOTIFICATIONS"
        case .Invalid:
            headerLabel.text = ""
        }
        
        view.addSubview(headerLabel)
        headerLabel.autoPinEdgesToSuperviewEdges()

        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        guard tableView.bounds.size.width > 0 else { return 0 }
        measurementCell.properties.value = getCellProperty(indexPath: indexPath)
        return measurementCell.sizeThatFits(CGSize(width: tableView.bounds.size.width, height: .greatestFiniteMagnitude)).height
    }
    
    fileprivate func getCellProperty(indexPath: IndexPath) -> NotificationConfigurationCell.Properties {
        if indexPath.section == 0
        {
            return NotificationConfigurationCell.Properties(notificationAlert: results.value.pinned[indexPath.row], applications: services.applications, contacts: CNContactStore())
        }
        else
        {
            return NotificationConfigurationCell.Properties(notificationAlert: results.value.unpinned[indexPath.row], applications: services.applications, contacts: CNContactStore())
        }
    }
}
    
extension NotificationAlertsViewController: NotificationConfigurationCellDelegate
{
    func notificationConfigurationDeleteCell(cell: NotificationConfigurationCell)
    {
        suspendReloadTableViewFor {
            NotificationAlertService.sharedNotificationService.removeEntry(notification: (cell.properties.value?.notificationAlert)!)
        }
    }
}


