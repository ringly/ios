import PureLayout
import ReactiveSwift
import Result
import UIKit

extension UIView
{
    // MARK: - Animation Producers

    /**
     Returns an animation as a signal producer.
     
     - parameter duration:   The duration of the animation.
     - parameter delay:      The animation delay, with a default value of `0`.
     - parameter options:    The animation options, with a default value of an empty option set.
     - parameter animations: A block of animations to perform.
     
     - returns: A signal producer that will yield the `finished` value, then complete.
     */
    public static func animationProducer(duration: TimeInterval,
                                         delay: TimeInterval = 0,
                                         options: UIViewAnimationOptions = UIViewAnimationOptions(),
                                         animations: @escaping () -> Void)
                                         -> SignalProducer<Bool, NoError>
    {
        return SignalProducer { observer, _ in
            UIView.animate(
                withDuration: duration,
                delay: delay,
                options: options,
                animations: animations,
                completion: { finished in
                    observer.send(value: finished)
                    observer.sendCompleted()
                }
            )
        }
    }
    
    /**
     Returns a transition as a signal producer.
     
     - parameter view:       The view to transition with.
     - parameter duration:   The duration of the animation.
     - parameter options:    The animation options, with a default value of an empty option set.
     - parameter animations: A block of animations to perform.
     
     - returns: A signal producer that will yield the `finished` value, then complete.
     */
    public static func transitionProducer(view: UIView,
                                          duration: TimeInterval,
                                          options: UIViewAnimationOptions = UIViewAnimationOptions(),
                                          animations: @escaping () -> ())
                                          -> SignalProducer<Bool, NoError>
    {
        return SignalProducer { observer, _ in
            UIView.transition(
                with: view,
                duration: duration,
                options: options,
                animations: animations,
                completion: { finished in
                    observer.send(value: finished)
                    observer.sendCompleted()
                }
            )
        }
    }
}

extension UIView
{
    // MARK: - Conditional Animation

    /**
     Animates if a condition is `true`. Otherwise, executes the animation block synchronously.

     - parameter condition:  The condition.
     - parameter duration:   The animation duration.
     - parameter animations: The animation block.
     */
    public static func animate(if condition: Bool, duration: TimeInterval, animations: @escaping () -> ())
    {
        if condition
        {
            UIView.animate(withDuration: duration, animations: animations)
        }
        else
        {
            animations()
        }
    }
}

extension UIView
{
    // MARK: - Layout

    /// Performs `layoutIfNeeded` if the view is currently in a window.
    public func layoutIfInWindowAndNeeded()
    {
        if window != nil
        {
            layoutIfNeeded()
        }
    }
}

extension UIView
{
    // MARK: - Layout Constraints

    /**
     "Floats" the view in its superview, centering it, and requiring it to be inside its superview's edges.

     - parameter inset: An optional inset parameter. The default value is `0`.
     */
    @discardableResult
    public func autoFloatInSuperview(inset: CGFloat = 0) -> [NSLayoutConstraint]
    {
        return [ALEdge.leading, .trailing, .top, .bottom].map({ edge in
            autoPinEdgeToSuperview(edge: edge, inset: inset, relation: .greaterThanOrEqual)
        }) + autoCenterInSuperview()
    }

    /**
     "Floats" the view in its superview relative to an axis, centering it, and requiring it to be inside its superview's
     leading and trailing edges.

     - parameter inset: An optional inset parameter. The default value is `0`.
     */
    @discardableResult
    public func autoFloatInSuperview(alignedTo axis: ALAxis, inset: CGFloat = 0) -> [NSLayoutConstraint]
    {
        let vertical = axis == .vertical

        return [
            autoPinEdgeToSuperview(edge: vertical ? .leading : .top, inset: inset, relation: .greaterThanOrEqual),
            autoPinEdgeToSuperview(edge: vertical ? .trailing : .bottom, inset: inset, relation: .greaterThanOrEqual),
            autoAlignAxis(toSuperviewAxis: axis)
        ]
    }

    /// Adds layout constraints setting the view's width and height to `size`.
    ///
    /// - parameter size: The width and height for the view.
    ///
    /// - returns: The newly-added layout constraints.
    @discardableResult
    public func autoSetEqualDimensions(to size: CGFloat) -> [NSLayoutConstraint]
    {
        return autoSetDimensions(to: CGSize(width: size, height: size))
    }
}
