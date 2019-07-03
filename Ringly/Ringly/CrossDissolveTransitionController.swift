import UIKit

/// A transition controller for a fade from one view controller to another view controller.
final class CrossDissolveTransitionController: NSObject
{
    // MARK: - Properties

    /// The duration of the transition.
    let duration: TimeInterval

    // MARK: - Initialization

    /**
     Creates a cross-dissolve transition controller with the specified duration.

     - parameter duration: The duration of the transition.
     */
    init(duration: TimeInterval)
    {
        self.duration = duration
    }

    // MARK: - Shared Delegate
    /// Shared delegates for horizontal and vertical axis slide transitions.
    @nonobjc static let sharedDelegate = TransitioningDelegate<()>(
        configuration: (),
        animation: { _, _, _, _ in CrossDissolveTransitionController(duration: 0.25) }
    )
}

extension CrossDissolveTransitionController: UIViewControllerAnimatedTransitioning
{
    // MARK: - Transition
    @objc func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    {
        return duration
    }

    @objc func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
    {
        let from = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)
        let to = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
        to?.view.alpha = 0

        let container = transitionContext.containerView
        let frame = container.bounds

        for controller in [from, to].flatMap({ $0 })
        {
            if controller.view.superview == nil
            {
                container.addSubview(controller.view)
            }

            controller.view.frame = frame
            controller.view.layoutIfNeeded()
        }

        UIView.animate(withDuration: self.transitionDuration(using: transitionContext), animations: {
            to?.view.alpha = 1
            from?.view.alpha = 0
        }, completion: { finished in
            transitionContext.completeTransition(finished)
        })
    }
}
