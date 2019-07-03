#if DEBUG || FUTURE

import ReactiveSwift
import UIKit

final class DeveloperTabBarViewController: ServicesViewController
{
    // MARK: - Subviews
    private let tabBarView = TabBarView<DeveloperNavigationItem>.newAutoLayout()
    private let container = ContainerViewController()

    override func loadView()
    {
        let view = UIStackView()
        view.axis = .vertical
        view.distribution = .fill
        view.alignment = .fill
        self.view = view

        tabBarView.backgroundColor = .tabBarBackgroundColor
        view.addArrangedSubview(tabBarView)
        tabBarView.autoSet(dimension: .height, to: 65)

        addChildViewController(container)
        view.addArrangedSubview(container.view)
        container.didMove(toParentViewController: self)
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        // fill out tab bar content
        tabBarView.items.value = [.Actions, .Logs, .Peripherals, .NotificationAlert]
        tabBarView.selectedItem.value = .Actions

        // bind content view controller to selected navigation item
        container.childViewController <~ tabBarView.selectedItem.producer
            .skipRepeats(==)
            .mapOptional({ item -> ServicesViewController.Type in
                switch item
                {
                case .Actions:
                    return DeveloperViewController.self
                case .Logs:
                    return LogsViewController.self
                case .Peripherals:
                    return DeveloperPeripheralsViewController.self
                case .NotificationAlert:
                    return NotificationAlertsViewController.self
                }
            })
            .mapOptionalFlat({ [weak self] viewControllerType in
                guard let services = self?.services else { return nil }
                return viewControllerType.init(services: services)
            })
    }
}

private enum DeveloperNavigationItem
{
    case Actions
    case Logs
    case Peripherals
    case NotificationAlert
}

extension DeveloperNavigationItem: TabBarViewItem
{
    var title: String
    {
        switch self
        {
        case .Actions: return "Actions"
        case .Logs: return "Logs"
        case .Peripherals: return "Peripherals"
        case .NotificationAlert: return "NotificationAlert"
        }
    }

    var image: UIImage?
    {
        switch self
        {
        case .Actions: return UIImage(asset: .tabConnect)
        case .Logs: return UIImage(asset: .tabAlerts)
        case .Peripherals: return UIImage(asset: .tabAlerts)
        case .NotificationAlert: return UIImage(asset: .tabContacts)
        }
    }
}
#else
// stub to prevent compiler errors
final class DeveloperTabBarViewController: ServicesViewController {}
#endif
