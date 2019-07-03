import ReactiveSwift
import UIKit
import enum Result.NoError

final class OnboardingAppsViewController: UIViewController
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
        title.attributedText = tr(.onboardingAppsTitle).attributedOnboardingTitleString
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
        description.attributedText = tr(.onboardingAppsDescription).attributedOnboardingDetailString
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

    // MARK: - Animation
    func startAnimation()
    {
        animateWith(0)
    }

    fileprivate func animateWith(_ offset: Int)
    {
        let app = animationApps[offset % animationApps.count]

        center.appIcons.transitionTo(UIImage(asset: app.asset))
            .then(center.animateDots())
            .then(center.vibrateRing())
            .then(center.flash(app.color.onboardingDemoColor))
            .delay(1, on: QueueScheduler.main)
            .startWithCompleted({ [weak self] in
                self?.animateWith(offset + 1)
            })
    }

    fileprivate let animationApps = [
        (asset: Asset.onboardingAppIconPhone, color: DefaultColor.blue),
        (asset: Asset.onboardingAppIconMessages, color: DefaultColor.green),
        (asset: Asset.onboardingAppIconMail, color: DefaultColor.yellow),
        (asset: Asset.onboardingAppIconCalendar, color: DefaultColor.red)
    ]
}

/// A view containing the center content for `OnboardingAppsViewController`.
private final class CenterView: UIView
{
    // MARK: - Subviews

    /// The app icons view, which can play an animation of an app icon.
    let appIcons = AppIconsView.newAutoLayout()

    /// The phone displaying `appIcons`.
    let phone = PhoneView.newAutoLayout()

    /// The dots between the phone and the ring.
    let dots = (0..<5).map({ _ in UIView.newAutoLayout() })

    /// The ring, which displays alerts and vibrates.
    let ring = OnboardingRingView.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        // add phone view
        addSubview(phone)
        phone.autoPinEdgeToSuperview(edge: .top)
        phone.autoPinEdgeToSuperview(edge: .left)

        // maximum size for phone on large displays
        phone.autoSet(dimension: .width, to: 121, relation: .lessThanOrEqual)
        phone.autoSet(dimension: .height, to: 234, relation: .lessThanOrEqual)

        // make phone as large as possible
        NSLayoutConstraint.autoSet(priority: UILayoutPriorityDefaultHigh, forConstraints: {
            (11...121).forEach({ offset in
                phone.autoSet(dimension: .width, to: CGFloat(offset), relation: .greaterThanOrEqual)
            })
        })

        phone.autoSet(dimension: .width, to: 10, relation: .greaterThanOrEqual)

        // add app icons view to phone screen
        phone.screen.addSubview(appIcons)
        appIcons.autoPinEdgesToSuperviewEdges()

        // add ring view
        addSubview(ring)

        ring.autoPinEdgeToSuperview(edge: .right)
        ring.autoMatch(dimension: .width, to: .width, of: phone, multiplier: 0.5619834711)
        ring.autoAlign(axis: .horizontal, toSameAxisOf: phone)

        // add dots between the phone and ring
        dots.forEach({ dot in
            dot.alpha = 0
            dot.backgroundColor = .white
            addSubview(dot)

            dot.autoMatch(dimension: .width, to: .height, of: dot)
            dot.autoMatch(dimension: .width, to: .width, of: phone, multiplier: 0.04132231405)
            dot.autoAlign(axis: .horizontal, toSameAxisOf: phone)
        })

        // add shadow views below ring and phone
        let shadows = (
            phone: OnboardingShadowView.newAutoLayout(),
            ring: OnboardingShadowView.newAutoLayout()
        )

        addSubview(shadows.phone)
        addSubview(shadows.ring)

        shadows.phone.autoAlign(axis: .vertical, toSameAxisOf: phone)
        shadows.phone.autoPinEdgeToSuperview(edge: .bottom)

        shadows.ring.autoAlign(axis: .horizontal, toSameAxisOf: shadows.phone)
        shadows.ring.autoAlign(axis: .vertical, toSameAxisOf: ring)

        [shadows.phone, shadows.ring].forEach({ shadow in
            shadow.autoMatch(dimension: .width, to: .width, of: phone, multiplier: 0.7892561983)
            shadow.autoMatch(dimension: .height, to: .width, of: shadow, multiplier: 0.05583756345)
        })

        let shadowSpacer = UIView.newAutoLayout()
        addSubview(shadowSpacer)

        shadowSpacer.autoPin(edge: .top, to: .bottom, of: phone)
        shadowSpacer.autoPin(edge: .bottom, to: .top, of: shadows.phone)
        shadowSpacer.autoMatch(dimension: .height, to: .width, of: phone, multiplier: 0.3140495868)

        // create views to evenly space the horizontal content
        let horizontalViews = [phone] + dots + [ring]

        let spacerViews = zip(horizontalViews.dropLast(), horizontalViews.dropFirst()).map({ left, right -> UIView in
            let spacer = UIView.newAutoLayout()
            addSubview(spacer)

            spacer.autoPin(edge: .left, to: .right, of: left)
            spacer.autoPin(edge: .right, to: .left, of: right)

            return spacer
        })

        (spacerViews as NSArray).autoMatchViews(dimension: .width)

        spacerViews.first?.autoMatch(dimension: .width, to: .width, of: phone, multiplier: 0.04132231405)
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

        // set the corner radii of the dots
        dots.forEach({ $0.layer.cornerRadius = $0.bounds.size.width / 2 })
    }

    // MARK: - Animation
    
    func animateDots() -> SignalProducer<(), NoError>
    {
        let delayDuration: Int = 5
        let fadeDuration: TimeInterval = 0.1
        let holdDuration: TimeInterval = 0.2

        return SignalProducer.merge(
            dots.enumerated().map({ index, dot in
                timer(interval: .milliseconds(index * delayDuration), on: QueueScheduler.main)
                    .take(first: 1)
                    .then(UIView.animationProducer(duration: fadeDuration, animations: { dot.alpha = 1 }))
                    .delay(holdDuration, on: QueueScheduler.main)
                    .then(UIView.animationProducer(duration: fadeDuration, animations: { dot.alpha = 0 }))
                    .void
            })
        )
    }

    
    func vibrateRing() -> SignalProducer<(), NoError>
    {
        let duration: DispatchTimeInterval = .milliseconds(500)

        return SignalProducer.`defer` { [weak ring] in
            ring?.rly_wiggle(withMoves: 8, distance: CGSize(width: 2, height: 0), duration: 0.5)
            return timer(interval: duration, on: QueueScheduler.main).take(first: 1).void
        }
    }

    
    func flash(_ color: UIColor) -> SignalProducer<(), NoError>
    {
        let fadeDuration: TimeInterval = 0.25
        let holdDuration: TimeInterval = 0.25

        return SignalProducer.`defer` { [weak self] in
            guard let strong = self else { return SignalProducer.empty }

            // add a light view to the view hierarchy
            let light = OnboardingLightView.newAutoLayout()
            light.color = color
            light.alpha = 0
            strong.ring.addSubview(light)

            // set the size of the light
            light.autoMatch(dimension: .width, to: .width, of: strong.phone, multiplier: 0.2323651452)
            light.autoMatch(dimension: .width, to: .height, of: light, multiplier: 0.9285714286)

            // pin the light to the ring
            light.autoConstrain(attribute: .horizontal, to: .bottom, of: strong.ring, multiplier: 0.21)
            light.autoConstrain(attribute: .left, to: .right, of: strong.ring, multiplier: 0.89)

            // animate the light in and out
            return UIView.animationProducer(duration: fadeDuration, animations: { light.alpha = 1 })
                .delay(holdDuration, on: QueueScheduler.main)
                .then(UIView.animationProducer(duration: fadeDuration, animations: { light.alpha = 0 }))
                .void
                .on(completed: { light.removeFromSuperview() })
        }
    }
}

private final class AppIconsView: UIView
{
    // MARK: - Subviews
    fileprivate let primaryIconContainer = UIView.newAutoLayout()
    fileprivate let secondaryIconContainer = UIView.newAutoLayout()
    fileprivate let primaryIcon = UIImageView.newAutoLayout()
    fileprivate let secondaryIcon = UIImageView.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        // add icons to containers
        primaryIconContainer.addSubview(primaryIcon)
        secondaryIconContainer.addSubview(secondaryIcon)

        // fixed layout of icons and containers
        [primaryIconContainer, secondaryIconContainer].forEach({ container in
            addSubview(container)
            container.autoMatch(dimension: .width, to: .width, of: self)
            container.autoPinEdgeToSuperview(edge: .top)
            container.autoPinEdgeToSuperview(edge: .bottom)
        })

        [primaryIcon, secondaryIcon].forEach({ icon in
            icon.autoMatch(dimension: .width, to: .width, of: self, multiplier: 0.4181818182)
            icon.autoMatch(dimension: .width, to: .height, of: icon)
            icon.autoCenterInSuperview()
        })

        primaryIconContainer.autoPinEdgeToSuperview(edge: .left)
        secondaryIconContainer.autoPin(edge: .left, to: .right, of: primaryIconContainer)
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

    // MARK: - Animation
    
    func transitionTo(_ icon: UIImage?) -> SignalProducer<(), NoError>
    {
        let initialIconChange = SignalProducer<(), NoError>.`defer` { [weak self] in
            self?.secondaryIcon.image = icon
            return SignalProducer.empty
        }

        let slideIcons = UIView.animationProducer(duration: 0.25, animations: { [weak self] in
            guard let strong = self else { return }
            let transform = CGAffineTransform(translationX: -strong.bounds.size.width, y: 0)
            strong.primaryIconContainer.transform = transform
            strong.secondaryIconContainer.transform = transform
        })

        let finalize = SignalProducer<(), NoError>.`defer` { [weak self] in
            // move icon to primary image view
            self?.primaryIcon.image = icon
            self?.secondaryIcon.image = nil

            // reset layout
            self?.primaryIconContainer.transform = CGAffineTransform.identity
            self?.secondaryIconContainer.transform = CGAffineTransform.identity

            return SignalProducer.empty
        }

        return initialIconChange.then(slideIcons).then(finalize)
    }
}

/// A view to draw the phone in `OnboardingAppsViewController`.
private final class PhoneView: UIView
{
    // MARK: - Subviews
    let screen = UIImageView.newAutoLayout()
    let button = UIView.newAutoLayout()

    let phoneMask = CAShapeLayer()

    // MARK: - Initialization
    fileprivate func setup()
    {
        backgroundColor = .white
        layer.mask = phoneMask
        phoneMask.fillRule = kCAFillRuleEvenOdd

        // fixed aspect ratio for phone
        autoMatch(dimension: .width, to: .height, of: self, multiplier: 0.5170940171)

        // add screen to phone
        screen.image = UIImage(asset: .onboardingAppsPhoneBackground)
        screen.layer.masksToBounds = true
        addSubview(screen)

        screen.autoAlignAxis(toSuperviewAxis: .vertical)
        screen.autoConstrain(attribute: .top, to: .bottom, of: self, multiplier: 0.09615384615)
        screen.autoMatch(dimension: .width, to: .width, of: self, multiplier: 0.9173553719)
        screen.autoMatch(dimension: .width, to: .height, of: screen, multiplier: 0.6350574713)

        // add button to phone
        button.layer.borderColor = UIColor(red: 0.8045, green: 0.8012, blue: 0.8011, alpha: 1).cgColor
        addSubview(button)

        // set dimensions of button
        button.autoMatch(dimension: .width, to: .height, of: button)
        button.autoMatch(dimension: .width, to: .width, of: self, multiplier: 0.1652892562)

        // set location of button
        button.autoConstrain(attribute: .horizontal, to: .bottom, of: self, multiplier: 0.9252136752)
        button.autoAlignAxis(toSuperviewAxis: .vertical)
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

        // update width of button
        let buttonWidth = button.bounds.size.width
        button.layer.cornerRadius = buttonWidth / 2
        button.layer.borderWidth = buttonWidth * 0.15

        // update corners of screen
        let phoneBounds = bounds
        let phoneWidth = phoneBounds.size.width
        screen.layer.cornerRadius = phoneWidth * 0.04132231405

        // update mask of phone
        phoneMask.frame = phoneBounds
        let speakerCenter = phoneWidth * 0.0991735537
        let speakerWidth = phoneWidth * 0.1404958678
        let speakerHeight = phoneWidth * 0.03305785124

        let path = UIBezierPath(roundedRect: phoneBounds, cornerRadius: phoneWidth * 0.0991735537)

        path.append(UIBezierPath(
            roundedRect: CGRect(
                x: phoneWidth / 2 - speakerWidth / 2,
                y: speakerCenter - speakerHeight / 2,
                width: speakerWidth,
                height: speakerHeight
            ),
            cornerRadius: speakerHeight / 2
        ))

        phoneMask.path = path.cgPath
    }
}

extension DefaultColor
{
    /// The color to display when demoing a light in the onboarding interface.
    fileprivate var onboardingDemoColor: UIColor
    {
        switch self
        {
        case .blue:
            return UIColor(red: 0.2144, green: 0.4943, blue: 0.9511, alpha: 1.0)
        case .green:
            return UIColor(red: 0.1686, green: 0.9373, blue: 0.3543, alpha: 1.0)
        case .red:
            return UIColor(red: 0.9373, green: 0.1686, blue: 0.1686, alpha: 1.0)
        case .purple:
            return UIColor(red: 0.9372, green: 0.1958, blue: 0.719, alpha: 1.0)
        case .yellow:
            return UIColor(red: 0.9373, green: 0.8471, blue: 0.1686, alpha: 1.0)
        case .none:
            return UIColor.clear
        }
    }
}
