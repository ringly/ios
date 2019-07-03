import UIKit

final class ConfigurationsOnboardingTransition: NSObject, UIViewControllerAnimatedTransitioning
{
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    {
        return 0.33
    }

    func animateTransition(using context: UIViewControllerContextTransitioning)
    {
        // view controllers and container
        let container = context.containerView
        let from = context.viewController(forKey: UITransitionContextViewControllerKey.from)
        let to = context.viewController(forKey: UITransitionContextViewControllerKey.to)

        // add the incoming view, if applicable
        if let to = to
        {
            container.addSubview(to.view)
            to.view.frame = context.finalFrame(for: to)
        }

        // determine offscreen transforms for the incoming and outgoing views
        let toTransform = (to?.view.frame.size.height).map({ CGAffineTransform(translationX: 0, y: $0) })
            ?? CGAffineTransform.identity

        let fromTransform = (from?.view.frame.size.height).map({ CGAffineTransform(translationX: 0, y: $0) })
            ?? CGAffineTransform.identity

        // content view providers for each view
        let fromProviding = from as? ForegroundBackgroundContentViewProviding
        let toProviding = to as? ForegroundBackgroundContentViewProviding

        // hide the incoming view by default
        toProviding?.backgroundContentView?.alpha = 0
        toProviding?.foregroundContentView?.transform = toTransform

        UIView.animate(withDuration: transitionDuration(using: context), animations: {
            // crossfade background views
            UIView.setAnimationCurve(.linear)
            toProviding?.backgroundContentView?.alpha = 1
            fromProviding?.backgroundContentView?.alpha = 0

            // move from view offscreen
            UIView.setAnimationCurve(.easeIn)
            fromProviding?.foregroundContentView?.transform = fromTransform

            // move to view onscreen
            UIView.setAnimationCurve(.easeOut)
            toProviding?.foregroundContentView?.transform = CGAffineTransform.identity
        }, completion: { _ in
            context.completeTransition(true)

            // reset from view
            fromProviding?.foregroundContentView?.transform = CGAffineTransform.identity
        })
    }
}
