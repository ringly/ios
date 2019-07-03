import PureLayout
import ReactiveSwift
import RinglyExtensions
import UIKit
import enum Result.NoError

final class PeripheralsViewController: ServicesViewController
{
    // MARK: - Child View Controllers

    /// The navigation controller that displays settings pages.
    let navigation = UINavigationController()

    /// The container view controller at the root of the navigation heirarchy, displaying either a pages view
    /// controller of the current peripherals, or a `NoPeripheralsViewController`.
    fileprivate let root = ContainerViewController()

    /// The page view controller that displays peripheral view controllers.
    fileprivate let pages = UIPageViewController(
        transitionStyle: .scroll,
        navigationOrientation: .horizontal,
        options: nil
    )

    /// Whether or not the root view controller (`pages`) is being displayed by `navigation`.
    fileprivate let currentNavigationViewController = MutableProperty(UIViewController?.none)

    /// The types of view controller that can be displayd by `pages`.
    fileprivate typealias CurrentViewController = Either<PeripheralReferenceViewController, ReviewsViewController>

    /// The current view controller displayed by `pages`, if any.
    fileprivate let currentViewController = MutableProperty(CurrentViewController?.none)

    // MARK: - Page Indicator

    /// The page indicator displayed over `pages`.
    fileprivate let pageIndicator = PageIndicator.newAutoLayout()

    // MARK: - Navigation Bar

    /// The navigation bar displayed above `navigation`.
    fileprivate let navigationBar = NavigationBar.newAutoLayout()

    // MARK: - View Loading
    override func loadView()
    {
        super.loadView()

        // add title bar area
        view.addSubview(navigationBar)

        navigationBar.autoSet(dimension: .height, to: 75)
        navigationBar.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.zero, excluding: .bottom)

        // add child view controllers
        navigation.delegate = self
        navigation.isNavigationBarHidden = true

        addChildViewController(navigation)
        view.addSubview(navigation.view)
        navigation.view.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.zero, excluding: .top)
        navigation.view.autoPin(edge: .top, to: .bottom, of: navigationBar)
        navigation.didMove(toParentViewController: self)

        pages.dataSource = self
        pages.delegate = self
        navigation.pushViewController(root, animated: false)
        currentNavigationViewController.value = root

        // add page indicator
        view.addSubview(pageIndicator)
        pageIndicator.autoAlignAxis(toSuperviewAxis: .vertical)
        pageIndicator.autoPinEdgeToSuperview(edge: .bottom, inset: 30)
    }

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // non-associated-with-self references for use in closures
        let services = self.services

        // bind current root controller
        root.childViewController <~ services.peripherals.stateProducer
            .map({ [weak self] state in
                if state.references.count > 0
                {
                    return (self?.pages)!
                }
                else
                {
                    return NoPeripheralsViewController(services: services)
                }
            })

        // bind title label content
        navigationBar.title <~ currentNavigationViewController.producer
            .flatMapOptionalFlat(.latest, transform: { [weak root] (viewController: UIViewController) -> SignalProducer<NavigationBar.Title?, NoError> in
                if viewController == root
                {
                    return SignalProducer(value: NavigationBar.Title.image(
                        image: UIImage(asset: .ringlyNavigationBarLogo)!,
                        accessibilityLabel: tr(.peripheralsJewelry)
                    ))
                }
                else
                {
                    return viewController.reactive.producerFor(keyPath: "title").mapOptional(NavigationBar.Title.text)
                }
            })

        // initialize with the selected reference or with the reviews interface
        let showingReview = services.preferences.reviewsState.producer
            .take(until: reactive.lifetime.ended)
            .map({ $0?.displayValue != nil })
            .skipRepeats()

        services.peripherals.stateProducer
            .filter({ $0.references.count > 0 })
            .combineLatest(with: showingReview)
            .take(first: 1)
            .take(until: reactive.lifetime.ended)
            .startWithValues({ [weak self] state, showingReview in
                guard let strong = self else { return }

                if showingReview
                {
                    let reviews = ReviewsViewController(services: strong.services)
                    strong.pages.setViewControllers([reviews], direction: .forward, animated: false, completion: nil)
                    strong.currentViewController.value = .right(reviews)
                }
                else
                {
                    let reference = state.references.first(where: { $0.identifier == state.activatedIdentifier })
                        ?? state.references[0]

                    self?.setCurrentPeripheralReferenceViewController(reference: reference)
                }
            })

        // reset to the first peripheral reference if the peripheral is forgotten, otherwise update when changed
        let references = services.peripherals.references.producer.take(until: reactive.lifetime.ended)

        references
            .filter({ $0.count > 0 })
            .skip(first: 1)
            .startWithValues({ [weak self] references in
                guard let current = self?.currentViewController.value?.leftValue else { return }
                guard let reference = current.peripheralReference.value else { return }

                if let replacement = references.first(where: { $0.identifier == reference.identifier })
                {
                    current.peripheralReference.value = replacement
                }
                else
                {
                    self?.setCurrentPeripheralReferenceViewController(reference: references[0])
                }
            })

        // hide the reviews view controller once dismissed
        showingReview.ignore(true).startWithValues({ [weak self] _ in
            // check that we are currently displaying a reviews view controller
            guard let strong = self, strong.currentViewController.value?.rightValue != nil else { return }

            // transition to displaying the last peripheral reference
            let controller = strong.services.peripherals.references.value.last
                .map(strong.peripheralReferenceViewController)

            let controllers = controller.map({ [$0] })

            strong.pages.setViewControllers(controllers, direction: .reverse, animated: true, completion: nil)
            strong.currentViewController.value = controller.map(Either.left)
        })

        // show the reviews view controller once activated
        showingReview.skip(first: 1).ignore(false).startWithValues({ [weak self] _ in
            guard let strong = self, strong.currentViewController.value?.rightValue == nil else { return }

            let reviews = ReviewsViewController(services: strong.services)
            strong.pages.setViewControllers([reviews], direction: .forward, animated: true, completion: nil)
            strong.currentViewController.value = .right(reviews)
        })

        // push add peripheral controllers
        let addPeripheralTriggers = SignalProducer.merge(
            navigationBar.actionProducer,
            root.childViewController.producer
                .delay(0.01, on: QueueScheduler.main) // break deadlock
                .mapOptionalFlat({ $0 as? NoPeripheralsViewController })
                .flatMapOptional(.latest, transform: {
                    SignalProducer($0.button.reactive.controlEvents(.touchUpInside))
                })
                .skipNil()
                .void
        )

        addPeripheralTriggers.startWithValues({ [weak self] _ in
            guard let strong = self else { return }

            let discovered = strong.services.peripherals.discoverAndRegisterConnectedPeripherals()

            if discovered.count == 0
            {
                let add = AddPeripheralViewController(services: services)
                strong.navigation.pushViewController(add, animated: true)
                add.pairedProducer.startWithValues({ [weak self] reference in self?.didPair(reference: reference) })
            }
            else
            {
                let reference = discovered[0]

                strong.services.peripherals.activate(identifier: reference.identifier)
                strong.setCurrentPeripheralReferenceViewController(reference: reference)
            }
        })

        // pop pushed controllers
        navigationBar.backProducer.startWithValues({ [weak self] in
            _ = self?.navigation.popViewController(animated: true)
        })

        // show and hide toolbar buttons
        let showingRootProducer = currentNavigationViewController.producer
            .skipNil()
            .map({ [weak self] in $0 === self?.root })
            .skipRepeats()

        let showingPagesProducer = currentNavigationViewController.producer
            .skipNil()
            .map({ [weak self] in ($0 as? ContainerViewController)?.childViewController.value === self?.pages })
            .skipRepeats()

        let multiPeripheralProducer = references
            .map({ $0.count > 1 })
            .skipRepeats()

        showingRootProducer.combineLatest(with: showingPagesProducer.and(multiPeripheralProducer.or(showingReview)))
            .start(animationDuration: 0.25, action: { [weak self] showingRoot, showingPageIndicator in
                // show the navigation bar buttons
                self?.navigationBar.backAvailable.value = !showingRoot
                self?.navigationBar.action.value = showingRoot
                    ? .image(image: UIImage(asset: .addButtonLarge), accessibilityLabel: "Add Jewelry")
                    : nil

                self?.navigationBar.layoutIfInWindowAndNeeded()

                // show the page indicator
                self?.pageIndicator.alpha = showingPageIndicator ? 1 : 0
            })

        // show current page in page indicator
        pageIndicator.model <~ SignalProducer.combineLatest(currentViewController.producer, references, showingReview)
            .pageIndicatorModelProducer.map({ $0 })
    }

    func didPair(reference: PeripheralReference)
    {
        setCurrentPeripheralReferenceViewController(reference: reference)
        navigation.popViewController(animated: true)

        RLYDispatchAfterMain(0.5, { [weak self] in
            (self?.pages.viewControllers?.last as? PeripheralReferenceViewController)?
                .presentActivitySupportModalIfNecessary()
        })
    }
}

extension PeripheralsViewController
{
    // MARK: - Button Producers

    /// Notifies an observer that the user has tapped a "not connecting" button.
    var notConnectingButtonProducer: SignalProducer<(), NoError>
    {
        return currentPeripheralReferenceViewControllerProducer
            .flatMapOptional(.latest, transform: { $0.notConnectingButtonProducer })
            .skipNil()
    }

    /// Notifies an observer that the user has tapped a "remove" button.
    var removeButtonProducer: SignalProducer<RLYPeripheral, NoError>
    {
        return currentPeripheralReferenceViewControllerProducer
            .flatMapOptionalFlat(.latest, transform: { controller in
                controller.peripheralReference.producer
                    .sample(on: controller.removeButtonProducer)
                    .map({ $0?.peripheralValue })
            })
            .skipNil()
    }

    var connectHealthProducer: SignalProducer<(), NoError>
    {
        return currentPeripheralReferenceViewControllerProducer
            .flatMapOptional(.latest, transform: { $0.connectHealthProducer })
            .skipNil()
    }
}

extension PeripheralsViewController
{
    // MARK: - Child Peripheral Reference View Controllers

    /// Creates a peripheral reference view controller with this controller's services, bound to the specified
    /// reference.
    ///
    /// - Parameter reference: The peripheral reference to use.
    /// - Returns: A newly-created peripheral reference view controller.
    fileprivate func peripheralReferenceViewController(reference: PeripheralReference)
        -> PeripheralReferenceViewController
    {
        let viewController = PeripheralReferenceViewController(services: services)
        viewController.peripheralReference.value = reference
        return viewController
    }

    /// Creates a peripheral reference view controller relative to `currentPeripheralReferenceViewController`.
    ///
    /// - Parameter offset: The offset for the new view controller.
    /// - Returns: A newly-created peripheral reference view controller, or `nil`.
    fileprivate func relativeReferenceViewController(offset: Int) -> PeripheralReferenceViewController?
    {
        // ensure the current view controller is a peripheral reference view controller
        guard let current = currentViewController.value?.leftValue else {
            return nil
        }

        // we need the peripheral reference to correctly find the current position
        guard let reference = current.peripheralReference.value else {
            return nil
        }

        // ensure that the offset is valid for a new index
        let references = services.peripherals.references.value
        guard let index = references.index(of: reference) else {
            return nil
        }

        let newIndex = index + offset
        guard newIndex >= references.startIndex && newIndex < references.endIndex else {
            return nil
        }

        return peripheralReferenceViewController(reference: references[newIndex])
    }

    /// Directly sets a new peripheral reference as the new visible reference.
    ///
    /// - Parameters:
    ///   - reference: The peripheral reference to display.
    ///   - direction: The direction to animate, if applicable. `.Forward` is the default value.
    ///   - animated: Whether or not to animate the transition from the previous view controller. `false` is the default
    ///               value.
    fileprivate func setCurrentPeripheralReferenceViewController
        (reference: PeripheralReference,
         direction: UIPageViewControllerNavigationDirection = .forward,
         animated: Bool = false)
    {
        let viewController = PeripheralReferenceViewController(services: services)
        viewController.peripheralReference.value = reference

        pages.setViewControllers([viewController], direction: direction, animated: animated, completion: nil)
        currentViewController.value = .left(viewController)
    }

    fileprivate var currentPeripheralReferenceViewControllerProducer:
        SignalProducer<PeripheralReferenceViewController?, NoError>
    {
        return currentViewController.producer.map({ $0?.leftValue })
    }
}

extension PeripheralsViewController: TabBarViewControllerTappedSelectedListener
{
    func tabBarViewControllerDidTapSelectedItem()
    {
        let peripherals = services.peripherals
        let identifier = peripherals.activatedIdentifier.value

        // make sure that the current view controller is not displaying the selected peripheral already
        let currentIdentifier = currentViewController.value?.leftValue?.peripheralReference.value?.identifier
        guard currentIdentifier != identifier else { return }

        // find the activated peripheral reference
        let references = peripherals.references.value
        guard let activated = references.first(where: { $0.identifier == identifier }) else { return }

        // find the direction to move in
        let referenceIndices = (currentViewController.value?.leftValue?.peripheralReference.value).flatMap({ current in
            unwrap(references.index(of: current), references.index(of: activated))
        })

        let direction: UIPageViewControllerNavigationDirection = referenceIndices.map({ current, activated in
            current < activated ? .forward : .reverse
        }) ?? .reverse // default to reverse, since this is probably the reviews view controller

        setCurrentPeripheralReferenceViewController(reference: activated, direction: direction, animated: true)
    }
}

extension PeripheralsViewController: UIPageViewControllerDataSource
{
    // MARK: - Page View Controller Data Source
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController)
                            -> UIViewController?
    {
        if viewController is ReviewsViewController
        {
            return nil
        }
        else if let relative = relativeReferenceViewController(offset: 1)
        {
            return relative
        }
        else
        {
            return services.preferences.reviewsState.value?.displayValue != nil
                ? ReviewsViewController(services: services)
                : nil
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController)
                            -> UIViewController?
    {
        if viewController is ReviewsViewController
        {
            return services.peripherals.references.value.last.map(peripheralReferenceViewController)
        }
        else
        {
            return relativeReferenceViewController(offset: -1)
        }
    }
}

extension PeripheralsViewController: UIPageViewControllerDelegate
{
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool)
    {
        currentViewController.value = (pageViewController.viewControllers?.first).flatMap({ current in
            (current as? PeripheralReferenceViewController).map(Either.left)
                ?? (current as? ReviewsViewController).map(Either.right)
        })
    }
}

extension PeripheralsViewController: UINavigationControllerDelegate
{
    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationControllerOperation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController)
                              -> UIViewControllerAnimatedTransitioning?
    {
        return SlideTransitionController(operation: operation)
    }

    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController,
                              animated: Bool)
    {
        self.currentNavigationViewController.value = viewController
    }
}

extension SignalProducerProtocol where
    Value == (PeripheralsViewController.CurrentViewController?, [PeripheralReference], Bool),
    Error == NoError
{
    fileprivate var pageIndicatorModelProducer: SignalProducer<PageIndicator.Model, Error>
    {
        let image = UIImage(asset: .pageIndicatorHeart)

        return flatMap(.latest, transform: { optionalCurrent, references, showingReview -> SignalProducer<PageIndicator.Model, Error> in
            // prevent zero division in reference view controller case
            guard let current = optionalCurrent, references.count > 0 else {
                return SignalProducer(value: PageIndicator.Model(pages: 0, progress: 0, lastImage: nil))
            }

            let pages = references.count + (showingReview ? 1 : 0)
            let lastImage = showingReview ? image : nil

            switch current
            {
            case let .left(referenceViewController):
                return referenceViewController.peripheralReference.producer.map({ reference -> PageIndicator.Model in
                    let progress = CGFloat(reference.flatMap(references.index) ?? 0)
                    return PageIndicator.Model(pages: pages, progress: progress, lastImage: lastImage)
                })

            case .right:
                return SignalProducer(value:
                    PageIndicator.Model(pages: pages, progress: CGFloat(pages - 1), lastImage: lastImage)
                )
            }
        })

    }
}
