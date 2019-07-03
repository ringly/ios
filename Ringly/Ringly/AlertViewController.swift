import ReactiveCocoa
import ReactiveSwift
import UIKit

// MARK: - View Controller
final class AlertViewController: UIViewController
{
    // MARK: - Initializers
    fileprivate func setup()
    {
        modalPresentationStyle = .overFullScreen
        transitioningDelegate = OverlayPresentationTransition.sharedDelegate
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

    // MARK: - Convenience Initializers
    convenience init(error: NSError, closeButtonTitle: String = tr(.close), closeAction: @escaping () -> () = {})
    {
        self.init()

        defer // required for didSet to be called
        {
            self.content = AlertImageTextContent(error: error)
            self.actionGroup = .single(action: (title: closeButtonTitle, dismiss: true, action: closeAction))
            self.error = error
        }
    }

    /// Creates an alert view controller for prompting the user to open the Settings app.
    ///
    /// - Parameters:
    ///   - openSettingsText: The primary text to display in the alert.
    ///   - openSettingsDetailText: The secondary text to display in the alert.
    convenience init(openSettingsText: String = tr(.uhOh), openSettingsDetailText: String)
    {
        self.init()

        defer
        {
            content = AlertImageTextContent(text: openSettingsText, detailText: openSettingsDetailText)
            actionGroup = .double(
                action: (title: tr(.openSettings), dismiss: true, action: {
                    if let url = URL(string: UIApplicationOpenSettingsURLString)
                    {
                        UIApplication.shared.openURL(url)
                    }
                }),
                dismiss: (title: tr(.close), dismiss: true, action: {})
            )
        }
    }

    // MARK: - Content

    /// The content to display in the alert.
    @nonobjc var content: AlertViewControllerContent?
    {
        didSet { contentView.contentView = content?.alertContentView }
    }

    /// An optional error. If set to a non-`nil` value, the code and domain will be displayed at the bottom of the
    /// view controller, faintly appearing above the background. This is useful for debugging error messages that appear
    /// on users' devices.
    @nonobjc var error: NSError?
    {
        get { return backgroundView.error }
        set { backgroundView.error = error }
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
            contentView.controlsView = actionGroup?.view(dismiss: { [weak self] in self?.dismiss() })
        }
    }

    // MARK: - Subviews
    fileprivate let backgroundView = AlertBackgroundView.newAutoLayout()
    fileprivate let contentView = AlertContentView.newAutoLayout()
    
    //MARK: Gestures
    fileprivate let tap = UITapGestureRecognizer()
    
    var backgroundDismissable:Bool = false

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        view.addSubview(backgroundView)
        backgroundView.autoPinEdgesToSuperviewEdges()
        backgroundView.addGestureRecognizer(tap)

        contentView.backgroundColor = .white
        view.addSubview(contentView)
        contentView.autoFloatInSuperview(alignedTo: .horizontal, inset: 10)
        contentView.autoAlignAxis(toSuperviewAxis: .vertical)
        contentView.autoSet(dimension: .width, to: 295)
        
        tap.reactive.stateChanged.filter({ $0.state == .ended }).observeValues({ [unowned self] _ in
            if(self.backgroundDismissable) {
                self.dismiss()
            }
        })
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

    fileprivate var customDismiss: ((AlertViewController) -> ())?
}

extension AlertViewController
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
        DispatchQueue.main.async(execute: {
            alertWindow.layoutIfNeeded()
        })

        viewController.present(self, animated: true, completion: nil)

        customDismiss = { controller in
            controller.dismiss(animated: true, completion: {
                alertWindow.isHidden = true
            })

            controller.customDismiss = nil
        }
    }
}

extension AlertViewController: ForegroundBackgroundContentViewProviding
{
    var backgroundContentView: UIView? { return backgroundView }
    var foregroundContentView: UIView? { return contentView }
}

// MARK: - Content Protocol

/// Provides content for an `AlertController`.
protocol AlertViewControllerContent
{
    /// The view to display in the alert controller.
    var alertContentView: UIView { get }
}

/// `UIView` is extended to provide alert view controller content.
extension UIView: AlertViewControllerContent
{
    /// Returns `self`.
    var alertContentView: UIView { return self }
}

// MARK: - Action Group Extensions
extension AlertViewController.ActionGroup
{
    /// An action group that performs an action and closes the alert, or allows the user to close the alert.
    ///
    /// - Parameters:
    ///   - title: The action title.
    ///   - action: The action callback function.
    static func actionOrClose(title: String, action: @escaping () -> ()) -> AlertViewController.ActionGroup
    {
        return .double(
            action: (title: title, dismiss: true, action: action),
            dismiss: (title: tr(.close), dismiss: true, action: {})
        )
    }

    /// An action group that displays the string "Close", dismisses the alert, and performs no action.
    static var close: AlertViewController.ActionGroup
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

extension Reactive where Base: AlertViewController
{
    /// The content to display in the alert.
    var content: BindingTarget<AlertViewControllerContent?>
    {
        return makeBindingTarget { $0.content = $1 }
    }

    /// An optional error. If set to a non-`nil` value, the code and domain will be displayed at the bottom of the
    /// view controller, faintly appearing above the background. This is useful for debugging error messages that appear
    /// on users' devices.
    var error: BindingTarget<NSError?>
    {
        return makeBindingTarget { $0.error = $1 }
    }

    /// The action groups to display in the alert.
    var actionGroup: BindingTarget<AlertViewController.ActionGroup?>
    {
        return makeBindingTarget { $0.actionGroup = $1 }
    }
}

// MARK: - Hiding Status Bar
private final class NoStatusBarViewController: UIViewController
{
    fileprivate override var prefersStatusBarHidden : Bool { return true }
}
