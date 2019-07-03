import Foundation
import ReactiveSwift
import UIKit
import enum Result.NoError

extension SignalProducerProtocol where Error == NoError
{
    /**
     Starts the signal producer, passing the first `next` value to `first`, then further values to `following`.

     This is intended for use with animations - `first` will set up the initial state without animations, then future
     applications will be animated in `following`.

     - parameter first:     The first function.
     - parameter following: The following function.
     */
    @discardableResult
    public func start(first: @escaping (Value) -> (), following: @escaping (Value) -> ()) -> Disposable
    {
        let composite = CompositeDisposable()

        startWithSignal({ signal, disposable in
            composite += signal.take(first: 1).observeValues(first)
            composite += signal.skip(first: 1).observeValues(following)
            composite += disposable
        })

        return composite
    }

    /**
     Starts the signal producer for an animation with initialization. The first value will not be animated, `action`
     will execute synchronously.

     - parameter duration: The duration of the animation.
     - parameter action:   The action to apply the animation.
     */
    @discardableResult
    public func start(animationDuration duration: TimeInterval, action: @escaping (Value) -> ()) -> Disposable
    {
        return start(first: action, following: { value in
            UIView.animate(withDuration: duration, animations: { action(value) })
        })
    }

    /**
     Starts the signal producer for a view transition with initialization. The first value will not be animated,
     `action` will execute synchronously.

     - parameter view:     The view to perform the transition in.
     - parameter duration: The duration of the animation.
     - parameter options:  The animation options.
     - parameter action:   The action to apply the animation.
     */
    @discardableResult
    public func startTransition(in view: UIView,
                                duration: TimeInterval,
                                options: UIViewAnimationOptions,
                                action: @escaping (Value) -> ())
                                -> Disposable
    {
        return start(first: action, following: { value in
            UIView.transition(
                with: view,
                duration: duration,
                options: options,
                animations: { action(value) },
                completion: nil
            )
        })
    }

    /**
     Starts the signal producer for a view cross-dissolve transition with initialization. The first value will not be
     animated, `action` will execute synchronously.

     - parameter view:     The view to perform the transition in.
     - parameter duration: The duration of the animation.
     - parameter action:   The action to apply the animation.
     */
    @discardableResult
    public func startCrossDissolve(in view: UIView, duration: TimeInterval, action: @escaping (Value) -> ()) -> Disposable
    {
        return startTransition(in: view, duration: duration, options: .transitionCrossDissolve, action: action)
    }
}
