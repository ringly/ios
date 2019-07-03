import ReactiveCocoa
import ReactiveSwift
import Result
import UIKit

extension Reactive where Base: UIViewController
{
    // MARK: - Modals

    /**
     A producer that will present the specified view controller when started, then complete after the presentation
     completes.
     
     - parameter viewController: The view controller to present.
     - parameter animated:       Whether or not the presentation should be animated.
     */
    public func present(viewController: UIViewController, animated: Bool) -> SignalProducer<(), NoError>
    {
        return SignalProducer { observer, disposable in
            self.base.present(viewController, animated: animated, completion: {
                observer.sendCompleted()
            })
        }
    }
    
    /**
     A producer that will dismiss the view controller when started, then complete after the dismissal finishes.
     
     - parameter animated: Whether or not to animate the dismissal.
     */
    public func dismiss(animated: Bool) -> SignalProducer<(), NoError>
    {
        return SignalProducer { observer, disposable in
            self.base.dismiss(animated: animated, completion: {
                observer.sendCompleted()
            })
        }
    }

    // MARK: - Lifecycle
    public var viewWillAppear: SignalProducer<(), NoError>
    {
        return SignalProducer(trigger(for: #selector(UIViewController.viewWillAppear(_:))))
    }

    public var viewWillDisappear: SignalProducer<(), NoError>
    {
        return SignalProducer(trigger(for: #selector(UIViewController.viewWillDisappear(_:))))
    }

    public var viewDidAppear: SignalProducer<(), NoError>
    {
        return SignalProducer(trigger(for: #selector(UIViewController.viewDidAppear(_:))))
    }

    public var viewDidDisappear: SignalProducer<(), NoError>
    {
        return SignalProducer(trigger(for: #selector(UIViewController.viewDidDisappear(_:))))
    }
}
