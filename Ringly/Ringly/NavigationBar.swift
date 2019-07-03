import ReactiveSwift
import RinglyExtensions
import UIKit
import enum Result.NoError


final class NavigationBar: UIView
{
    
    // MARK: - Content
    enum Title {
        case text(String)
        case image(image: UIImage?, accessibilityLabel: String)
        case textWithIcon(text: String, view: UIView?)
        case textWithSubtitle(text: String, subtitle: String, pullProgress: Double)
        
        var textValue:String? {
            switch self {
            case .text(let text):
                return text
            default:
                return nil
            }
        }
        
        var subtitleTextValue:String? {
            switch self {
            case let .textWithSubtitle(_, subtitle, _):
                return subtitle
            default:
                return nil
            }
        }
        
        var imageValue:UIImage? {
            switch self {
            case .image(let image, _):
                return image
            default:
                return nil
            }
        }
        
        var accessibilityLabel:String? {
            switch self {
            case .text(let text):
                return text
            case .textWithIcon(text: let text, _):
                return text
            case .image(_, let accessibilityLabel):
                return accessibilityLabel
            case .textWithSubtitle(let text, let subtitle, _):
                return "\(text) \(subtitle)"
            }
        }
    }

    // MARK: - Layout

    /// The standard navigation bar height.
    @nonobjc static let standardHeight: CGFloat = 80

    /// The title displayed by the navigation bar.
    let title = MutableProperty(Title?.none)

    /// Whether the navigation bar should display a "back" button.
    let backAvailable = MutableProperty(false)

    /// The content for the action button.
    let action = MutableProperty(Title?.none)

    // MARK: - Animation
    var animateTitleChanges = true

    // MARK: - Buttons
    fileprivate let backButton = UIButton.newAutoLayout()
    fileprivate let actionButton = UIButton.newAutoLayout()

    /// The transform applied to the action button.
    var actionButtonTransform: CGAffineTransform
    {
        get { return actionButton.transform }
        set { actionButton.transform = newValue }
    }

    /// When set to `true`, a bouncing prompt arrow will be displayed next to the action button.
    let showBouncingArrow = MutableProperty(false)

    // MARK: - Initialization
    fileprivate func setup()
    {
        // add back button
        backButton.setImage(UIImage(asset: .navigationBackArrow), for: UIControlState())
        backButton.accessibilityLabel = "Back"
        backButton.showsTouchWhenHighlighted = true
        addSubview(backButton)

        backButton.autoPinEdgeToSuperview(edge: .top)
        backButton.autoPinEdgeToSuperview(edge: .bottom)
        backButton.autoSet(dimension: .width, to: 50)

        let backButtonShown = backButton.autoPinEdgeToSuperview(edge: .left)
        let backButtonHidden = backButton.autoPin(edge: .right, to: .left, of: self)

        backAvailable.producer.startWithValues({ [weak self] shown in
            self?.backButton.isUserInteractionEnabled = shown
            self?.backButton.isAccessibilityElement = shown

            NSLayoutConstraint.conditionallyActivateConstraints([
                (backButtonShown, shown), (backButtonHidden, !shown)
            ])
        })

        // add action button
        actionButton.showsTouchWhenHighlighted = true
        addSubview(actionButton)

        actionButton.autoPinEdgeToSuperview(edge: .top)
        actionButton.autoPinEdgeToSuperview(edge: .bottom)
        actionButton.autoSet(dimension: .width, to: 50)

        let actionButtonShown = actionButton.autoPinEdgeToSuperview(edge: .right, inset: 16)
        let actionButtonHidden = actionButton.autoPin(edge: .left, to: .right, of: self)

        action.producer.startWithValues({ [weak self] action in
            let shown = action != nil

            NSLayoutConstraint.conditionallyActivateConstraints([
                (actionButtonShown, shown), (actionButtonHidden, !shown)
            ])

            self?.actionButton.setAttributedTitle((action?.textValue).map({ text in
                UIFont.gothamBook(16).track(150, text).attributes(color: .white)
            }), for: .normal)

            self?.actionButton.setImage(action?.imageValue, for: .normal)
            self?.actionButton.accessibilityLabel = action?.accessibilityLabel

            self?.actionButton.isUserInteractionEnabled = shown
            self?.actionButton.isAccessibilityElement = shown
        })

        title.producer.skip(while: { $0 == nil }).start(
            first: { [weak self] title in self?.update(title) },
            following: { [weak self] title in
                guard let strong = self else { return }
                strong.update(title, animatedFor: strong.animateTitleChanges ? 0.25 : nil)
            }
        )

        showBouncingArrow.producer.skipRepeats()
            .map({ $0 ? NavigationBarBouncingArrowView.newAutoLayout() : Optional.none })
            .combinePrevious(nil)
            .startWithValues({ [weak self] previous, current in
                previous?.removeFromSuperview()

                if let view = current, let strong = self
                {
                    strong.addSubview(view)

                    view.autoSet(dimension: .width, to: 40)
                    view.autoPinEdgeToSuperview(edge: .top)
                    view.autoPinEdgeToSuperview(edge: .bottom)
                    view.autoPin(edge: .right, to: .left, of: strong.actionButton)
                }
            })
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

    // MARK: - Producers
    var backProducer: SignalProducer<(), NoError>
    {
        return SignalProducer(backButton.reactive.controlEvents(.touchUpInside)).void
    }

    var actionProducer: SignalProducer<(), NoError>
    {
        return SignalProducer(actionButton.reactive.controlEvents(.touchUpInside)).void
    }

    // MARK: - Updating Title Content
    var currentTitleView: UIView?

    fileprivate func update(_ title: Title?, animatedFor animationDuration: TimeInterval? = nil)
    {
        
        if let text = title?.textValue, let label = currentTitleView as? UILabel, animationDuration == nil
        {
            label.attributedText = text.navigationBarTitleAttributedString
        }
        else {
            // create new title view, obtain old title view
            let oldTitleView = currentTitleView
            let titleView = title.map(self.titleView)
            currentTitleView = titleView

            // add the new title view to the center of the view
            if let view = titleView
            {
                addSubview(view)
                view.autoCenterInSuperview()
                view.autoPin(edge: .left, to: .right, of: backButton, offset: 10, relation: .greaterThanOrEqual)
                view.autoPin(edge: .right, to: .left, of: actionButton, offset: -10, relation: .lessThanOrEqual)
            }

            if let duration = animationDuration
            {
                layoutIfNeeded()
                titleView?.alpha = 0

                UIView.animate(withDuration: duration, animations: {
                    UIView.setAnimationCurve(.linear)
                    titleView?.alpha = 1
                    oldTitleView?.alpha = 0
                }, completion: { _ in oldTitleView?.removeFromSuperview() })
            }
            else
            {
                oldTitleView?.removeFromSuperview()
            }
        }
    }

    fileprivate func titleView(for title: Title) -> UIView
    {
        switch title
        {
        case let .textWithSubtitle(text, subtitle, pullProgress):
            let titleSubtitleView = TitleSubtitleView.newAutoLayout()
            titleSubtitleView.title = text
            titleSubtitleView.subtitle = subtitle
            titleSubtitleView.progress.value = pullProgress
            
            
            return titleSubtitleView
        case let .text(text):
            let label = UILabel.newAutoLayout()
            label.textAlignment = .center
            label.textColor = .white
            label.attributedText = text.navigationBarTitleAttributedString

            return label

        case let .image(image, accessibilityLabel):
            let imageView = UIImageView.newAutoLayout()
            imageView.image = image
            imageView.isAccessibilityElement = true
            imageView.accessibilityLabel = accessibilityLabel

            return imageView
        case let .textWithIcon(text, view):
            let iconView = UIStackView.newAutoLayout()
            iconView.axis = .horizontal
            iconView.spacing = 10.0
            iconView.alignment = .center
            
            if let view = view {
                iconView.addArrangedSubview(view)
            }
            
            let label = UILabel.newAutoLayout()
            label.textAlignment = .center
            label.textColor = .white
            label.attributedText = text.navigationBarTitleAttributedString
            iconView.addArrangedSubview(label)
            
            return iconView
        }
    }
}

extension String
{
    fileprivate var navigationBarTitleAttributedString: NSAttributedString
    {
        return UIFont.gothamBook(15).track(250, self).attributedString
    }
    
    fileprivate var navigationBarSubtitleAttributedString: NSAttributedString
    {
        return attributes(color: nil, font: UIFont.gothamBook(12), paragraphStyle: .with(alignment: .center, lineSpacing: 3), tracking: 250)
    }
}

private final class NavigationBarBouncingArrowView: DisplayLinkView
{
    // MARK: - Initialization
    fileprivate let arrow = UIImageView.newAutoLayout()

    fileprivate func setup()
    {
        arrow.image = UIImage(asset: .onboardingArrow)

        addSubview(arrow)
        arrow.autoAlignAxis(toSuperviewAxis: .horizontal)
        arrow.autoPinEdgeToSuperview(edge: .right)
        arrow.autoConstrainSize()
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

    override func displayLinkCallback(_ displayLink: CADisplayLink)
    {
        let sine = sin(fmod(displayLink.timestamp, M_PI * 2) * 4) - 1
        arrow.transform = CGAffineTransform(translationX: CGFloat(sine * 10), y: 0)
    }
}

private final class TitleSubtitleView: UIView
{
    private let label = UILabel.newAutoLayout()
    private let subtitleLabel = UILabel.newAutoLayout()
    private var subtitleTitleOffsetConstraint:NSLayoutConstraint?
    
    let progress = MutableProperty<Double>(0.0)
    
    var title:String? {
        didSet {
            self.label.attributedText = title!.navigationBarTitleAttributedString
        }
    }
    
    var subtitle:String? {
        didSet {
            self.subtitleLabel.attributedText = subtitle!.navigationBarSubtitleAttributedString
        }
    }

    fileprivate func setup()
    {
        label.textAlignment = .center
        label.textColor = .white
        addSubview(label)
        label.autoCenterInSuperview()
        
        subtitleLabel.textColor = .white
        subtitleLabel.textAlignment = .center
        subtitleLabel.alpha = 0
        subtitleLabel.numberOfLines = 0
        
        let subtitleStartingOffset:Double = 20.0
        let subtitleOffset:Double = 9.0

        addSubview(subtitleLabel)
        subtitleLabel.autoAlign(axis: .vertical, toSameAxisOf: label)
        subtitleTitleOffsetConstraint = subtitleLabel.autoPin(edge: .top, to: .bottom, of: label, offset: CGFloat(subtitleStartingOffset))
        
        progress.producer.startWithValues({ [weak self] progress in
            self?.subtitleLabel.alpha = CGFloat(progress)
            
            let adjustedOffset = (subtitleStartingOffset - subtitleOffset) * progress
            
            self?.subtitleTitleOffsetConstraint?.constant = CGFloat(subtitleStartingOffset.subtracting(adjustedOffset))
        })
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
