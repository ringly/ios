import ReactiveSwift
import UIKit
import enum Result.NoError

class ConfigurationsViewController: ServicesViewController
{
    // MARK: - Constants

    /// The row-height of the table view.
    @nonobjc static let rowHeight: CGFloat = 84

    /// The bottom edge inset for configurations onboarding view controllers.
    @nonobjc static let onboardingBottomPadding: CGFloat = 30

    // MARK: - Onboarding View Controller

    /// The view controller to display as an onboarding overlay.
    let onboardingViewController = MutableProperty(UIViewController?.none)

    /// The container view controller displaying the onboarding view controller.
    fileprivate let onboardingContainer = ContainerViewController()

    /// If `true`, animated transitions will be used to display or hide the onboarding view controller.
    fileprivate var allowOnboardingTransition = false

    // MARK: - Subviews

    /// The view controller's navigation bar, displayed above `tableView`.
    let navigationBar = NavigationBar.newAutoLayout()

    /// The table view in which configuration cells are displayed. Implementation is left to subclasses.
    let tableView = UITableView(frame: .zero, style: .plain)

    /// A view containing the table view, allowing it to be masked.
    fileprivate let tableContentView = UIView.newAutoLayout()

    // MARK: - View Loading
    override func loadView()
    {
        let view = GradientView()
        view.startPoint = .zero
        view.endPoint = CGPoint(x: 1, y: 1)
        view.setGradient(
            startColor: UIColor(white: 0.33, alpha: 1),
            endColor: UIColor(white: 0.4, alpha: 1)
        )

        self.view = view

        // add table content view, below onboarding
        view.addSubview(tableContentView)
        tableContentView.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.zero, excluding: .top)

        // add table view to table content view
        tableView.backgroundColor = .clear
        tableView.indicatorStyle = .white
        tableView.separatorStyle = .none
        tableView.rowHeight = ConfigurationsViewController.rowHeight
        tableContentView.addSubview(tableView)
        tableView.autoPinEdgesToSuperviewEdges()

        // add onboarding container above table content view
        onboardingContainer.childTransitioningDelegate = self
        onboardingContainer.addAsEdgePinnedChild(of: self, in: view)

        // add navigation bar, above onboarding container
        navigationBar.action.value = .image(image: UIImage(asset: .addButtonLarge), accessibilityLabel: "Add")
        view.addSubview(navigationBar)
        navigationBar.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.zero, excluding: .bottom)
        navigationBar.autoSet(dimension: .height, to: NavigationBar.standardHeight)
        tableContentView.autoPin(edge: .top, to: .bottom, of: navigationBar)
    }

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        onboardingContainer.childViewController <~ onboardingViewController

        // disable overlay controller when there is no child view controller
        onboardingContainer.childViewController.producer
            .map({ $0 != nil })
            .skipRepeats()
            .startWithValues({ [weak self] showingOnboarding in
                self?.onboardingContainer.view.isUserInteractionEnabled = showingOnboarding
                self?.tableView.isUserInteractionEnabled = !showingOnboarding
                self?.tableView.accessibilityElementsHidden = !showingOnboarding

                if self?.view.window != nil
                {
                    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self?.view)
                }
            })
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        allowOnboardingTransition = true
    }

    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        allowOnboardingTransition = false
    }

    // MARK: - Reloading Table View
    fileprivate var reloadedSuspended = false

    /// Reloads the table view, iff not within a `suspendReloadTableViewFor` block.
    func reloadTableView()
    {
        if !reloadedSuspended
        {
            tableView.reloadData()
        }
    }

    /**
     Suspends `reloadTableView` while executing a block of code.

     - parameter function: The function to execute.
     */
    func suspendReloadTableViewFor(_ function: () -> ())
    {
        reloadedSuspended = true
        function()
        reloadedSuspended = false
    }

    // MARK: - Displaying Demo Notifications

    /**
     Displays a demo notification on the activated peripheral.

     - parameter notification: The notification to display.
     */
    func display(demo notification: PeripheralNotification)
    {
        services.peripherals.activatedPeripheral.value?.writeNotification(notification)
    }

    // MARK: - Actions
    enum Action { case onboarding, navigation }

    var actionProducer: SignalProducer<Action, NoError>
    {
        return SignalProducer.merge(
            onboardingViewController.producer
                .delay(0.01, on: QueueScheduler.main) // prevents re-entrant producer
                .map({ $0 as? ConfigurationsOnboardingConfirmation })
                .flatMapOptional(.latest, transform: { $0.actionProducer })
                .skipNil()
                .map({ _ in .onboarding }),
            navigationBar.actionProducer.map({ _ in .navigation })
        )
    }
}

extension ConfigurationsViewController: ContainerViewControllerTransitioningDelegate
{
    func containerViewController(containerViewController: ContainerViewController,
                                 animationControllerForTransitionFromViewController fromViewController: UIViewController?,
                                 toViewController: UIViewController?)
        -> UIViewControllerAnimatedTransitioning?
    {
        return allowOnboardingTransition ? ConfigurationsOnboardingTransition() : nil
    }
}

extension ConfigurationsViewController: TabBarViewControllerTappedSelectedListener
{
    func tabBarViewControllerDidTapSelectedItem()
    {
        tableView.setContentOffset(.zero, animated: true)
    }
}

protocol ConfigurationsOnboardingConfirmation
{
    var actionProducer: SignalProducer<(), NoError> { get }
}
