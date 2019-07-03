import ReactiveSwift
import UIKit
import enum Result.NoError

final class OnboardingNotificationsViewController: UIViewController
{
    // MARK: - Subviews

    /// The view controller's view (typed).
    fileprivate let notificationsView = OnboardingNotificationsView()

    // MARK: - Button Producers

    /// A producer that yields a value when the user taps the button to accept notifications.
    var acceptProducer: SignalProducer<(), NoError>
    {
        return SignalProducer(notificationsView.accept.reactive.controlEvents(.touchUpInside)).void
    }

    /// A producer that yields a value when the user taps the button to decline notifications.
    var declineProducer: SignalProducer<(), NoError>
    {
        return SignalProducer(notificationsView.decline.reactive.controlEvents(.touchUpInside)).void
    }

    // MARK: - View Loading
    override func loadView()
    {
        view = notificationsView
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        animating.producer.ignore(false).take(first: 1)
            .startWithValues({ [weak notificationsView] _ in notificationsView?.graph.playAnimation() })
    }

    // MARK: - Animation
    let animating = MutableProperty(false)
}

private final class OnboardingNotificationsView: UIView
{
    // MARK: - Subviews

    /// The title label for the view.
    fileprivate let titleLabel = UILabel.newAutoLayout()

    /// The description label for the view.
    fileprivate let descriptionLabel = UILabel.newAutoLayout()

    /// The view displayed in the center of the view controller.
    let graph = OnboardingGraphView(frame: .zero)

    /// The button to accept notifications.
    let accept = ButtonControl.newAutoLayout()

    /// The button to decline notifications.
    let decline = LinkControl.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        // add title label to top of view
        titleLabel.attributedText = tr(.onboardingNotificationsTitle).attributedOnboardingTitleString
        titleLabel.numberOfLines = 2
        addSubview(titleLabel)

        titleLabel.autoPinEdgeToSuperview(edge: .top)
        titleLabel.autoFloatInSuperview(alignedTo: .vertical)

        // add center content
        addSubview(graph)

        // add description label to bottom of view
        descriptionLabel.attributedText = tr(.onboardingNotificationsDescription).attributedOnboardingDetailString
        descriptionLabel.numberOfLines = 0
        addSubview(descriptionLabel)

        descriptionLabel.autoAlignAxis(toSuperviewAxis: .vertical)

        [titleLabel, descriptionLabel].forEach({
            $0.autoSet(dimension: .width, to: 310, relation: .lessThanOrEqual)
            $0.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
            $0.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        })

        // add confirmation button
        accept.title = tr(.onboardingNotificationsAccept)
        addSubview(accept)

        accept.autoSetDimensions(to: CGSize(width: 300, height: 51))
        accept.autoAlignAxis(toSuperviewAxis: .vertical)
        accept.autoPin(edge: .top, to: .bottom, of: descriptionLabel, offset: 30)

        // add decline button
        decline.font.value = UIFont.gothamMedium(12)
        decline.text.value = tr(.onboardingNotificationsDecline)
        addSubview(decline)

        decline.autoPin(edge: .top, to: .bottom, of: accept)
        decline.autoPinEdgeToSuperview(edge: .bottom, inset: -15)
        decline.autoAlignAxis(toSuperviewAxis: .vertical)
        decline.autoSetDimensions(to: CGSize(width: 258, height: 56))
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

    // MARK: - Layout
    fileprivate override func layoutSubviews()
    {
        super.layoutSubviews()

        // place graph between top content and bottom content, with padding
        let topBound = titleLabel.frame.offsetBy(dx: 0, dy: 40).maxY
        let bottomBound = descriptionLabel.frame.offsetBy(dx: 0, dy: -10).minY

        // ensure that graph is inset a minimum amount
        let size = bounds.size
        let inset: CGFloat = 45

        // the rect that the graph should fit inside
        graph.frame = CGRect(x: inset, y: topBound, width: size.width - inset * 2, height: bottomBound - topBound)
    }
}
