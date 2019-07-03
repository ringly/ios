import ReactiveSwift
import UIKit
import enum Result.NoError

final class PeripheralRemoveView: UIView
{
    // MARK: - Configuration
    let peripheralStyle = MutableProperty(RLYPeripheralStyle?.none)

    // MARK: - Subviews
    fileprivate let remove = ButtonControl.newAutoLayout()
    fileprivate let notNow = LinkControl.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        let label = UILabel.newAutoLayout()
        label.textColor = .white
        label.numberOfLines = 2
        addSubview(label)

        remove.title = tr(.remove)
        addSubview(remove)

        notNow.text.value = trUpper(.notNow)
        addSubview(notNow)

        [label, remove, notNow].forEach({ $0.autoFloatInSuperview(alignedTo: .vertical) })

        label.autoPinEdgeToSuperview(edge: .top)
        notNow.autoPinEdgeToSuperview(edge: .bottom)

        remove.autoPin(edge: .top, to: .bottom, of: label, offset: 36)
        remove.autoSetDimensions(to: CGSize(width: 166, height: 47))

        notNow.autoPin(edge: .top, to: .bottom, of: remove)
        notNow.autoSetDimensions(to: CGSize(width: 166, height: 58))

        // bind text of label
        peripheralStyle.producer
            .mapOptional({ style -> NSAttributedString in
                let font = UIFont.gothamBook(21)

                return [
                    font.track(250, trUpper(.remove)),
                    "\n",
                    font.track(250, (RLYPeripheralStyleName(style) ?? "RINGLY").uppercased() + "?")
                ].join().attributes(paragraphStyle: .with(alignment: .center, lineSpacing: 9))
            })
            .startWithValues({ label.attributedText = $0 })
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

    // MARK: - Controls

    /// A producer for the user tapping the "REMOVE" button.
    var removeProducer: SignalProducer<(), NoError> { return SignalProducer(remove.reactive.controlEvents(.touchUpInside)).void }

    /// A producer for the user tapping the "NOT NOW" button.
    var notNowProducer: SignalProducer<(), NoError> { return SignalProducer(notNow.reactive.controlEvents(.touchUpInside)).void }
}
