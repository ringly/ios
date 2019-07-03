import UIKit

/// Implements a transitioning delegate with a single function.
final class TransitioningDelegate<Configuration>: NSObject, UINavigationControllerDelegate, UIViewControllerTransitioningDelegate
{
    // MARK: - Initialization

    /// Initializes a transitioning delegate.
    ///
    /// - Parameters:
    ///   - configuration: A configuration value, which will be passed to all animation callbacks.
    ///   - animation: An animation callback, used when creating an animation controller.
    init(configuration: Configuration, animation: @escaping Animation)
    {
        self.configuration = configuration
        self.animation = animation
    }

    // MARK: - Configuration

    /// The configuration value stored on the transitioning delegate. This value will be passed to `animation` when
    /// a transition is required.
    fileprivate let configuration: Configuration

    // MARK: - Animation

    /// A function from a configuration value, the "from" and "to" view controllers, and a navigation operation to
    /// an animation to perform.
    typealias Animation = (Configuration, UIViewController?, UIViewController?, UINavigationControllerOperation)
        -> UIViewControllerAnimatedTransitioning?

    /// The animation function.
    fileprivate let animation: Animation

    // MARK: - Navigation Controller Delegate
    @objc func navigationController(_ navigationController: UINavigationController,
                                    animationControllerFor operation: UINavigationControllerOperation,
                                    from fromVC: UIViewController,
                                    to toVC: UIViewController)
        -> UIViewControllerAnimatedTransitioning?
    {
        return animation(configuration, fromVC, toVC, operation)
    }

    // MARK: - View Controller Transitioning Delegate
    @objc func animationController(forPresented presented: UIViewController,
                                                         presenting: UIViewController,
                                                         source: UIViewController)
        -> UIViewControllerAnimatedTransitioning?
    {
        return animation(configuration, presenting, presented, .push)
    }

    @objc func animationController(forDismissed dismissed: UIViewController)
        -> UIViewControllerAnimatedTransitioning?
    {
        return animation(configuration, dismissed, dismissed.presentingViewController, .pop)
    }
}

extension UINavigationControllerOperation
{
    /// Determines the presented view controller from a "from" and "to" view controller operation.
    ///
    /// Equivalent to `operation == .Push ? to : from`.
    ///
    /// - Parameters:
    ///   - from: The from view controller.
    ///   - to: The to view controller.
    /// - Returns: The presented view controller.
    func presented(from: UIViewController?, to: UIViewController?) -> UIViewController?
    {
        return self == .push ? to : from
    }
}
