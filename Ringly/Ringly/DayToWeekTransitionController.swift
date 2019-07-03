import Foundation

final class DayToWeekTransitionController: NSObject
{
    init(operation: UINavigationControllerOperation)
    {
        self.operation = operation
    }

    let operation: UINavigationControllerOperation
}

extension DayToWeekTransitionController: UIViewControllerAnimatedTransitioning
{
    @nonobjc static let transitionDuration: TimeInterval = 0.33

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    {
        return DayToWeekTransitionController.transitionDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
    {
        guard let
            from = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let to = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
        else {
            transitionContext.completeTransition(false)
            return
        }

        // add the incoming view to the container view controller
        let container = transitionContext.containerView
        container.addSubview(to.view)

        // initialize incoming view layout
        to.view.alpha = 0
        to.view.frame = transitionContext.finalFrame(for: to)
        to.view.layoutIfInWindowAndNeeded()

        // determine which view controller we shoudl transform
        let isPop = operation == .pop
        let scaleTargetViewController = isPop ? to : from
        let translateTargetViewController = isPop ? from : to

        // determine the transforms to use for making the transition
        let scaleFactor: CGFloat = 0.8
        let containerSize = container.bounds.size
        let scaledDown = CGSize(width: containerSize.width * scaleFactor, height: containerSize.height * scaleFactor)
        let scaledDownFrame = CGRect(
            origin: CGPoint(
                x: containerSize.width / 2 - scaledDown.width / 2,
                y: containerSize.height - scaledDown.height
            ),
            size: scaledDown
        )

        let scaleTargetTransform = container.bounds.transform(to: scaledDownFrame)
        let translateTargetTransform = CGAffineTransform(translationX: 0, y: containerSize.height)

        // initialize transition state
        if isPop
        {
            scaleTargetViewController.view.transform = scaleTargetTransform
            scaleTargetViewController.view.alpha = 0
        }
        else
        {
            translateTargetViewController.view.transform = translateTargetTransform
        }

        // fade the views in and out in an overlapping sense, so that they are fully faded in for more time
        let duration = transitionDuration(using: transitionContext)

        UIView.animate(withDuration: duration * 0.66, animations: {
            UIView.setAnimationCurve(.linear)
            to.view.alpha = 1
        })

        UIView.animate(withDuration: duration * 0.66, delay: duration * 0.33, options: [], animations: {
            UIView.setAnimationCurve(.linear)
            from.view.alpha = 0
        }, completion: nil)

        UIView.animate(withDuration: duration, animations: {
            if isPop
            {
                UIView.setAnimationCurve(.easeOut)
                scaleTargetViewController.view.transform = CGAffineTransform.identity

                UIView.setAnimationCurve(.easeIn)
                translateTargetViewController.view.transform = translateTargetTransform
            }
            else
            {
                UIView.setAnimationCurve(.easeIn)
                scaleTargetViewController.view.transform = scaleTargetTransform

                UIView.setAnimationCurve(.easeOut)
                translateTargetViewController.view.transform = CGAffineTransform.identity
            }

        }, completion: { completed in
            transitionContext.completeTransition(completed)

            // reset view state
            from.view.alpha = 1
            scaleTargetViewController.view.transform = CGAffineTransform.identity
            translateTargetViewController.view.transform = CGAffineTransform.identity
        })
    }
}

extension CGRect
{
    func transform(_ to: CGRect) -> CGAffineTransform
    {
        let transform = CGAffineTransform(translationX: to.midX - midX, y: to.midY - midY)
        return transform.scaledBy(x: to.width / width, y: to.height / height)
    }
}
