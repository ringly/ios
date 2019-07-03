import ReactiveSwift
import RinglyExtensions
import RinglyKit
import PureLayout
import UIKit
import enum Result.NoError

/// Displays mindfulness settings
final class MindfulnessSettingsViewController : ServicesViewController, MindfulTimeSelectDelegate
{
    // MARK: - Subviews
    fileprivate let scrollView = UIScrollView.newAutoLayout()
    fileprivate let stack = UIStackView.newAutoLayout()

    let closeView = UIView.newAutoLayout()
    let datePicker = UIDatePicker.newAutoLayout()
    let closeGesture = UITapGestureRecognizer()
    
    let choosingTime = MutableProperty<Bool>(false)
    var dateOffsetConstraint : NSLayoutConstraint?

    // adds empty content to allow scroll view to work on larger phones
    let goalSpacerView = UIView.newAutoLayout()
    let spacerView = UIView.newAutoLayout()

    weak var timeDelegate : MindfulnessTimeDelegate?
    
    override func loadView()
    {
        // set up the base view
        self.view = GradientView.mindfulnessGradientView
        
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
        
        view.addSubview(datePicker)
        datePicker.backgroundColor = .white
        datePicker.autoPinEdgeToSuperview(edge: .leading)
        datePicker.autoPinEdgeToSuperview(edge: .trailing)
        dateOffsetConstraint = datePicker.autoPin(edge: .top, to: .bottom, of: scrollView, offset: 0)

        // create sub-controllers
        let goal = MindfulMinuteGoalViewController(services: services)
        let switches = MindfulSwitchViewController(services: services)
        let reminderTime = MindfulTimeViewController(services: services)

        // set up delegate
        self.timeDelegate = reminderTime

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
        let descriptionText = "Set a goal to de-stress with mindfulness exercises."
        descriptionLabel.attributedText = UIFont.gothamBook(16).track(150, descriptionText).attributedString
        
        
        // vertically, always start with the goal and switches view controllers
        let viewControllers: [UIViewController] = [
            goal,
            switches,
            reminderTime
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

        let separatorView = UIView.rly_separatorView(withHeight: 1, color: UIColor.white.withAlphaComponent(0.5))
        
        addEither(PreferencesEither.left(switches))
        addEither(PreferencesEither.right(separatorView))
        addEither(PreferencesEither.left(reminderTime))
        
        spacerView.autoSet(dimension: .height, to: CGFloat(datePicker.frame.height))
        addEither(PreferencesEither.right(spacerView))
        spacerView.isHidden = true
        
        stack.addGestureRecognizer(closeGesture)
        closeGesture.addTarget(self, action: #selector(self.closeAction(_:)))
        
        services.preferences.mindfulRemindersEnabled.producer.take(until: reactive.lifetime.ended)
            .startWithValues({ [weak self] current in
                switch current
                {
                case true:
                    self?.services.analytics.track(AnalyticsEvent.mindfulRemindersEnabled(source: "Settings", enabled: true))
                    UIView.animate(withDuration: 0.1, animations: {
                        // index 6 contains separator, 7 contains the choose time view
                        self?.stack.arrangedSubviews[6].alpha = 1
                        self?.stack.arrangedSubviews[7].alpha = 1
                    })
                case false:
                    self?.services.analytics.track(AnalyticsEvent.mindfulRemindersEnabled(source: "Settings", enabled: false))
                    UIView.animate(withDuration: 0.3, animations: {
                        self?.stack.arrangedSubviews[6].alpha = 0
                        self?.stack.arrangedSubviews[7].alpha = 0
                        self?.scrollView.contentOffset = CGPoint.zero
                        self?.dateOffsetConstraint?.constant = 0
                        self?.choosingTime.value = false
                    })
                }
            })

        services.analytics.track(AnalyticsEvent.viewedScreen(name: .mindfulnessSettings))
        SLogGeneric("Visited Mindfulness Settings Screen")
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()
        let date = Calendar.current.date(from: services.preferences.mindfulReminderTime.value) ?? Date()
        datePicker.date = date
        datePicker.datePickerMode = .time
        datePicker.addTarget(self, action: #selector(self.datePickerValueChanged(_:)), for: .valueChanged)
        
        NotificationCenter.default.addObserver(self, selector: #selector(viewWillDisappear(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        self.dismiss(animated: true, completion: nil)
    }
    
    func datePickerValueChanged(_ sender: UIDatePicker)
    {
        self.timeDelegate?.updateTime(time: sender.date)
    }
    
    override var prefersStatusBarHidden: Bool
    {
        return true
    }
    

    func closeAction(_ sender:UITapGestureRecognizer)
    {
        if choosingTime.value {
            UIView.animate(withDuration: 0.5, animations: {
                self.spacerView.isHidden = true
                self.scrollView.contentOffset = CGPoint.zero
                self.dateOffsetConstraint?.constant = 0
                self.choosingTime.value = false
            })
        }
    }
    
    internal func showDatePicker() {
        if !choosingTime.value {
            UIView.animate(withDuration: 0.5, animations: {
                self.spacerView.isHidden = false
                self.scrollView.contentOffset = CGPoint.init(x: 0, y: self.datePicker.frame.height)
                self.dateOffsetConstraint?.constant = -self.datePicker.frame.height
                self.choosingTime.value = true
            })
        }
    }
}

protocol MindfulTimeSelectDelegate : class
{
    func showDatePicker()
}

final class BellSeparatorView : UIView
{
    fileprivate let imageView = UIImageView.newAutoLayout()
    func setup()
    {
        addSubview(imageView)
        imageView.image = UIImage(asset: .bell).withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .white
        imageView.autoAlignAxis(toSuperviewAxis: .vertical)
        imageView.autoAlignAxis(toSuperviewAxis: .horizontal)
        
        let separatorLeft = UIView.newAutoLayout()
        let separatorRight = UIView.newAutoLayout()
        
        let separators = [separatorLeft, separatorRight]
        separators.forEach({ line in
            line.autoSet(dimension: .height, to: 1)
            line.backgroundColor = .white
            addSubview(line)
            line.alpha = 0.5
            line.autoAlignAxis(toSuperviewAxis: .horizontal)
        })
        
        separatorLeft.autoPinEdgeToSuperview(edge: .leading)
        imageView.autoPin(edge: .left, to: .right, of: separatorLeft, offset: 20)
        separatorRight.autoPin(edge: .left, to: .right, of: imageView, offset: 20)
        separatorRight.autoPinEdgeToSuperview(edge: .trailing)
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

