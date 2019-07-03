import PureLayout
import UIKit

/// A view controller displayed when the app starts, before the user has authenticated.
///
/// This view controller manages the authentication process, displaying it as child view controllers of itself.
final class AuthenticationButtonsViewController: UIViewController
{
    // MARK: - Child View Controllers
    fileprivate let video = VideoBackgroundViewController()

    // MARK: - Subviews
    fileprivate let foregroundView = UIView.newAutoLayout()
    fileprivate let logo = UIImageView.newAutoLayout()
    let registerButton = ButtonControl.newAutoLayout()
    let loginButton = ButtonControl.newAutoLayout()

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        // add the video view controller first, as a background for all other views
        addChildViewController(video)
        view.addSubview(video.view)
        video.view.autoPinEdgesToSuperviewEdges()
        video.didMove(toParentViewController: self)

        // add foreground content view
        view.addSubview(foregroundView)
        foregroundView.autoPinEdgesToSuperviewEdges()

        // add subviews
        logo.image = UIImage(asset: .authenticationLogo)
        logo.applyAuthenticationButtonsShadow()
        foregroundView.addSubview(logo)

        // add buttons to wrapper
        registerButton.title = tr(.signUp)
        foregroundView.addSubview(registerButton)

        loginButton.title = tr(.login)
        foregroundView.addSubview(loginButton)

        let textColor = UIColor(red: 0.4164, green: 0.5684, blue: 0.8251, alpha: 1.0)

        for button in [registerButton, loginButton]
        {
            button.textColor = textColor
        }

        // layout
        logo.autoPinEdgeToSuperview(edge: .top, inset: 60)
        logo.autoAlignAxis(toSuperviewAxis: .vertical)

        for view in [registerButton, loginButton]
        {
            view.autoPinEdgeToSuperview(edge: .leading, inset: 40, relation: .greaterThanOrEqual)
            view.autoPinEdgeToSuperview(edge: .trailing, inset: 40, relation: .greaterThanOrEqual)
            view.autoSet(dimension: .width, to: 256)
            view.autoSet(dimension: .height, to: 50)
            view.autoAlignAxis(toSuperviewAxis: .vertical)
        }

        loginButton.autoPin(edge: .top, to: .bottom, of: registerButton, offset: 20)
        loginButton.autoPinEdgeToSuperview(edge: .bottom, inset: 40)
    }

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        video.configuration.value = Bundle.main.url(forResource: "ringly", withExtension: "mp4").map({ url in
            (videoURL: url, completion: .loop)
        })
    }

    // MARK: - View Controller
    override var prefersStatusBarHidden : Bool
    {
        return true
    }
}

extension AuthenticationButtonsViewController: ForegroundBackgroundContentViewProviding
{
    var foregroundContentView: UIView? { return foregroundView }
    var backgroundContentView: UIView? { return video.view }
}

extension UIView
{
    fileprivate func applyAuthenticationButtonsShadow()
    {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize.zero
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 4
    }
}
