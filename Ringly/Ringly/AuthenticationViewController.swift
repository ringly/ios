import PureLayout
import ReactiveCocoa
import ReactiveSwift
import Result
import UIKit

/// A view controller displayed when the app starts, before the user has authenticated.
///
/// This view controller manages the authentication process, displaying it as child view controllers of itself.
final class AuthenticationViewController: ServicesViewController
{
    // MARK: - Child View Controllers
    fileprivate let navigation = UINavigationController()
    fileprivate let buttons = AuthenticationButtonsViewController()

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        // add the navigation controller
        navigation.delegate = self
        navigation.isNavigationBarHidden = true
        navigation.pushViewController(buttons, animated: false)

        addChildViewController(navigation)
        view.addSubview(navigation.view)
        navigation.view.autoPinEdgesToSuperviewEdges()
        navigation.didMove(toParentViewController: self)
    }

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // track analytics events for buttons controller
        buttons.reactive.viewDidAppear.startWithValues({ [weak self] _ in
            self?.services.analytics.track(AnalyticsEvent.viewedScreen(name: .loginWall))
        })

        // actions for initial buttons
        let modeActions: SignalProducer<AuthenticationFieldsViewController.Mode, NoError> = SignalProducer.merge(
            SignalProducer(buttons.registerButton.reactive.controlEvents(.touchUpInside)).map({ _ in .register }),
            SignalProducer(buttons.loginButton.reactive.controlEvents(.touchUpInside)).map({ _ in .login })
        )

        modeActions.startWithValues({ [weak self] mode in
            guard let strongSelf = self else { return }

            let authentication = AuthenticationFieldsViewController(services: strongSelf.services)
            authentication.mode.value = mode

            let navigation = AuthenticationNavigationController()
            navigation.navigation.pushViewController(authentication, animated: false)
            navigation.poppedRoot = { [weak self] _ in
                _ = self?.navigation.popViewController(animated: true)
            }

            strongSelf.navigation.pushViewController(navigation, animated: true)
        })
    }

    // MARK: - View Controller
    override var prefersStatusBarHidden : Bool
    {
        return true
    }
}

extension AuthenticationViewController
{
    /**
     Presents the password reset interface, using the specified token string.

     - parameter token: The password reset token string to use.
     */
    func presentPasswordResetWithTokenString(_ tokenString: String)
    {
        let passwordReset = PasswordResetViewController(services: services)
        passwordReset.tokenString.value = tokenString

        if let navigation = self.navigation.visibleViewController as? AuthenticationNavigationController
        {
            navigation.navigation.pushViewController(passwordReset, animated: true)
        }
        else
        {
            let navigation = AuthenticationNavigationController()
            navigation.navigation.pushViewController(passwordReset, animated: false)
            navigation.poppedRoot = { [weak self] _ in _ = self?.navigation.popViewController(animated: true) }
            self.navigation.pushViewController(navigation, animated: true)
        }
    }
}

extension AuthenticationViewController: UINavigationControllerDelegate
{
    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationControllerOperation,
        from fromVC: UIViewController,
        to toVC: UIViewController)
        -> UIViewControllerAnimatedTransitioning?
    {
        if let from = fromVC as? ForegroundBackgroundContentViewProviding,
                 let to = toVC as? ForegroundBackgroundContentViewProviding
        {
            return ForegroundBackgroundTransitionController(
                operation: operation,
                from: from,
                to: to
            )
        }
        else
        {
            return nil
        }
    }
}

extension AuthenticationViewController: ForegroundBackgroundContentViewProviding
{
    var foregroundContentView: UIView?
    {
        return (navigation.viewControllers.last as? ForegroundBackgroundContentViewProviding)?.foregroundContentView
    }

    var backgroundContentView: UIView?
    {
        return (navigation.viewControllers.last as? ForegroundBackgroundContentViewProviding)?.backgroundContentView
    }
}
