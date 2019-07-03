import PureLayout
import ReactiveSwift
import RinglyExtensions
import UIKit
import enum Result.NoError

final class ApplicationsOnboardingViewController: UIViewController, ConfigurationsOnboardingConfirmation
{
    // MARK: - Subviews

    /// The label displaying detail text about the applications functionality.
    fileprivate let detailLabel = UILabel.newAutoLayout()

    /// The confirmation button.
    fileprivate let button = ButtonControl.newAutoLayout()

    /// A producer that yields a value when the user taps the view controller's confirmation button.
    var actionProducer: SignalProducer<(), NoError>
    {
        return SignalProducer(button.reactive.controlEvents(.touchUpInside)).void
    }

    // MARK: - Subviews
    fileprivate let gradient = GradientView.newAutoLayout()
    fileprivate let content = UIView.newAutoLayout()

    // MARK: - Phone Subviews
    fileprivate let phone = OnboardingPhoneView.newAutoLayout()
    fileprivate let animationView = ApplicationsOnboardingAnimationView()
    
    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        // use a gradient background
        gradient.setGradient(
            startColor: UIColor(red: 0.7759, green: 0.551, blue: 0.7441, alpha: 1.0),
            endColor: UIColor(red: 0.2615, green: 0.6641, blue: 0.9383, alpha: 1.0)
        )

        gradient.startPoint = CGPoint(x: 0.2, y: 0.2)
        gradient.endPoint = CGPoint(x: 1, y: 1)

        view.addSubview(gradient)
        gradient.autoPinEdgesToSuperviewEdges()

        // add content view (for transitions)
        view.addSubview(content)
        content.autoPinEdgesToSuperviewEdges()

        // add the phone view
        content.addSubview(phone)
        phone.autoFloatInSuperview(alignedTo: .vertical, inset: 10)
        phone.autoPinEdgeToSuperview(edge: .top, inset: NavigationBar.standardHeight)

        // add the detail label
        detailLabel.attributedText = tr(.applicationsOnboardingDetails).attributedOnboardingDetailString
        detailLabel.textColor = .white
        detailLabel.numberOfLines = 0
        content.addSubview(detailLabel)

        detailLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        detailLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        detailLabel.autoFloatInSuperview(alignedTo: .vertical, inset: 10)
        detailLabel.autoPin(edge: .top, to: .bottom, of: phone, offset: 30)

        // add the button
        button.title = tr(.applicationsOnboardingAction)
        content.addSubview(button)

        button.autoSetDimensions(to: CGSize(width: 256, height: 50))
        button.autoAlignAxis(toSuperviewAxis: .vertical)
        button.autoPin(edge: .top, to: .bottom, of: detailLabel, offset: 40)
        button.autoPinEdgeToSuperview(edge: .bottom, inset: ConfigurationsViewController.onboardingBottomPadding)

        // add the animation view to the phone
        phone.screen.addSubview(animationView)
        animationView.autoPinEdgesToSuperviewEdges()
        
        // set all icons to transparent to begin
        for icon in animationView.icons
        {
            icon.alpha = 0
            icon.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
        
        for vibration in animationView.vibrations
        {
            vibration.alpha = 0
            vibration.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
    }
    
    // MARK: - View Lifecycle
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        performAnimation()
    }
    
    // MARK: - Animation
    func performAnimation()
    {
        let animationView = self.animationView
        
        // the icons that will be visible in the final state
        let visibleIcons = (0..<(animationView.icons.count / 2)).map({ index -> UIView in
            animationView.icons[index * 2 + index % 2]
        })
        
        let invisibleIcons = (0..<(animationView.icons.count / 2)).map({ index -> UIView in
            animationView.icons[index * 2 + (index + 1) % 2]
        })
        
        // a producer to perform the initial animation fade-in
        let fadeInIcons = animationView.icons.map({ icon in
            UIView.animationProducer(duration: 
                Double.random(minimum: 0.35, maximum: 0.55),
                delay: Double.random(minimum: 0, maximum: 0.25),
                animations: {
                    icon.alpha = 0.5
                }
            )
        })
        
        // a producer to perform the icon scale-up
        let scaleUpIcons = zip(visibleIcons, 0..<visibleIcons.count).map({ icon, index in
            UIView.animationProducer(duration: 
                0.35,
                delay: 0.15 * Double(index),
                animations: {
                    icon.alpha = 1
                    icon.transform = .identity
                }
            )
        })
        
        // transition to left mode
        let transitionToLeft = UIView.animationProducer(duration: 0.4, delay: 0, animations: {
            for icon in invisibleIcons
            {
                icon.alpha = 0
            }
            
            animationView.phase.value = .lineup
            animationView.layoutIfNeeded()
        })
        
        // expand the colored rows
        let scaleUpTime = 0.25
        let rowExpansionTime = 0.5
        let rowExpansionDelay = 0.25
        
        let expandRows = [
            UIView.animationProducer(duration: rowExpansionTime, animations: {
                animationView.phase.value = .expandFirst
                animationView.layoutIfNeeded()
            }),
            UIView.animationProducer(duration: rowExpansionTime, delay: rowExpansionDelay, animations: {
                animationView.phase.value = .expandSecond
                animationView.layoutIfNeeded()
            }),
            UIView.animationProducer(duration: rowExpansionTime, delay: rowExpansionDelay * 2, animations: {
                animationView.phase.value = .expandThird
                animationView.layoutIfNeeded()
            }),
            UIView.animationProducer(duration: rowExpansionTime, delay: rowExpansionDelay * 3, animations: {
                animationView.phase.value = .expandFourth
                animationView.layoutIfNeeded()
            })
        ]
        
        let expandRowsAndScaleUp = zip(expandRows, 0..<expandRows.count).map({ producer, index in
            producer.then(UIView.animationProducer(duration: scaleUpTime, animations: {
                animationView.vibrations[index].alpha = 1
                animationView.vibrations[index].transform = .identity
            }))
        })
        
        // perform animations
        timer(interval: .milliseconds(250), on: QueueScheduler.main).take(first: 1)
            .then(SignalProducer.merge(fadeInIcons))
            .then(SignalProducer.merge(scaleUpIcons))
            .then(transitionToLeft)
            .then(SignalProducer.merge(expandRowsAndScaleUp))
            .start()
    }
}

extension ApplicationsOnboardingViewController: ForegroundBackgroundContentViewProviding
{
    var backgroundContentView: UIView? { return gradient }
    var foregroundContentView: UIView? { return content }
}
