import UIKit

final class OverlayPresentationTransition: NSObject
{
    fileprivate let presentedProvider: ForegroundBackgroundContentViewProviding
    fileprivate let presenting: Bool

    init(presentedProvider: ForegroundBackgroundContentViewProviding, presenting: Bool)
    {
        self.presentedProvider = presentedProvider
        self.presenting = presenting
    }

    /// A shared transition delegate for using `OverlayPresentationTransition` for presented view controllers.
    @nonobjc static let sharedDelegate = TransitioningDelegate(
        configuration: (),
        animation: { _, from, to, operation in
            (operation.presented(from: from, to: to) as? ForegroundBackgroundContentViewProviding).map({ provider in
                OverlayPresentationTransition(presentedProvider: provider, presenting: operation == .push)
            })
        }
    )
}

extension OverlayPresentationTransition: UIViewControllerAnimatedTransitioning
{
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    {
        return 0.33
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
    {
        let key = presenting ? UITransitionContextViewControllerKey.to : UITransitionContextViewControllerKey.from

        guard let presented = transitionContext.viewController(forKey: key) else {
            transitionContext.completeTransition(true)
            return
        }

        let container = transitionContext.containerView

        presented.view.frame = container.bounds
        let outTransform = CGAffineTransform(translationX: 0, y: container.bounds.size.height)

        if presenting
        {
            container.addSubview(presented.view)
            presentedProvider.foregroundContentView?.transform = outTransform
            presentedProvider.backgroundContentView?.alpha = 0
        }

        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            UIView.setAnimationCurve(.linear)
            self.presentedProvider.backgroundContentView?.alpha = self.presenting ? 1 : 0

            UIView.setAnimationCurve(self.presenting ? .easeOut : .easeIn)
            self.presentedProvider.foregroundContentView?.transform = self.presenting
                ? CGAffineTransform.identity : outTransform
        }, completion: { completed in
            transitionContext.completeTransition(completed)
        })
    }
}
