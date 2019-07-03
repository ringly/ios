
import ReactiveSwift
import Result
import RinglyExtensions
import UIKit

// MARK: - View Controller

/// A view controller that contains a single child view controller, and supports arbitrary animated transitions between
/// previous and new view controllers.
final class ContainerViewController: UIViewController
{
    // MARK: - Child View Controller

    /// The child view controller currently displayed by this container view controller.
    let childViewController = MutableProperty(UIViewController?.none)

    // MARK: - Transitioning
    weak var childTransitioningDelegate: ContainerViewControllerTransitioningDelegate?

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        childViewController.producer
            // if a redundant value is set, do not attempt to perform a transition
            .skipRepeats(===)
            .startWithValues({ [weak self] controller in
                self?.updateContainer(controller)
            })
    }

    // MARK: - Updating Container View Controller

    /// Updates the child view controller, reusing the current child if it is of the same type.
    ///
    /// - parameter type:   The child view controller type to update to.
    /// - parameter make:   A function to create the child view controller. If omitted, this function invokes `init()`.
    /// - parameter update: A function to update the child view controller's state. This function will be invoked with
    ///                     an old or newly-created view controller.
    func updateChild<Child: UIViewController>(type: Child.Type,
                                              make: () -> Child = { Child() },
                                              update: (Child) -> () = { _ in })
    {
        if let child = childViewController.value as? Child
        {
            update(child)
        }
        else
        {
            let child = make()
            update(child)
            childViewController.value = child
        }
    }

    /// Updates the child view controller, reusing the current child if it is of the same type.
    ///
    /// - parameter type:     The child view controller type to update to.
    /// - parameter services: The services object to pass to newly-created view controllers.
    /// - parameter update:   A function to update the child view controller's state. This function will be invoked with
    ///                       an old or newly-created view controller.
    func updateServicesChild<Child: ServicesViewController>(type: Child.Type,
                                                            services: Services,
                                                            update: (Child) -> () = { _ in })
    {
        updateChild(type: type, make: { Child(services: services) }, update: update)
    }

    /// The previously updated view controller. Used by `updateContainer` to perform transitions.
    fileprivate var previousViewController = UIViewController?.none

    /// Updates the container view controller. An internal utility.
    ///
    /// - parameter newViewController: The new view controller to display.
    fileprivate func updateContainer(_ newViewController: UIViewController?)
    {
        // update status bar appearance for the new view controller
        setNeedsStatusBarAppearanceUpdate()

        // add the new view controller
        newViewController?.addAsEdgePinnedChild(of: self, in: view)

        // perform an animated transition if the delegate provides one
        if let animationController = childTransitioningDelegate?
            .containerViewController(containerViewController: self,
                                     animationControllerForTransitionFromViewController: previousViewController,
                                     toViewController: newViewController)
        {
            let context = ContainerViewControllerTransitionContext(
                frame: view.bounds,
                fromViewController: previousViewController,
                toViewController: newViewController,
                containerView: view
            )

            animationController.animateTransition(using: context)

            // store reference to previous, since we will reassign before the transition completes
            let previous = previousViewController
            context.completed.await(true).startWithCompleted({ [weak previous] in
                previous?.removeFromParentViewControllerImmediately()
            })
        }
        else
        {
            // perform an animation-less swap of the view controllers
            previousViewController?.removeFromParentViewControllerImmediately()
        }

        previousViewController = newViewController
    }

    // MARK: - Status Bar
    override var childViewControllerForStatusBarStyle : UIViewController?
    {
        return childViewController.value
    }

    override var childViewControllerForStatusBarHidden : UIViewController?
    {
        return childViewController.value
    }
}

extension ContainerViewController: TabBarViewControllerTappedSelectedListener
{
    func tabBarViewControllerDidTapSelectedItem()
    {
        (childViewController.value as? TabBarViewControllerTappedSelectedListener)?
            .tabBarViewControllerDidTapSelectedItem()
    }
}

// MARK: - Delegate

/// Defines the methods required for transitioning delegates of `ContainerViewController` instances.
protocol ContainerViewControllerTransitioningDelegate: class
{
    // MARK: - Child View Controller Transitions

    /**
     Asks the delegate for a transition controller to handle a transition between child view controllers. If the
     delegate returns `nil`, or no delegate is provided, the view controllers will be swapped without animation.

     - parameter containerViewController: The container view controller.
     - parameter fromViewController:      The outgoing child view controller, or `nil`.
     - parameter toViewController:        The incoming child view controller, or `nil`.
     */
    func containerViewController(
        containerViewController: ContainerViewController,
        animationControllerForTransitionFromViewController fromViewController: UIViewController?,
        toViewController: UIViewController?)
        -> UIViewControllerAnimatedTransitioning?
}

// MARK: - Transition Context
private final class ContainerViewControllerTransitionContext: NSObject
{
    // MARK: - Initialization
    init(frame: CGRect,
         fromViewController: UIViewController?,
         toViewController: UIViewController?,
         containerView: UIView)
    {
        self.frame = frame
        self.fromViewController = fromViewController
        self.toViewController = toViewController
        self.containerViewProperty = containerView
    }

    // MARK: - Frames

    /// The frame for child views.
    let frame: CGRect

    // MARK: - View Controllers

    /// The outgoing view controller.
    let fromViewController: UIViewController?

    /// The incoming view controller
    let toViewController: UIViewController?

    /// A backing property for `completed`.
    fileprivate let completedProperty = MutableProperty(false)

    /// A signal producer for completion of the transition.
    var completed: SignalProducer<Bool, NoError> { return completedProperty.producer }

    /// MARK: Display
    let containerViewProperty: UIView
}

extension ContainerViewControllerTransitionContext: UIViewControllerContextTransitioning
{
    // MARK: - Completion
    @objc func completeTransition(_ didComplete: Bool)
    {
        completedProperty.value = true
    }

    // MARK: - Container View
    @objc var containerView : UIView
    {
        return containerViewProperty
    }

    // MARK: - Keys
    @objc func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController?
    {
        return [
            UITransitionContextViewControllerKey.from: fromViewController,
            UITransitionContextViewControllerKey.to: toViewController
        ][key].flatten()
    }

    @objc func view(forKey key: UITransitionContextViewKey) -> UIView?
    {
        return [
            UITransitionContextViewKey.from: fromViewController?.view,
            UITransitionContextViewKey.to: toViewController?.view
        ][key].flatten()
    }

    // MARK: - Frames
    @objc func initialFrame(for vc: UIViewController) -> CGRect
    {
        return frame
    }

    @objc func finalFrame(for vc: UIViewController) -> CGRect
    {
        return frame
    }

    @objc var targetTransform : CGAffineTransform
    {
        return CGAffineTransform.identity
    }

    // MARK: - State

    /// The transition cannot be cancelled.
    @objc var transitionWasCancelled : Bool { return false }

    /// The transition is always animated.
    @objc var isAnimated : Bool { return true }

    /// The transition is never interactive.
    @objc var isInteractive : Bool { return false }

    /// This value doesn't matter.
    @objc var presentationStyle : UIModalPresentationStyle { return .custom }

    // MARK: - Empty Implementations

    /// The transition is not interactive, so this function does nothing.
    @objc func updateInteractiveTransition(_ percentComplete: CGFloat) {}

    /// The transition is not interactive, so this function does nothing.
    @objc func finishInteractiveTransition() {}

    /// The transition is not interactive, so this function does nothing.
    @objc func cancelInteractiveTransition() {}

    /// The transition is not interactive, so this function does nothing.
    @objc func pauseInteractiveTransition() {}
}

// MARK: - View Controller Extensions
extension UIViewController
{
    /**
     Adds the view controller as a child of the specified view controller, pinning its view's edges to the parent view
     controller's view's edges.

     - parameter parent: The new parent view controller for the receiver.
     */
    func addAsEdgePinnedChild(of parent: UIViewController, in view: UIView)
    {
        parent.addChildViewController(self)
        view.addSubview(self.view)
        self.view.autoPinEdgesToSuperviewEdges()
        didMove(toParentViewController: parent)
    }

    /// Removes the view controller from its parent view controller, and the view controller's view from its superview.
    func removeFromParentViewControllerImmediately()
    {
        willMove(toParentViewController: nil)
        view.removeFromSuperview()
        removeFromParentViewController()
    }
}
