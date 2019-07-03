import UIKit

/// A transition controller for a horizontal slide of two view controller with foreground and background content views.
final class SlideTransitionController: NSObject
{
    // MARK: - Direction
    fileprivate let axis: UILayoutConstraintAxis
    fileprivate let operation: UINavigationControllerOperation

    // MARK: - Initialization

    /**
     Creates a transition controller for the specified view controllers.

     - parameter operation:      The navigation controller operation to use, which determines the direction of the
                                 animation.
     */
    init(operation: UINavigationControllerOperation, axis: UILayoutConstraintAxis = .horizontal)
    {
        self.axis = axis
        self.operation = operation
    }

    // MARK: - Shared Delegates

    /// Shared delegates for horizontal and vertical axis slide transitions.
    @nonobjc static let sharedDelegate = (
        horizontal: SlideTransitionController.makeSharedDelegate(.horizontal),
        vertical: SlideTransitionController.makeSharedDelegate(.vertical)
    )

    /// Creates a shared `TransitionDelegate`.
    ///
    /// - Parameter axis: The axis for the delegate to create transitions on.
    @nonobjc fileprivate static func makeSharedDelegate(_ axis: UILayoutConstraintAxis)
        -> UIViewControllerTransitioningDelegate & UINavigationControllerDelegate
    {
        return TransitioningDelegate<UILayoutConstraintAxis>(
            configuration: axis,
            animation: { axis, _, _, operation in return SlideTransitionController(operation: operation, axis: axis) }
        )
    }
}

extension SlideTransitionController: UIViewControllerAnimatedTransitioning
{
    // MARK: - Transition
    @objc func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    {
        return 0.5
    }

    @objc func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
    {
        let container = transitionContext.containerView
        let fromController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)
        let toController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)

        if let toController = toController
        {
            let endFrame = transitionContext.finalFrame(for: toController)
            toController.view.frame = endFrame
            toController.view.layoutIfNeeded()
            container.addSubview(toController.view)
        }

        toController?.view.transform = axis.transform(container.bounds, forPushDirection: operation == .push)
        let transitionTransform = axis.transform(container.bounds, forPushDirection: operation == .pop)

        UIView.animate(withDuration: self.transitionDuration(using: transitionContext), animations: {
            fromController?.view.transform = transitionTransform
            toController?.view.transform = CGAffineTransform.identity
        }, completion: { finished in
            transitionContext.completeTransition(finished)

            // reset changed properties to defaults
            fromController?.view.transform = CGAffineTransform.identity
        })
    }
}

extension UILayoutConstraintAxis
{
    fileprivate func transform(_ bounds: CGRect, forPushDirection: Bool) -> CGAffineTransform
    {
        let factor: CGFloat = forPushDirection ? 1 : -1

        switch self
        {
        case .horizontal:
            return CGAffineTransform(translationX: bounds.size.width * factor, y: 0)
        case .vertical:
            return CGAffineTransform(translationX: 0, y: bounds.size.height * factor)
        }
    }
}
