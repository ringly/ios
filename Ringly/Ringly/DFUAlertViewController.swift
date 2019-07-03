import ReactiveCocoa
import ReactiveSwift
import RinglyExtensions
import RinglyKit
import PureLayout
import UIKit
import enum Result.NoError

// MARK: - View Controller
final class DFUAlertViewController: UIViewController
{
    fileprivate var alertType : DFUAlertType?
    
    // MARK: - Subviews
    fileprivate let backgroundView = AlertBackgroundView.newAutoLayout()
    fileprivate let allContentContainer = UIView.newAutoLayout()
    fileprivate let contentViewContainer = UIView.newAutoLayout()
    fileprivate let controlsViewContainer = UIView.newAutoLayout()
    fileprivate let checklist = DFUAlertChecklistView.newAutoLayout()
    
    convenience init(alertType: DFUAlertType)
    {
        self.init()
        self.alertType = alertType
        switch alertType
        {
        case .lostConnection:
            contentView = DFUAlertContent(text: tr(.dfuReconnectAlertTitle), detailText: tr(.dfuReconnectAlertBody)).dfuAlertContentView
        case .didNotUpdate:
            contentView = DFUAlertContent(text: tr(.dfuFailedAlertTitle), detailText: tr(.dfuFailedAlertBody)).dfuAlertContentView
        }
        contentViewContainer.addSubview(contentView!)
        contentView?.autoPinEdgesToSuperviewEdges()
    }
    
    convenience init(alertType: DFUAlertType, closeAction: @escaping () -> () = {})
    {
        self.init()
        self.alertType = alertType
        switch alertType
        {
        case .lostConnection:
            contentView = DFUAlertContent(text: tr(.dfuReconnectAlertTitle), detailText: tr(.dfuReconnectAlertBody)).dfuAlertContentView
        case .didNotUpdate:
            contentView = DFUAlertContent(text: tr(.dfuFailedAlertTitle), detailText: tr(.dfuFailedAlertBody)).dfuAlertContentView
        }
        defer
        {
            contentViewContainer.addSubview(contentView!)
            contentView?.autoPinEdgesToSuperviewEdges()
            self.actionGroup = .single(action: (title: "RESTART UPDATE", dismiss: true, action: closeAction))
        }
    }
    
    // MARK: - Views
    var contentView: UIView?
    
    var controlsView: UIView?
        {
        didSet
        {
            oldValue?.removeFromSuperview()
            
            if let view = controlsView
            {
                controlsViewContainer.addSubview(view)
                view.autoPinEdgesToSuperviewEdges()
            }
        }
    }
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        setup()
    }
    
    override init(nibName: String?, bundle: Bundle?)
    {
        super.init(nibName: nibName, bundle: bundle)
        setup()
    }
    
    //MARK: Gestures
    let closeGesture = UITapGestureRecognizer()
    
    var backgroundDismissable:Bool = false
    
    // MARK: - Initializers
    fileprivate func setup()
    {
        modalPresentationStyle = .overFullScreen
        transitioningDelegate = OverlayPresentationTransition.sharedDelegate
    }
    
    override func loadView()
    {
        let view = UIView()
        self.view = view
        view.addSubview(backgroundView)
        backgroundView.autoPinEdgesToSuperviewEdges()
        
        view.addSubview(allContentContainer)
        allContentContainer.autoFloatInSuperview(inset: 20)
        allContentContainer.backgroundColor = .white
        
        allContentContainer.addSubview(contentViewContainer)
        allContentContainer.addSubview(checklist)
        allContentContainer.addSubview(controlsViewContainer)
        
        contentViewContainer.autoPinEdgeToSuperview(edge: .top, inset: 30)
        contentViewContainer.autoPinEdgeToSuperview(edge: .leading, inset: 30)
        contentViewContainer.autoPinEdgeToSuperview(edge: .trailing, inset: 30)
        
        checklist.autoPin(edge: .top, to: .bottom, of: contentViewContainer)
        checklist.autoPinEdgeToSuperview(edge: .leading, inset: 30)
        checklist.autoPinEdgeToSuperview(edge: .trailing, inset: 30)
        
        switch self.alertType!
        {
        case .lostConnection:
            let reconnectingView = UIView.newAutoLayout()
            reconnectingView.autoSet(dimension: .height, to: 44)
            allContentContainer.addSubview(reconnectingView)

            let separatorView = UIView.rly_separatorView(withHeight: 1, color: UIColor.init(white: 0.91, alpha: 1.0))
            reconnectingView.addSubview(separatorView)
            separatorView.autoPinEdgesToSuperviewEdges(excluding: .bottom)
            
            let containerView = UIView.newAutoLayout()

            let activity = DiamondActivityIndicator.init(color: UIColor.init(white: 0.8, alpha: 1.0))
            activity.isUserInteractionEnabled = false
            activity.autoSetDimensions(to: CGSize(width: 22, height: 22))
            containerView.addSubview(activity)
            activity.autoPinEdgesToSuperviewEdges(excluding: .trailing)
            
            let waitingLabel = UILabel.newAutoLayout()
            waitingLabel.textColor = UIColor(white: 0.2, alpha: 1.0)
            waitingLabel.attributedText = UIFont.gothamBook(13).track(30, tr(.dfuTryingToReconnect)).attributedString
            containerView.addSubview(waitingLabel)
            waitingLabel.autoPin(edge: .leading, to: .trailing, of: activity, offset: 7)
            waitingLabel.autoPinEdgesToSuperviewEdges(excluding: .leading)
            
            reconnectingView.addSubview(containerView)
            containerView.autoPin(edge: .top, to: .bottom, of: separatorView, offset: 20)
            containerView.autoAlignAxis(toSuperviewAxis: .vertical)
            
            reconnectingView.autoPin(edge: .top, to: .bottom, of: checklist, offset: 20)
            reconnectingView.autoPinEdgeToSuperview(edge: .leading, inset: 30)
            reconnectingView.autoPinEdgeToSuperview(edge: .trailing, inset: 30)
            reconnectingView.autoPinEdgeToSuperview(edge: .bottom, inset: 30)
            
        case .didNotUpdate:
            controlsViewContainer.autoPin(edge: .top, to: .bottom, of: checklist, offset: 40)
            controlsViewContainer.autoPinEdgeToSuperview(edge: .leading, inset: 30)
            controlsViewContainer.autoPinEdgeToSuperview(edge: .trailing, inset: 30)
            controlsViewContainer.autoPinEdgeToSuperview(edge: .bottom, inset: 30)
        }
    }
    
    /// The content to display in the alert.
    @nonobjc var content: DFUAlertViewControllerContent?
        {
        didSet { contentView? = (content?.dfuAlertContentView)! }
    }
    
    // MARK: - Actions
    
    /// An alert button action - the title will be displayed in a tappable control, and `action` will be called when
    /// the button is tapped. `dismiss` should be set to `true` if the alert view controller should be dismissed
    /// (modally) after the action has been performed.
    typealias Action = (title: String, dismiss: Bool, action: () -> ())
    
    /// The types of action group that may be displayed in an alert.
    enum ActionGroup
    {
        /// A single action.
        case single(action: Action)
        
        /// A positive action, displayed in a bold button control, and a dismissal action, displayed in a less bold
        /// control.
        case double(action: Action, dismiss: Action)
    }
    
    /// The action groups to display in the alert.
    @nonobjc var actionGroup: ActionGroup?
        {
        didSet
        {
            controlsView = (actionGroup?.view(dismiss: { [weak self] in self?.dismiss() }))!
        }
    }
    
    
    // MARK: - Dismiss
    func dismiss()
    {
        if let dismiss = customDismiss
        {
            dismiss(self)
        }
        else
        {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    fileprivate var customDismiss: ((DFUAlertViewController) -> ())?
    
    override var prefersStatusBarHidden: Bool
    {
        return true
    }
}

extension DFUAlertViewController
{
    // MARK: - Presenting as a Window
    
    /// Presents the alert above the view controller's window.
    ///
    /// - Parameter viewController: The view controller to present above.
    @nonobjc func present(above viewController: UIViewController)
    {
        if let window = viewController.view.window
        {
            present(above: window)
        }
    }
    
    /// Presents the alert above the window.
    ///
    /// - Parameter window: The window to present above.
    @nonobjc func present(above window: UIWindow)
    {
        let viewController = NoStatusBarViewController()
        
        let alertWindow = UIWindow(frame: window.frame)
        alertWindow.windowLevel = UIWindowLevelAlert
        alertWindow.rootViewController = viewController
        alertWindow.isHidden = false
        alertWindow.layoutIfNeeded()
        
        viewController.present(self, animated: true, completion: nil)
        
        customDismiss = { controller in
            controller.dismiss(animated: true, completion: {
                alertWindow.isHidden = true
            })
            
            controller.customDismiss = nil
        }
    }
}

extension DFUAlertViewController: ForegroundBackgroundContentViewProviding
{
    var backgroundContentView: UIView? { return backgroundView }
    var foregroundContentView: UIView? { return allContentContainer }
}

/// Provides content for an `DFUAlertController`.
protocol DFUAlertViewControllerContent
{
    /// The view to display in the alert controller.
    var dfuAlertContentView: UIView { get }
}

/// `UIView` is extended to provide alert view controller content.
extension UIView: DFUAlertViewControllerContent
{
    /// Returns `self`.
    var dfuAlertContentView: UIView { return self }
}


// MARK: - Action Group Extensions
extension DFUAlertViewController.ActionGroup
{
    /// An action group that performs an action and closes the alert, or allows the user to close the alert.
    ///
    /// - Parameters:
    ///   - title: The action title.
    ///   - action: The action callback function.
    static func actionOrClose(title: String, action: @escaping () -> ()) -> DFUAlertViewController.ActionGroup
    {
        return .double(
            action: (title: title, dismiss: true, action: action),
            dismiss: (title: tr(.close), dismiss: true, action: {})
        )
    }
    
    /// An action group that displays the string "Close", dismisses the alert, and performs no action.
    static var close: DFUAlertViewController.ActionGroup
    {
        return .single(action: (title: tr(.close), dismiss: true, action: {}))
    }
    
    /// A view for the action group.
    ///
    /// - Parameter dismissFunction: A function to dismiss the alert view controller.
    fileprivate func view(dismiss dismissFunction: @escaping () -> ()) -> UIView
    {
        switch self
        {
        case let .single(action):
            let buttonControl = ButtonControl.newAutoLayout()
            buttonControl.font = UIFont.gothamMedium(12)
            buttonControl.useDarkAppearance()
            buttonControl.title = action.title
            buttonControl.autoSet(dimension: .height, to: 44)
            
            SignalProducer(buttonControl.reactive.controlEvents(.touchUpInside)).startWithValues({ _ in
                action.action()
                if action.dismiss { dismissFunction() }
            })
            
            return buttonControl
            
        case let .double(action, dismiss):
            let pad = AlertControlPad.newAutoLayout()
            pad.useDarkAppearance()
            
            pad.actionTitle = action.title
            pad.dismissTitle = dismiss.title
            
            pad.actionProducer.startWithValues({
                action.action()
                if action.dismiss { dismissFunction() }
            })
            
            pad.dismissProducer.startWithValues({
                dismiss.action()
                if dismiss.dismiss { dismissFunction() }
            })
            
            return pad
        }
    }
}

extension Reactive where Base: DFUAlertViewController
{
    /// The content to display in the alert.
    var content: BindingTarget<DFUAlertViewControllerContent?>
    {
        return makeBindingTarget { $0.content = $1 }
    }
    
    /// The action groups to display in the alert.
    var actionGroup: BindingTarget<DFUAlertViewController.ActionGroup?>
    {
        return makeBindingTarget { $0.actionGroup = $1 }
    }
}

// MARK: - Hiding Status Bar
private final class NoStatusBarViewController: UIViewController
{
    fileprivate override var prefersStatusBarHidden : Bool { return true }
}


struct DFUAlertContent
{
    /// The title text to display.
    let text: String
    
    /// The detail text to display.
    let detailText: String
}

extension DFUAlertContent: DFUAlertViewControllerContent
{
    var dfuAlertContentView: UIView
    {
        let foregroundColor = UIColor(white: 0.2, alpha: 1.0)
        
        let stack = UIStackView.newAutoLayout()
        stack.alignment = .center
        stack.axis = .vertical
        stack.distribution = .equalSpacing
        stack.autoSet(dimension: .width, to: 216)
        
        stack.addArrangedSubview(spacer(20))
        
        // add the text label
        let textLabel = UILabel.newAutoLayout()
        textLabel.attributedText = text.alertTextAttributedString
        textLabel.numberOfLines = 0
        textLabel.textColor = foregroundColor
        
        stack.addArrangedSubview(textLabel)
        stack.addArrangedSubview(spacer(28))
        
        let detailTextLabel = UILabel.newAutoLayout()
        detailTextLabel.attributedText = detailText.alertDetailTextAttributedString
        detailTextLabel.numberOfLines = 0
        detailTextLabel.textColor = foregroundColor
        
        stack.addArrangedSubview(detailTextLabel)
        stack.addArrangedSubview(spacer(20))
        
        return stack
    }
}

final class DFUAlertChecklistView : UIView
{
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    func setup()
    {
        let checklist = [tr(.dfuChecklistOne), tr(.dfuChecklistTwo), tr(.dfuChecklistThree)]

        let stackView = UIStackView.newAutoLayout()
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 15
        
        for item in checklist
        {
            let itemView = UIView.newAutoLayout()
            let doneCheck = UIImageView.init(image: Asset.doneCheckSmallGreen.image)
            doneCheck.autoSetDimensions(to: CGSize.init(width: 13, height: 13))
            
            itemView.addSubview(doneCheck)
            doneCheck.autoPinEdgeToSuperview(edge: .top, inset: 5)
            doneCheck.autoPinEdgeToSuperview(edge: .leading)
            
            let label = UILabel.newAutoLayout()
            label.textAlignment = .left
            label.textColor = UIColor(white: 0.2, alpha: 1.0)
            label.lineBreakMode = .byWordWrapping
            label.adjustsFontSizeToFitWidth = true
            label.numberOfLines = 0
            label.attributedText = UIFont.gothamBook(12).track(50, item).attributedString
            
            itemView.addSubview(label)
            label.autoPinEdgeToSuperview(edge: .top)
            label.autoPin(edge: .leading, to: .trailing, of: doneCheck, offset: 7.5)
            label.autoPinEdgeToSuperview(edge: .trailing)
            label.autoPinEdgeToSuperview(edge: .bottom)
            stackView.addArrangedSubview(itemView)
        }
    }
}

enum DFUAlertType
{
    case lostConnection
    case didNotUpdate
}

// insert a spacer view at the top of the hierarchy
fileprivate func spacer(_ height: CGFloat) -> UIView
{
    let view = UIView.newAutoLayout()
    view.autoSet(dimension: .height, to: height)
    return view
}
