import PureLayout
import ReactiveSwift
import RinglyExtensions
import UIKit

/// A text-based button control.
final class LinkControl: UIControl
{
    // MARK: - Initialization
    fileprivate func setup()
    {
        accessibilityTraits = UIAccessibilityTraitButton
        isAccessibilityElement = true

        let container = UIView.newAutoLayout()
        container.isUserInteractionEnabled = false // disables interaction on all subviews
        addSubview(container)

        let label = UILabel.newAutoLayout()
        label.textColor = UIColor.white
        container.addSubview(label)

        glow.showsTouchWhenHighlighted = true
        container.addSubview(glow)

        // layout
        container.autoFloatInSuperview()
        label.autoFloatInSuperview()

        glow.autoAlignAxis(toSuperviewAxis: .vertical)
        glow.autoConstrain(attribute: .horizontal, to: .horizontal, of: label)

        // bind text to properties
        SignalProducer.combineLatest(text.producer, font.producer, kerning.producer)
            .map(unwrap)
            .mapOptional({ text, font, tracking in font.track(tracking, text) })
            .startWithValues({ attributed in
                label.attributedText = attributed?.attributedString
            })

        text.producer.startWithValues({ [weak self] in self?.accessibilityLabel = $0 })
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

    // MARK: - Subviews

    /// A glow added when the button is highlighted.
    fileprivate let glow = UIButton.newAutoLayout()

    // MARK: - Text

    /// The text displayed by the control.
    let text = MutableProperty(String?.none)

    /// The font used by the control.
    let font = MutableProperty(UIFont.gothamBook(12))

    /// The kerning used by the control's text.
    let kerning = MutableProperty<CGFloat>(350)

    // MARK: - State

    /// Updates the glow appearance when the highlight state changes.
    override var isHighlighted: Bool { didSet { glow.isHighlighted = isHighlighted } }
}
