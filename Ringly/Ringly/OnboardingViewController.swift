import ReactiveSwift
import RinglyExtensions
import UIKit
import enum Result.NoError

final class OnboardingViewController: ServicesViewController
{
    // MARK: - Subviews

    /// Contains the background color overlay views.
    fileprivate let colorsView = UIView.newAutoLayout()

    /// An overlay background view, displayed during the activity tracking steps.
    fileprivate let pink = UIView.newAutoLayout()

    /// Contains the scroll view and page indicator.
    fileprivate let content = UIView.newAutoLayout()

    /// The scroll view, which contains the child view controllers. We can't use a page view controller, because we need
    /// to know the exact scroll offset.
    fileprivate let scroll = UIScrollView.newAutoLayout()

    /// A page indicator displaying current progress.
    fileprivate let pageIndicator = PageIndicator.newAutoLayout()

    // MARK: - Child View Controller
    fileprivate let appsController = OnboardingAppsViewController()
    fileprivate let activityController = OnboardingActivityViewController()
    fileprivate let notificationsController = OnboardingNotificationsViewController()

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        // add background color views
        view.addSubview(colorsView)
        colorsView.autoPinEdgesToSuperviewEdges()

        let purple = UIView()
        purple.backgroundColor = UIColor(red: 0.8067, green: 0.5525, blue: 0.8213, alpha: 1.0)
        colorsView.addSubview(purple)
        purple.autoPinEdgesToSuperviewEdges()

        pink.backgroundColor = UIColor(red: 1.0, green: 0.5005, blue: 0.4897, alpha: 1.0)
        pink.alpha = 0
        colorsView.addSubview(pink)
        pink.autoPinEdgesToSuperviewEdges()

        // add content
        view.addSubview(content)
        content.autoPinEdgesToSuperviewEdges()

        // add scroll view
        scroll.delegate = self
        scroll.isPagingEnabled = true
        scroll.showsHorizontalScrollIndicator = false
        scroll.showsVerticalScrollIndicator = false
        content.addSubview(scroll)
        scroll.autoPinEdgesToSuperviewEdges()

        // add view controllers to scroll view
        let viewControllers = [appsController, activityController, notificationsController]
        let edgeTargets = [view, scroll]

        viewControllers.forEach({ viewController in
            addChildViewController(viewController)
            scroll.addSubview(viewController.view)

            edgeTargets.forEach({ target in
                viewController.view.autoPin(
                    edge: .top,
                    to: .top,
                    of: target,
                    offset: DeviceScreenHeight.current.select(four: 10, five: 20, preferred: 45)
                )

                viewController.view.autoPin(edge: .bottom, to: .bottom, of: target, offset: -73)
            })
        })

        // pin view controllers horizontally
        zip(viewControllers.dropLast(), viewControllers.dropFirst()).forEach({
            $0.view.autoPin(edge: .right, to: .left, of: $1.view)
        })

        viewControllers.first?.view.autoPin(edge: .left, to: .left, of: scroll)
        viewControllers.last?.view.autoPin(edge: .right, to: .right, of: scroll)

        // set view controller widths
        viewControllers.forEach({ $0.view.autoMatch(dimension: .width, to: .width, of: view) })

        // finish adding view controllers
        viewControllers.forEach({ viewController in
            viewController.didMove(toParentViewController: self)
        })

        // add page indicator to the bottom of the view
        pageIndicator.model.value = PageIndicator.Model(pages: viewControllers.count, progress: 0, lastImage: nil)
        pageIndicator.isUserInteractionEnabled = false // do not block scrolling
        content.addSubview(pageIndicator)

        pageIndicator.autoAlignAxis(toSuperviewAxis: .vertical)
        pageIndicator.autoPinEdgeToSuperview(edge: .bottom, inset: 32)
    }

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // start the apps animation once the view appears for the first time
        reactive.viewDidAppear.take(first: 1).startWithCompleted({ [weak appsController] in
            appsController?.startAnimation()
        })

        // prompt the user to enable notifications
        let enableNotificationsController = EnableNotificationsController(analytics: services.analytics)
        notificationsController.acceptProducer.startWithValues {
            enableNotificationsController.promptUser(completion: { [weak self] didAccept in
                self?.services.preferences.notificationsEnabled.value = didAccept
            })
        }

        // complete once notifications have been accepted or denied
        notificationsController.declineProducer.startWithValues(completionPipe.1.send)
        enableNotificationsController.userPrompted.producer.ignore(false).void.startWithValues(completionPipe.1.send)
    }

    // MARK: - Completion

    /// A backing pipe for `completionProducer`.
    fileprivate let completionPipe = Signal<(), NoError>.pipe()

    /// A signal producer notifying observers when onboarding has been completed.
    var completionProducer: SignalProducer<(), NoError>
    {
        return SignalProducer(completionPipe.0)
    }

    // MARK: - Status Bar
    override var prefersStatusBarHidden : Bool
    {
        return true
    }
}

extension OnboardingViewController: UIScrollViewDelegate
{
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        // layout values needed for calculations
        let width = scrollView.bounds.size.width
        let offset = scrollView.contentOffset.x
        let size = scrollView.contentSize.width

        // fade the pink background view in while displaying the second view controller
        let addAlpha = min(1, max(offset / width, 0))
        let subtractAlpha = min(1, max(0, (offset - width) / width))
        pink.alpha = addAlpha - subtractAlpha

        // update the page indicator
        pageIndicator.model.modify({ current in
            current = current.map({ model in
                PageIndicator.Model(
                    pages: model.pages,
                    progress: (offset / size) * CGFloat(model.pages),
                    lastImage: nil
                )
            })
        })

        // enable animation on the activity view controller
        activityController.animating.value = offset == width
        notificationsController.animating.value = offset >= width * 2
    }
}

extension OnboardingViewController: ForegroundBackgroundContentViewProviding
{
    var foregroundContentView: UIView? { return content }
    var backgroundContentView: UIView? { return colorsView }
}
