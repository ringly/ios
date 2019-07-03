import Foundation

/// A protocol for view controllers with foreground and background content views.
protocol ForegroundBackgroundContentViewProviding
{
    /// The background content of this view.
    var backgroundContentView: UIView? { get }

    /// The foreground content of this view.
    var foregroundContentView: UIView? { get }
}

/// A transition controller for a horizontal slide of two view controller with foreground and background content views.
final class ForegroundBackgroundTransitionController: NSObject, UIViewControllerAnimatedTransitioning
{
    // MARK: - Properties
    fileprivate let operation: UINavigationControllerOperation
    fileprivate let from: ForegroundBackgroundContentViewProviding
    fileprivate let to: ForegroundBackgroundContentViewProviding

    // MARK: - Initialization

    /**
     Creates a transition controller for the specified view controllers.

     - parameter operation:      The navigation controller operation to use, which determines the direction of the
                                 animation.
     - parameter from:           The from content view provider, which should be the same as `fromController`, but with
                                 a different type.
     - parameter to:             The to content view provider, which should be the same as `toController`, but with a
                                 different type.
     */
    init(operation: UINavigationControllerOperation,
         from: ForegroundBackgroundContentViewProviding,
         to: ForegroundBackgroundContentViewProviding)
    {
        self.operation = operation

        self.from = from
        self.to = to
    }

    // MARK: - Transition
    @objc func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    {
        return 0.5
    }

    @objc func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
    {
        guard let fromController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
              let toController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
        else {
            transitionContext.completeTransition(true)
            return
        }

        let endFrame = transitionContext.finalFrame(for: toController)
        toController.view.frame = endFrame
        toController.view.layoutIfNeeded()

        let pushing = operation == .push

        if fromController.view.superview == transitionContext.containerView
        {
            if pushing
            {
                transitionContext.containerView.insertSubview(toController.view, aboveSubview: fromController.view)
            }
            else
            {
                transitionContext.containerView.insertSubview(toController.view, belowSubview: fromController.view)
            }
        }
        else
        {
            fromController.view.removeFromSuperview()

            for controller in pushing ? [fromController, toController] : [toController, fromController]
            {
                transitionContext.containerView.addSubview(controller.view)
            }
        }

        if pushing
        {
            to.backgroundContentView?.alpha = 0
        }

        let offset = endFrame.size.width * (pushing ? 1 : -1)
        to.foregroundContentView?.transform = CGAffineTransform(translationX: offset, y: 0)

        UIView.animate(withDuration: self.transitionDuration(using: transitionContext), animations: {
            self.from.foregroundContentView?.transform = CGAffineTransform(translationX: -offset, y: 0)
            self.to.foregroundContentView?.transform = CGAffineTransform.identity

            if pushing
            {
                self.to.backgroundContentView?.alpha = 1
            }
            else
            {
                self.from.backgroundContentView?.alpha = 0
            }
        }, completion: { finished in
            transitionContext.completeTransition(finished)

            // reset changed properties to defaults
            self.from.foregroundContentView?.transform = CGAffineTransform.identity
            self.from.backgroundContentView?.alpha = 1
        })
    }
}
