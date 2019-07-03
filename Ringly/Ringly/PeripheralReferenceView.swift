import ReactiveSwift
import RinglyExtensions
import UIKit
import enum Result.NoError

final class PeripheralReferenceView: UIView
{
    // MARK: - View Model

    /// Describes the potential states of a peripheral reference view.
    struct Model
    {
        /// The style of peripheral to display.
        let content: PeripheralReferenceContentView.Model

        /// Whether or not the peripheral removal interface should be displayed.
        let removing: Bool
    }

    /// The view's current model.
    let model = MutableProperty(Model?.none)

    // MARK: - Peripheral Control

    /// A long-press gesture recognizer for `peripheralControl`.
    private let peripheralLongPress = UILongPressGestureRecognizer()

    /// Displays an image of the current peripheral.
    let peripheralControl = PeripheralImageControl.newAutoLayout()

    // MARK: - Other Subviews

    /// Displays information about and buttons to change settings for the peripheral.
    private let contentView = PeripheralReferenceContentView.newAutoLayout()

    /// A view for removing the peripheral.
    private let removeView = PeripheralRemoveView.newAutoLayout()

    // MARK: - Initialization
    private func setup()
    {
        // add the peripheral control at the top of the view
        addSubview(peripheralControl)
        peripheralControl.autoPinEdgeToSuperview(edge: .top)
        peripheralControl.autoAlignAxis(toSuperviewAxis: .vertical)

        // add a long press gesture recognizer for removing peripherals
        peripheralControl.addGestureRecognizer(peripheralLongPress)

        // add the content view
        addSubview(contentView)
        contentView.autoPin(edge: .top, to: .bottom, of: peripheralControl, offset: -20)
        contentView.autoFloatInSuperview(alignedTo: .vertical)
        let contentBottom = contentView.autoPinEdgeToSuperview(edge: .bottom)

        // add the removal view
        addSubview(removeView)
        removeView.autoPin(edge: .top, to: .bottom, of: peripheralControl, offset: 10)
        removeView.autoFloatInSuperview(alignedTo: .vertical)
        let removeBottom = removeView.autoPinEdgeToSuperview(edge: .bottom)

        // shake peripheral control while removing
        let shakeDuration: DispatchTimeInterval = .milliseconds(75)

        // bind models
        removeView.peripheralStyle <~ model.producer.map({ $0?.content.style })
        contentView.model <~ model.producer.map({ $0?.content })

        // update the peripheral style
        model.producer.map({ $0?.content.style }).skipRepeatsOptional(==).startWithValues({ [weak self] style in
            self?.peripheralControl.style = style
        })

        model.producer.map({ $0?.removing ?? false }).skipRepeats()
            .on(value: { [weak self] removing in
                self?.contentView.activate(if: !removing)
                self?.removeView.activate(if: removing)

                NSLayoutConstraint.conditionallyActivateConstraints([
                    (removeBottom, removing), (contentBottom, !removing)
                ])
            })
            .flatMap(.latest, transform: { removing -> SignalProducer<CGFloat?, NoError> in
                removing
                    ? immediateTimer(interval: shakeDuration, on: QueueScheduler.main)
                        .scan(1, { previous, _ in -previous }).map(Optional.some)
                    : SignalProducer(value: .none)
            })
            .take(until: reactive.lifetime.ended)
            .start(animationDuration: shakeDuration.timeInterval, action: { [weak peripheralControl] optionalFactor in
                peripheralControl?.peripheralTransform = optionalFactor.map({ factor in
                    CGAffineTransform(rotationAngle: CGFloat.random(minimum: 0.025, maximum: 0.05) * factor)
                }) ?? CGAffineTransform.identity
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

    // MARK: - Peripheral Producers
    var peripheralTapped: SignalProducer<PeripheralImageControl, NoError>
    {
        return SignalProducer(peripheralControl.reactive.controlEvents(.touchUpInside))
    }

    var producerForDisconnectedWiggle: SignalProducer<(), NoError>
    {
        return contentView.producerForDisconnectedWiggle
    }

    // MARK: - Removal Producers
    var requestRemoveProducer: SignalProducer<Bool, NoError>
    {
        return SignalProducer.merge(
            SignalProducer(peripheralLongPress.reactive.stateChanged)
                .filter({ $0.state == .began })
                .map({ _ in true }),
            SignalProducer.merge(
                removeView.notNowProducer,
                removeView.removeProducer.delay(0.5, on: QueueScheduler.main) // wait for animate out
            ).map({ _ in false })
        )
    }

    var removeProducer: SignalProducer<(), NoError>
    {
        return removeView.removeProducer
    }

    // MARK: - Button Producers
    var updateTapped: SignalProducer<(), NoError>
    {
        return contentView.updateTapped
    }

    var notConnectedTapped: SignalProducer<(), NoError>
    {
        return contentView.notConnectedTapped
    }

    var selectTapped: SignalProducer<(), NoError>
    {
        return contentView.selectTapped
    }
    
    var reconnectTapped: SignalProducer<(), NoError>
    {
        return contentView.reconnectTapped
    }
}

extension UIView
{
    @nonobjc func activate(if active: Bool)
    {
        self.isAccessibilityElement = active
        self.isUserInteractionEnabled = active
        self.alpha = active ? 1 : 0
    }
}
