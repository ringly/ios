import PureLayout
import ReactiveSwift
import UIKit
import enum Result.NoError

final class TabBarViewController: ServicesViewController
{
    // MARK: - Primary Content

    /// The currently displayed content view controller, if any.
    fileprivate(set) var contentViewController: UIViewController?
    {
        didSet
        {
            if let old = oldValue
            {
                old.willMove(toParentViewController: nil)
                old.view.removeFromSuperview()
                old.removeFromParentViewController()
            }

            if let new = contentViewController
            {
                addChildViewController(new)
                view.insertSubview(new.view, at: 0)
                self.contentViewHeightConstraints = new.view.autoPinEdgesToSuperviewEdges(
                    insets: self.tabBarHeightInsets
                ) as NSArray?
                new.didMove(toParentViewController: self)
            }

            contentViewControllerProperty.value = contentViewController
        }
    }

    fileprivate let contentViewControllerProperty = MutableProperty(UIViewController?.none)

    // MARK: - Tab Bar Item

    /// The current selected tab bar item.
    var selectedTabBarItem: TabBarViewControllerItem?
    {
        get { return tabBarView.selectedItem.value }
        set { tabBarView.selectedItem.value = newValue }
    }

    /// The default "via" analytics value.
    var defaultVia: SwitchedMainViewEvent.Via?

    // MARK: - Tab Bar Content

    /// The container for tab bar content.
    fileprivate let tabBarContainer = UIView.newAutoLayout()

    /// The tab bar view.
    fileprivate let tabBarView = TabBarView<TabBarViewControllerItem>.newAutoLayout()

    /// The height of the tab bar.
    static let tabBarHeight: CGFloat = 65
    
    /// The height constraint of the tab bar.
    var tabBarHeightInsets = UIEdgeInsetsMake(0, 0, 65, 0)
    var tabBarHeightConstraints: NSLayoutConstraint?
    var contentViewHeightConstraints: NSArray?
    

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        // add tab bar container
        tabBarContainer.backgroundColor = .tabBarBackgroundColor
        view.addSubview(tabBarContainer)
        tabBarContainer.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.zero, excluding: .top)

        // add tab bar to tab bar container
        tabBarContainer.addSubview(tabBarView)
        tabBarView.autoSet(dimension: .height, to: TabBarViewController.tabBarHeight)
        tabBarView.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.zero, excluding: .top)
        tabBarView.autoPinEdgeToSuperview(edge: .top, inset: 0, relation: .greaterThanOrEqual)
        
    }

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // fill out tab bar content
        let defaultTabBarViewItems: [TabBarViewControllerItem] =
            [.activity, .notifications, .contacts, .connection, .preferences]

        #if DEBUG || FUTURE
            tabBarView.items <~ services.preferences.developerModeEnabled.producer.map({ enabled in
                enabled
                    ? (defaultTabBarViewItems + [.developer])
                    : defaultTabBarViewItems
            })
        #else
            tabBarView.items.value = defaultTabBarViewItems
        #endif

        if tabBarView.selectedItem.value == nil
        {
            tabBarView.selectedItem.value = .connection
        }

        // bind content view controller to selected navigation item
        tabBarView.selectedItem.producer
            .skipRepeats(==)
            .mapOptionalFlat({ [weak self] item -> UIViewController? in
                guard let services = self?.services else { return nil }
                return item.viewControllerWithServices(services)
            })
            .startWithValues({ [weak self] in self?.contentViewController = $0 })

        // listen for foreground notification and send tracking event for current tab
        SignalProducer(NotificationCenter.default.reactive
            .notifications(forName: Notification.Name.UIApplicationWillEnterForeground, object: UIApplication.shared))
            .take(first: 1)
            .startWithValues({ [weak self] _ in
                if let selectedItem = self?.tabBarView.selectedItem.value {
                    let event = SwitchedMainViewEvent(to: selectedItem, from: nil, via: .foreground)
                    self?.services.analytics.track(event)
                }
            })
        
        // track tab switches
        tabBarView.selectedItem.producer
            .filter({ $0 != nil })
            .combinePrevious(nil)
            .map({ [weak self] previous, current in
                current.map({
                    SwitchedMainViewEvent(to: $0, from: previous, via: previous != nil ? .tabs : self?.defaultVia)
                })
            })
            .skipNil()
            .startWithValues({ [weak self] in self?.services.analytics.track($0) })

        // send tapped-selected events to child view controller
        tabBarView.tappedSelectedItemSignal.observeValues({ [weak self] _ in
            (self?.contentViewController as? TabBarViewControllerTappedSelectedListener)?
                .tabBarViewControllerDidTapSelectedItem()
        })

        // offset tab bar when appropriate
        contentViewControllerProperty.producer
            .map({ $0 as? TabBarViewControllerOffsetting })
            .flatMapOptional(.latest, transform: { $0.tabBarOffsettingProducer })
            .map({ $0 ?? false })
            .skipRepeats()
            .startWithValues({ [weak self] offset in
                if let strongSelf = self {
                    switch offset
                    {
                    case true:
                        strongSelf.tabBarContainer.isHidden = true
                        strongSelf.contentViewHeightConstraints?.autoRemoveConstraints()
                        strongSelf.contentViewHeightConstraints = strongSelf.contentViewController?.view.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.zero) as NSArray?
                    case false:
                        strongSelf.tabBarContainer.isHidden = false
                        strongSelf.contentViewHeightConstraints?.autoRemoveConstraints()
                        strongSelf.contentViewHeightConstraints = strongSelf.contentViewController?.view.autoPinEdgesToSuperviewEdges(insets: strongSelf.tabBarHeightInsets) as NSArray?
                    }
                }
//                self?.tabBarContainer.transform = CGAffineTransform(translationX: 0, y: offset)
            })
    }

    // MARK: - Status Bar
    override var prefersStatusBarHidden : Bool
    {
        return true
    }
}

// MARK: - Selected Tabs
protocol TabBarViewControllerTappedSelectedListener
{
    func tabBarViewControllerDidTapSelectedItem()
}

/// A protocol for types that can offset the tab bar vertically.
protocol TabBarViewControllerOffsetting
{
    /// A producer for the current tab bar offset.
    var tabBarOffsettingProducer: SignalProducer<Bool, NoError> { get }
}

// MARK: - Tab Bar Items
enum TabBarViewControllerItem: String
{
    case connection
    case notifications
    case contacts
    case activity
    case preferences
    case developer
}

extension TabBarViewControllerItem
{
    fileprivate func viewControllerWithServices(_ services: Services) -> UIViewController
    {
        switch self
        {
        case .connection:
            return ConnectViewController(services: services)
        case .notifications:
            return ApplicationsViewController(services: services)
        case .contacts:
            return ContactsViewController(services: services)
        case .activity:
            return ActivityTrackingViewController(services: services)
        case .preferences:
            return PreferencesViewController(services: services)
        case .developer:
            return DeveloperTabBarViewController(services: services)
        }
    }
}

extension TabBarViewControllerItem: TabBarViewItem
{
    var title: String
    {
        switch self
        {
        case .connection: return tr(.tabBarConnect)
        case .notifications: return tr(.tabBarAlerts)
        case .contacts: return tr(.tabBarContacts)
        case .activity: return tr(.tabBarActivity)
        case .preferences: return tr(.tabBarSettings)
        case .developer: return "Developer"
        }
    }

    var image: UIImage?
    {
        switch self
        {
        case .connection: return UIImage(asset: .tabConnect)
        case .notifications: return UIImage(asset: .tabAlerts)
        case .contacts: return UIImage(asset: .tabContacts)
        case .activity: return UIImage(asset: .tabActivityTracking)
        case .preferences: return UIImage(asset: .tabPreferences)
        case .developer: return UIImage(asset: .tabPreferences)
        }
    }
}

// MARK: - Analytics
struct SwitchedMainViewEvent
{
    // MARK: - Items
    let to: TabBarViewControllerItem
    let from: TabBarViewControllerItem?

    // MARK: - Via
    enum Via: String, AnalyticsPropertyValueType
    {
        case tabs = "Tabs"
        case launch = "Launch"
        case onboarding = "Onboarding"
        case login = "Login"
        case foreground = "Foreground"
    }

    let via: Via?
}

extension SwitchedMainViewEvent: AnalyticsEventType
{
    var name: String { return "Switched Main View" }

    var properties: [String : AnalyticsPropertyValueType]
    {
        var properties: [String: AnalyticsPropertyValueType] = ["To": to]
        properties["From"] = from
        properties["Via"] = via
        return properties
    }
}

extension TabBarViewControllerItem: AnalyticsPropertyValueType
{
    var analyticsString: String
    {
        switch self
        {
        case .connection: return "Connect"
        case .notifications: return "Alerts"
        case .contacts: return "Contacts"
        case .activity: return "Activity"
        case .preferences: return "Settings"
        case .developer: return "Developer"
        }
    }
}
