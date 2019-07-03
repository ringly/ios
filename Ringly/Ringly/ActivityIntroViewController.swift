import ReactiveSwift
import RinglyExtensions
import UIKit
import enum Result.NoError

final class ActivityIntroViewController: ServicesViewController
{
    // MARK: - Signals
    fileprivate let buttonTapPipe = Signal<(), NoError>.pipe()

    var buttonTapSignal: Signal<(), NoError>
    {
        return buttonTapPipe.0
    }

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        // centered hero image
        let container = UIView.newAutoLayout()
        view.addSubview(container)

        let imageView = UIImageView.newAutoLayout()
        imageView.image = UIImage(asset: .activityTrackingOnboardingHealthKit)
        container.addSubview(imageView)

        // main prompt label
        let promptLabel = UILabel.newAutoLayout()
        promptLabel.numberOfLines = 0
        promptLabel.textColor = .white
        view.addSubview(promptLabel)

        // button
        let button = ButtonControl.newAutoLayout()
        button.title = "SET SOME GOALS"
        view.addSubview(button)

        // layout
        container.autoPinEdgeToSuperview(edge: .top)
        container.autoFloatInSuperview(alignedTo: .vertical, inset: 10)

        imageView.autoFloatInSuperview()
        imageView.autoConstrainAspectRatio()

        promptLabel.autoPin(edge: .top, to: .bottom, of: container, offset: 40)
        promptLabel.autoFloatInSuperview(alignedTo: .vertical)
        promptLabel.autoSet(dimension: .width, to: 315, relation: .lessThanOrEqual)

        promptLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        promptLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)

        button.autoPin(edge: .top, to: .bottom, of: promptLabel, offset: 25)
        button.autoSetDimensions(to: CGSize(width: 230, height: 50))
        button.autoPinEdgeToSuperview(edge: .bottom, inset: 30)
        button.autoFloatInSuperview(alignedTo: .vertical)

        // interaction
        SignalProducer(button.reactive.controlEvents(.touchUpInside)).void.start(buttonTapPipe.1)

        // update prompt label for current services state
        services.peripherals.activityTrackingConnectivityProducer
            .take(until: reactive.lifetime.ended)
            .startWithValues({ promptLabel.attributedText = $0.promptText.attributedString })
    }
}

extension ActivityTrackingConnectivity
{
    fileprivate var promptText: NSAttributedString
    {
        let fontSize: CGFloat = 15
        let tracking: CGFloat = 30

        func attributes(_ string: AttributedStringProtocol) -> NSAttributedString
        {
            return string.attributes(
                font: UIFont.gothamBook(fontSize),
                paragraphStyle: NSParagraphStyle.with(alignment: .center, lineSpacing: 3),
                tracking: tracking
            )
        }

        func toAppleHealth(_ prefix: AttributedStringProtocol) -> NSAttributedString
        {
            return attributes([
                prefix,
                "connect".attributes(font: .gothamBold(fontSize), tracking: tracking),
                " to the Health app."
            ].join())
        }

        switch self
        {
        case .haveTrackingAndNoTracking, .updateRequired:
            return attributes("Don't miss a beat! Track your activity by connecting to the Health app.")
        case .haveTracking:
            return toAppleHealth("Stay on top of your activity!\nTo track your activity even when you're not wearing your Ringly, ")
        case .noTracking:
            return toAppleHealth("Good news! Even though your Ringly doesn't support activity, you can still track your activity in the Ringly app if you ")
        case .noPeripheralsNoHealth:
            return toAppleHealth("You're in luck. Even if you don't have a Ringly, you can still track your activity in the Ringly app if you ")
            
        }
    }
}
