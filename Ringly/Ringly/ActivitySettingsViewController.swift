import ReactiveSwift
import RinglyExtensions
import RinglyKit
import PureLayout
import UIKit
import enum Result.NoError

/// Displays activity settings
final class ActivitySettingsViewController : ServicesViewController
{
    // NOTES: Diagnostic links will not work correctly if the app is backgrounded 
    //        with this view controller still presented.
    
    // MARK: - Subviews
    fileprivate let scrollView = UIScrollView.newAutoLayout()
    fileprivate let stack = UIStackView.newAutoLayout()
    
    let closeView = UIView.newAutoLayout()
    
    let goalSpacerView = UIView.newAutoLayout()
    let spacerView = UIView.newAutoLayout()
    
    override func loadView()
    {
        // set up the base view
        self.view = GradientView.activityTrackingGradientView
        
        view.addSubview(closeView)
        closeView.autoSet(dimension: .height, to: 60)
        closeView.autoPinEdgeToSuperview(edge: .top)
        closeView.autoPinEdgeToSuperview(edge: .leading)
        closeView.autoPinEdgeToSuperview(edge: .trailing)
        
        // set up the scroll view
        scrollView.indicatorStyle = .white
        view.addSubview(scrollView)
        scrollView.clipsToBounds = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.autoPin(edge: .top, to: .bottom, of: closeView)
        scrollView.autoPinEdgeToSuperview(edge: .leading)
        scrollView.autoPinEdgeToSuperview(edge: .trailing)
        scrollView.autoPinEdgeToSuperview(edge: .bottom)
        
        let close:((Any)->Void) = { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }
        
        let closeXImageView = UIImageView.newAutoLayout()
        closeXImageView.image = Asset.alertClose.image.withRenderingMode(.alwaysTemplate)
        closeXImageView.tintColor = UIColor.white
        closeXImageView.contentMode = .scaleAspectFit
        
        // add stack view for preferences
        stack.axis = .vertical
        stack.alignment = .fill
        scrollView.addSubview(stack)
        
        stack.autoPinEdgeToSuperview(edge: .top)
        stack.autoPin(edge: .leading, to: .leading, of: view, offset: 37)
        stack.autoPin(edge: .trailing, to: .trailing, of: view, offset: -37)
        stack.autoPinEdgeToSuperview(edge: .bottom)
        
        // create sub-controllers
        let goal = ActivityGoalViewController(services: services)
        let switches = ActivitySwitchViewController(services: services)
        
        // title label setup
        let titleBar = UIView.newAutoLayout()
        titleBar.autoSet(dimension: .height, to: 90)
        
        let titleLabel = UILabel.newAutoLayout()
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white
        titleBar.addSubview(titleLabel)
        titleLabel.autoPinEdgeToSuperview(edge: .bottom, inset: 15)
        
        titleLabel.autoPinEdgeToSuperview(edge: .leading)
        titleLabel.autoPinEdgeToSuperview(edge: .trailing)
        titleLabel.attributedText = UIFont.gothamBook(20).track(250, tr(.stayActive)).attributedString
        
        // description label setup
        let descriptionBar = UIView.newAutoLayout()
        descriptionBar.autoSet(dimension: .height, to: 80)
        
        let descriptionLabel = UILabel.newAutoLayout()
        descriptionLabel.textAlignment = .center
        descriptionLabel.textColor = .white
        descriptionBar.addSubview(descriptionLabel)
        descriptionLabel.autoPinEdgeToSuperview(edge: .top)
        descriptionLabel.autoPinEdgeToSuperview(edge: .leading)
        descriptionLabel.autoPinEdgeToSuperview(edge: .trailing)
        descriptionLabel.numberOfLines = 3
        descriptionLabel.lineBreakMode = .byWordWrapping
        let descriptionText = "Track your steps, everyday."
        descriptionLabel.attributedText = UIFont.gothamBook(16).track(150, descriptionText).attributedString
        
        
        // vertically, always start with the goal and switches view controllers
        let viewControllers: [UIViewController] = [
            goal,
            switches
        ]
        
        // add the view controllers and separators to the stack view
        typealias PreferencesEither = Either<UIViewController, UIView>
        
        func addEither(_ either: PreferencesEither)
        {
            switch either
            {
            case .left(let viewController):
                addChildViewController(viewController)
                viewController.view.translatesAutoresizingMaskIntoConstraints = false
                stack.addArrangedSubview(viewController.view)
                viewController.didMove(toParentViewController: self)
            case .right(let view):
                stack.addArrangedSubview(view)
            }
        }
        
        let bellSeparator = BellSeparatorView.newAutoLayout()
        bellSeparator.autoSet(dimension: .height, to: 30)
        
        addEither(PreferencesEither.right(titleBar))
        addEither(PreferencesEither.right(descriptionBar))
        
        let closeButton = GestureAvoidableButton.newAutoLayout()
        closeView.addSubview(closeButton)
        closeButton.autoSet(dimension: .width, to: 60)
        closeButton.autoPinEdgeToSuperview(edge: .top)
        closeButton.autoPinEdgeToSuperview(edge: .leading)
        closeButton.addSubview(closeXImageView)
        closeButton.reactive.controlEvents(.touchUpInside).observeValues(close)
        closeXImageView.autoSetDimensions(to: CGSize.init(width: 14, height: 14))
        closeXImageView.autoPin(edge: .left, to: .left, of: closeButton, offset: 20)
        closeXImageView.autoPin(edge: .top, to: .top, of: closeButton, offset: 20)
        
        goalSpacerView.autoSet(dimension: .height, to: 50)
        
        addEither(PreferencesEither.left(goal))
        addEither(PreferencesEither.right(goalSpacerView))
        addEither(PreferencesEither.right(bellSeparator))
        addEither(PreferencesEither.left(switches))
    }
    
    override var prefersStatusBarHidden: Bool
    {
        return true
    }
}
