import UIKit

/// A transition controller for a slight scale in/out and cross-fade.
final class ScaleTransitionController: NSObject {}

extension ScaleTransitionController: UIViewControllerAnimatedTransitioning
{
    // MARK: - Animated Transitioning
    @objc func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    {
        return 0.25
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

        let transitionTransform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        toController?.view.transform = transitionTransform
        toController?.view.alpha = 0

        UIView.animate(withDuration: self.transitionDuration(using: transitionContext), animations: {
            UIView.setAnimationCurve(.easeIn)
            fromController?.view.transform = transitionTransform

            UIView.setAnimationCurve(.easeOut)
            toController?.view.transform = CGAffineTransform.identity

            UIView.setAnimationCurve(.linear)
            fromController?.view.alpha = 0
            toController?.view.alpha = 1
        }, completion: { finished in
            transitionContext.completeTransition(finished)
            fromController?.view.transform = CGAffineTransform.identity
        })
    }
}
