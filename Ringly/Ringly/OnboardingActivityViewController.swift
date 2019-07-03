import ReactiveSwift
import UIKit
import enum Result.NoError

final class OnboardingActivityViewController: UIViewController
{
    // MARK: - Subviews
    fileprivate let center = CenterView.newAutoLayout()

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        // add title label to top of view
        let title = UILabel.newAutoLayout()
        title.attributedText = tr(.onboardingActivityTitle).attributedOnboardingTitleString
        title.numberOfLines = 2
        view.addSubview(title)

        title.autoPinEdgeToSuperview(edge: .top)
        title.autoFloatInSuperview(alignedTo: .vertical)

        // add center content
        view.addSubview(center)
        center.autoFloatInSuperview()
        center.autoPin(edge: .top, to: .bottom, of: title, offset: 10, relation: .greaterThanOrEqual)

        // add description label to bottom of view
        let description = UILabel.newAutoLayout()
        description.attributedText = tr(.onboardingActivityDescription).attributedOnboardingDetailString
        description.numberOfLines = 0
        view.addSubview(description)

        description.autoFloatInSuperview(alignedTo: .vertical)
        description.autoSet(dimension: .width, to: 298)
        description.autoPinEdgeToSuperview(edge: .bottom)
        description.autoPin(edge: .top, to: .bottom, of: center, offset: 10, relation: .greaterThanOrEqual)

        [title, description].forEach({
            $0.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
            $0.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        })
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        let animationTriggers = animating.producer.skipRepeats().flatMap(.latest, transform: { animating in
            animating ? timer(interval: .seconds(5), on: QueueScheduler.main).void : SignalProducer.empty
        })

        animationTriggers.take(until: reactive.lifetime.ended).startWithValues({ [weak self] in
            _ = self?.centerContent.pureModify({ $0.next })
        })

        centerContent.producer
            .map({ $0.content })
            .flatMap(.merge, transform: { [weak self] content in
                self?.center.transitionTo(content).concat(content.animationProducer) ?? SignalProducer.empty
            })
            .take(until: reactive.lifetime.ended)
            .start()
    }

    // MARK: - Animation

    /// Whether or not the view should animate between subviews.
    let animating = MutableProperty(false)

    fileprivate enum CenterContent { case steps, calories, distance }
    fileprivate let centerContent = MutableProperty(CenterContent.steps)
}

extension OnboardingActivityViewController.CenterContent
{
    fileprivate var content: CenterView.Content
    {
        switch self
        {
        case .steps:
            return CenterView.Content(
                title: trUpper(.steps),
                view: OnboardingStepsView.newAutoLayout(),
                widthMultiplier: 1,
                animationProducer: timer(interval: .seconds(5), on: QueueScheduler.main).take(first: 1).void
            )

        case .calories:
            return CenterView.Content(
                title: trUpper(.calories),
                view: OnboardingCaloriesView.newAutoLayout(),
                widthMultiplier: 1,
                animationProducer: timer(interval: .seconds(5), on: QueueScheduler.main).take(first: 1).void
            )

        case .distance:
            let map = OnboardingMapView.newAutoLayout()

            return CenterView.Content(
                title: trUpper(.distance),
                view: map,
                widthMultiplier: 0.6921568627,
                animationProducer: map.animationProducer().delay(2, on: QueueScheduler.main)
            )
        }
    }

    fileprivate var next: OnboardingActivityViewController.CenterContent
    {
        switch self
        {
        case .steps: return .distance
        case .distance: return .calories
        case .calories: return .steps
        }
    }
}

private final class CenterView: UIView
{
    // MARK: - Subviews

    /// The outer circle provides a white border.
    fileprivate let outerCircle = UIView.newAutoLayout()

    /// The inner circle provides a purple background.
    fileprivate let innerCircle = UIView.newAutoLayout()

    /// The label displays a text description of the current circle content.
    fileprivate let label = UILabel.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        // add outer circle to root
        outerCircle.backgroundColor = .white
        addSubview(outerCircle)

        outerCircle.autoPinEdgeToSuperview(edge: .top)
        outerCircle.autoFloatInSuperview(alignedTo: .vertical)
        outerCircle.autoMatch(dimension: .width, to: .height, of: outerCircle)

        // add inner circle to outer circle
        innerCircle.clipsToBounds = true
        innerCircle.backgroundColor = UIColor(red: 0.8033, green: 0.5522, blue: 0.818, alpha: 1.0)
        addSubview(innerCircle)

        innerCircle.autoAlign(axis: .horizontal, toSameAxisOf: outerCircle)
        innerCircle.autoAlign(axis: .vertical, toSameAxisOf: outerCircle)
        innerCircle.autoMatch(dimension: .width, to: .height, of: innerCircle)
        innerCircle.autoMatch(dimension: .width, to: .width, of: outerCircle, multiplier: 0.9125)

        // ensure circle size is as large as possible
        outerCircle.autoSet(dimension: .width, to: 280, relation: .lessThanOrEqual)

        NSLayoutConstraint.autoSet(priority: UILayoutPriorityDefaultHigh, forConstraints: {
            (10...280).forEach({ width in
                outerCircle.autoSet(dimension: .width, to: CGFloat(width), relation: .greaterThanOrEqual)
            })
        })

        // add label
        label.textColor = .white
        addSubview(label)

        label.autoPinEdgeToSuperview(edge: .bottom)
        label.autoFloatInSuperview(alignedTo: .vertical)
        label.autoPin(edge: .top, to: .bottom, of: outerCircle, offset: 29)
        label.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
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

        outerCircle.layer.cornerRadius = outerCircle.bounds.size.width / 2
        innerCircle.layer.cornerRadius = innerCircle.bounds.size.width / 2
    }

    // MARK: - Content
    struct Content
    {
        let title: String
        let view: UIView
        let widthMultiplier: CGFloat
        let animationProducer: SignalProducer<(), NoError>
    }

    let content = MutableProperty(Content?.none)

    fileprivate var currentContent: Content?

    func transitionTo(_ content: Content) -> SignalProducer<(), NoError>
    {
        let duration = 0.25

        return SignalProducer.`defer` { [weak self] in
            guard let strong = self else { return SignalProducer.empty }

            let title = UIFont.gothamBook(18).track(350, content.title).attributedString

            // add the new content
            strong.innerCircle.addSubview(content.view)
            content.view.autoCenterInSuperview()
            content.view.autoMatch(
                dimension: .width,
                to: .width,
                of: strong.innerCircle,
                multiplier: content.widthMultiplier
            )

            // swap content var
            let maybePrevious = strong.currentContent
            strong.currentContent = content

            // if we have previous content, perform an animation
            if let previous = maybePrevious
            {
                let width = strong.innerCircle.bounds.size.width
                content.view.transform = CGAffineTransform(translationX: width, y: 0)

                let transitionContent = UIView.animationProducer(duration: duration, animations: {
                    content.view.transform = .identity
                    previous.view.transform = CGAffineTransform(translationX: -width, y: 0)
                }).void.on(completed: previous.view.removeFromSuperview)

                let transitionLabel = UIView.transitionProducer(
                    view: strong.label,
                    duration: duration,
                    options: .transitionCrossDissolve,
                    animations: { strong.label.attributedText = title }
                ).void

                return SignalProducer.merge(transitionContent, transitionLabel)
            }
            else
            {
                strong.label.attributedText = title
                return SignalProducer.empty
            }
        }
    }
}
