import UIKit

final class AuthenticationNavigationController: UIViewController
{
    // MARK: - Callbacks
    var poppedRoot: ((AuthenticationNavigationController) -> ())?

    // MARK: - Content Views
    fileprivate let gradient = GradientView.purpleBlueGradientView
    fileprivate let foregroundView = UIView.newAutoLayout()

    // MARK: - Layout Contents
    static let topMargin: CGFloat = 55

    // MARK: - Navigation Controller
    let navigation = UINavigationController()

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        // add the gradient view
        view.addSubview(gradient)
        gradient.autoPinEdgesToSuperviewEdges()

        // add foreground view
        view.addSubview(foregroundView)
        foregroundView.autoPinEdgesToSuperviewEdges()

        // add the navigation controller
        navigation.delegate = SlideTransitionController.sharedDelegate.horizontal
        navigation.isNavigationBarHidden = true

        addChildViewController(navigation)
        foregroundView.addSubview(navigation.view)
        navigation.view.autoPinEdgesToSuperviewEdges()
        navigation.didMove(toParentViewController: self)

        // add navigation bar
        let navigationBar = NavigationBar.newAutoLayout()
        navigationBar.backgroundColor = UIColor(white: 1, alpha: 0.2)

        navigationBar.backAvailable.value = true
        navigationBar.title.value = .image(
            image: UIImage(asset: .authenticationTextLogo),
            accessibilityLabel: "Ringly"
        )

        foregroundView.addSubview(navigationBar)

        navigationBar.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.zero, excluding: .bottom)
        navigationBar.autoSet(dimension: .height, to: AuthenticationNavigationController.topMargin)

        // allow back navigation
        navigationBar.backProducer.startWithValues({ [weak self] in
            guard let strong = self else { return }

            if strong.navigation.viewControllers.count > 1
            {
                strong.navigation.popViewController(animated: true)
            }
            else
            {
                strong.poppedRoot?(strong)
            }
        })
    }

    // MARK: - Status Bar
    override var prefersStatusBarHidden : Bool
    {
        return true
    }
}

extension AuthenticationNavigationController: ForegroundBackgroundContentViewProviding
{
    var foregroundContentView: UIView? { return foregroundView }
    var backgroundContentView: UIView? { return gradient }
}
