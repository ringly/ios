import ReactiveCocoa
import ReactiveSwift
import RinglyExtensions
import RinglyKit
import PureLayout
import UIKit
import enum Result.NoError

// MARK: - View Controller
final class MindfulAlertViewController: ServicesViewController, MindfulTimeSelectDelegate
{
    weak var timeDelegate : MindfulnessTimeDelegate?
    
    // MARK: - Subviews
    fileprivate let backgroundView = AlertBackgroundView.newAutoLayout()
    fileprivate let allContentContainer = UIView.newAutoLayout()
    fileprivate let contentViewContainer = UIView.newAutoLayout()
    fileprivate let reminderContainer = UIView.newAutoLayout()
    fileprivate var reminderTimeContainer : ReminderTimeViewController
    fileprivate let controlsViewContainer = UIView.newAutoLayout()

    override init(services: Services)
    {
        contentView = MindfulAlertContent(image: Asset.bell.image, text: "SET A DAILY REMINDER", detailText: "Building a mindfulness practice isn't easy. Setting a daily reminder will help.").mindfulAlertContentView
        contentViewContainer.addSubview(contentView!)
        contentView?.autoPinEdgesToSuperviewEdges()
        reminderTimeContainer = ReminderTimeViewController(services: services)
        super.init(services: services)
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
    
    let datePicker = UIDatePicker.newAutoLayout()
    
    let choosingTime = MutableProperty<Bool>(false)
    var dateOffsetConstraint : NSLayoutConstraint?
    
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
        setup()
        
        let view = UIView()
        self.view = view
        view.addSubview(backgroundView)
        backgroundView.autoPinEdgesToSuperviewEdges()
        
        view.addSubview(allContentContainer)
        allContentContainer.autoFloatInSuperview(inset: 20)
        allContentContainer.backgroundColor = .white
        
        let separatorView1 = UIView.rly_separatorView(withHeight: 1, color: UIColor.init(white: 0.91, alpha: 1.0))
        let separatorView2 = UIView.rly_separatorView(withHeight: 1, color: UIColor.init(white: 0.91, alpha: 1.0))

        allContentContainer.addSubview(contentViewContainer)
        allContentContainer.addSubview(separatorView1)
        
        addChildViewController(reminderTimeContainer)
        reminderTimeContainer.view.translatesAutoresizingMaskIntoConstraints = false
        allContentContainer.addSubview(reminderTimeContainer.view)
        reminderTimeContainer.didMove(toParentViewController: self)

        allContentContainer.addSubview(separatorView2)
        allContentContainer.addSubview(controlsViewContainer)

        contentViewContainer.autoPinEdgeToSuperview(edge: .top, inset: 30)
        contentViewContainer.autoPinEdgeToSuperview(edge: .leading, inset: 30)
        contentViewContainer.autoPinEdgeToSuperview(edge: .trailing, inset: 30)
        
        separatorView1.autoPin(edge: .top, to: .bottom, of: contentViewContainer)
        separatorView1.autoPinEdgeToSuperview(edge: .leading, inset: 30)
        separatorView1.autoPinEdgeToSuperview(edge: .trailing, inset: 30)
        
        reminderTimeContainer.view.autoPin(edge: .top, to: .bottom, of: separatorView1)
        reminderTimeContainer.view.autoPinEdgeToSuperview(edge: .leading, inset: 30)
        reminderTimeContainer.view.autoPinEdgeToSuperview(edge: .trailing, inset: 30)
        
        separatorView2.autoPin(edge: .top, to: .bottom, of: reminderTimeContainer.view)
        separatorView2.autoPinEdgeToSuperview(edge: .leading, inset: 30)
        separatorView2.autoPinEdgeToSuperview(edge: .trailing, inset: 30)
        
        controlsViewContainer.autoPin(edge: .top, to: .bottom, of: separatorView2, offset: 40)
        controlsViewContainer.autoPinEdgeToSuperview(edge: .leading, inset: 30)
        controlsViewContainer.autoPinEdgeToSuperview(edge: .trailing, inset: 30)
        controlsViewContainer.autoPinEdgeToSuperview(edge: .bottom, inset: 30)
        
        view.addSubview(datePicker)

        // set up delegate
        self.timeDelegate = reminderTimeContainer
        
        datePicker.backgroundColor = .white
        datePicker.autoPinEdgeToSuperview(edge: .leading)
        datePicker.autoPinEdgeToSuperview(edge: .trailing)
        dateOffsetConstraint = datePicker.autoPin(edge: .top, to: .bottom, of: self.view)
        
        view.addGestureRecognizer(closeGesture)
        contentView?.addGestureRecognizer(closeGesture)
        closeGesture.addTarget(self, action: #selector(self.closeAction(_:)))
        
        let actionTitle = "TURN ON"
        let dismissTitle = "NOT NOW"
        
        let dismiss = (title: dismissTitle, dismiss: true, action: { })
        let action:(()->Void) = {
            [weak self] in
                self?.services.preferences.mindfulRemindersEnabled.value = true
                self?.services.analytics.track(AnalyticsEvent.mindfulRemindersEnabled(source: "Overlay", enabled: true))
                SLogGeneric("Mindfulness reminders turned on from overlay")
        }
        
        actionGroup = .double(action: (title: actionTitle, dismiss: true, action: action), dismiss: dismiss)
        
        services.preferences.mindfulReminderAlertOnboardingState.value = true

        services.analytics.track(AnalyticsEvent.mindfulOverlayShown)
        SLogGeneric("Mindful overlay shown")
    }
    
    func closeAction(_ sender: UITapGestureRecognizer)
    {
        if choosingTime.value {
            UIView.animate(withDuration: 1, animations: {
                self.dateOffsetConstraint?.constant = 0
                self.choosingTime.value = false
            })
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        let date = Calendar.current.date(from: services.preferences.mindfulReminderTime.value) ?? Date()
        datePicker.date = date
        datePicker.datePickerMode = .time
        datePicker.addTarget(self, action: #selector(self.datePickerValueChanged(_:)), for: .valueChanged)
    }
    
    
    func datePickerValueChanged(_ sender: UIDatePicker)
    {
        self.timeDelegate?.updateTime(time: sender.date)
    }
    
    internal func showDatePicker() {
        if !choosingTime.value {
            UIView.animate(withDuration: 1, animations: {
                self.dateOffsetConstraint?.constant = -self.datePicker.frame.height
                self.choosingTime.value = true
            })
        }
        else {
            UIView.animate(withDuration: 1, animations: {
                self.dateOffsetConstraint?.constant = self.datePicker.frame.height
                self.choosingTime.value = false
            })
        }
    }
    
    /// The content to display in the alert.
    @nonobjc var content: MindfulAlertViewControllerContent?
    {
        didSet { contentView? = (content?.mindfulAlertContentView)! }
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
            let presentingViewController = self.presentingViewController
            self.dismiss(animated: false, completion: { presentingViewController!.dismiss(animated: true, completion: nil) })
        }
    }
    
    fileprivate var customDismiss: ((MindfulAlertViewController) -> ())?
    
    override var prefersStatusBarHidden: Bool
    {
        return true
    }
}

extension MindfulAlertViewController
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

extension MindfulAlertViewController: ForegroundBackgroundContentViewProviding
{
    var backgroundContentView: UIView? { return backgroundView }
    var foregroundContentView: UIView? { return allContentContainer }
}

/// Provides content for an `MindfulAlertController`.
protocol MindfulAlertViewControllerContent
{
    /// The view to display in the alert controller.
    var mindfulAlertContentView: UIView { get }
}

/// `UIView` is extended to provide alert view controller content.
extension UIView: MindfulAlertViewControllerContent
{
    /// Returns `self`.
    var mindfulAlertContentView: UIView { return self }
}


// MARK: - Action Group Extensions
extension MindfulAlertViewController.ActionGroup
{
    /// An action group that performs an action and closes the alert, or allows the user to close the alert.
    ///
    /// - Parameters:
    ///   - title: The action title.
    ///   - action: The action callback function.
    static func actionOrClose(title: String, action: @escaping () -> ()) -> MindfulAlertViewController.ActionGroup
    {
        return .double(
            action: (title: title, dismiss: true, action: action),
            dismiss: (title: tr(.close), dismiss: true, action: {})
        )
    }
    
    /// An action group that displays the string "Close", dismisses the alert, and performs no action.
    static var close: MindfulAlertViewController.ActionGroup
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
            buttonControl.useDarkAppearance()
            buttonControl.title = action.title
            buttonControl.autoSet(dimension: .height, to: 50)
            
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

extension Reactive where Base: MindfulAlertViewController
{
    /// The content to display in the alert.
    var content: BindingTarget<MindfulAlertViewControllerContent?>
    {
        return makeBindingTarget { $0.content = $1 }
    }
    
    /// The action groups to display in the alert.
    var actionGroup: BindingTarget<MindfulAlertViewController.ActionGroup?>
    {
        return makeBindingTarget { $0.actionGroup = $1 }
    }
}

// MARK: - Hiding Status Bar
private final class NoStatusBarViewController: UIViewController
{
    fileprivate override var prefersStatusBarHidden : Bool { return true }
}


struct MindfulAlertContent
{
    /// The image to display above the text content.
    let image: UIImage?
    
    /// The title text to display.
    let text: String
    
    /// The detail text to display.
    let detailText: String
}

extension MindfulAlertContent: MindfulAlertViewControllerContent
{
    var mindfulAlertContentView: UIView
    {
        let foregroundColor = UIColor(white: 0.2, alpha: 1.0)
        
        let stack = UIStackView.newAutoLayout()
        stack.alignment = .center
        stack.axis = .vertical
        stack.distribution = .equalSpacing
        stack.autoSet(dimension: .width, to: 216)
        
        // insert a spacer view at the top of the hierarchy
        func spacer(_ height: CGFloat) -> UIView
        {
            let view = UIView.newAutoLayout()
            view.autoSet(dimension: .height, to: height)
            return view
        }
        
        stack.addArrangedSubview(spacer(20))
        
        // add the image view if an image was specified
        if let image = self.image
        {
            let imageView = UIImageView()
            
            imageView.image = image.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = foregroundColor
            
            stack.addArrangedSubview(imageView)
            stack.addArrangedSubview(spacer(15))
        }
        
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
        stack.addArrangedSubview(spacer(28))
        
        return stack
    }
}

final class ReminderTimeViewController: ServicesViewController, MindfulnessTimeDelegate
{
    /// The view for setting the reminder time.
    let timeSection = ReminderTimeView.newAutoLayout()
    
    weak var changeTimeDelegate : MindfulTimeSelectDelegate?
    
    // MARK: - Initialization
    override func loadView()
    {
        let view = UIView()
        self.view = view
        view.autoSet(dimension: .height, to: 70)
        
        self.changeTimeDelegate = self.parent as! MindfulTimeSelectDelegate?
        
        let services = self.services
        
        // functions for spacer views
        func space(_ height: CGFloat) -> UIView
        {
            let view = UIView.newAutoLayout()
            view.autoSet(dimension: .height, to: height)
            return view
        }
        
        func titleLabel(_ text: String) -> UIView
        {
            let label = UILabel.newAutoLayout()
            label.textColor = .white
            label.textAlignment = .center
            label.attributedText = UIFont.gothamBook(12).track(150, text).attributedString
            return label
        }
        
        // create views for section titles and time picker
        let sectionViews = MindfulTime.sections.map({ title, mindfulTime in
            (
                titleLabel: titleLabel(title),
                mindfulTime: mindfulTime
                    .map({ mindfulTime -> (MindfulTime, ReminderTimeView) in
                        let view = timeSection
                        view.title = mindfulTime.title
                        return (mindfulTime, view)
                    })
            )
        })
        
        sectionViews.enumerated().forEach({ sectionIndex, section in
            section.mindfulTime.enumerated().forEach({ switchIndex, mindfulTime in
                view.addSubview(mindfulTime.1)
                mindfulTime.1.autoPinEdgesToSuperviewEdges()
            })
        })
        
        let dateFormat = DateFormatter(format: "h:mm a")
        let date = Calendar.current.date(from: services.preferences.mindfulReminderTime.value) ?? Date()
        let descriptionText = dateFormat.string(from: date)
        timeSection.timeSelected.attributedText = UIFont.gothamBook(12).track(150, descriptionText).attributedString
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let changing:((Any)->Void) = { [weak self] _ in
            self?.changeTimeDelegate?.showDatePicker()
        }
        timeSection.changeTimeButton.reactive.controlEvents(.touchUpInside).observe(changing)
    }
    
    internal func updateTime(time: Date) {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        let descriptionText = dateFormatter.string(from: time)
        timeSection.timeSelected.attributedText = UIFont.gothamBook(12).track(150, descriptionText).attributedString
        
        let newTime = Calendar.current.dateComponents([.hour, .minute], from: time)
        
        services.preferences.mindfulReminderTime.value = DateComponents.init(hour: newTime.hour, minute: newTime.minute)
    }
}

final class ReminderTimeView: UIView
{
    
    /// The label displaying the switch's title.
    let titleLabel = UILabel.newAutoLayout()
    
    /// The button to tap to change the time
    let changeTimeButton = UIButton.newAutoLayout()
    let timeSelected = UILabel.newAutoLayout()
    
    // MARK: - Content
    
    /// The title of the switch.
    var title: String?
        {
        get { return titleLabel.attributedText?.string }
        set
        {
            titleLabel.attributedText = newValue.map({ text in
                text.attributes(
                    font: .gothamBook(12),
                    paragraphStyle: .with(alignment: .left),
                    tracking: 150
                )
            })
        }
    }
    
    // MARK: - Initialization
    fileprivate func setup()
    {
        titleLabel.textColor = UIColor(white: 0.2, alpha: 1.0)
        titleLabel.numberOfLines = 1
        
        changeTimeButton.addSubview(timeSelected)
        changeTimeButton.showsTouchWhenHighlighted = true
        timeSelected.autoPin(edge: .top, to: .top, of: changeTimeButton)
        timeSelected.autoPin(edge: .left, to: .left, of: changeTimeButton)
        timeSelected.autoCenterInSuperview()
        timeSelected.textColor = UIColor(white: 0.2, alpha: 1.0)
        timeSelected.textAlignment = .right
        
        // center all elements vertically in this view
        [ titleLabel, changeTimeButton].forEach({ view in
            addSubview(view)
            view.autoFloatInSuperview(alignedTo: .horizontal)
        })
        
        // title label fixed size
        titleLabel.autoSet(dimension: .width, to: 130)
        titleLabel.autoPinEdgeToSuperview(edge: .leading)
        
        // the change time button has a fixed size
        changeTimeButton.autoPin(edge: .leading, to: .trailing, of: titleLabel, offset: 15)
        changeTimeButton.autoPinEdgeToSuperview(edge: .trailing)
        changeTimeButton.autoAlign(axis: .horizontal, toSameAxisOf: titleLabel)
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        setup()
    }
}
