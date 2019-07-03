import PureLayout
import ReactiveSwift
import RinglyExtensions
import UIKit

/// A text-based button control, with a custom underline effect applied.
final class UnderlineLinkControl: UIControl
{
    // MARK: - Initialization
    fileprivate func setup()
    {
        accessibilityTraits = UIAccessibilityTraitButton
        isAccessibilityElement = true

        let container = UIView.newAutoLayout()
        container.isUserInteractionEnabled = false // disables interaction on all subviews
        addSubview(container)

        label.textColor = UIColor.white
        container.addSubview(label)

        underline.backgroundColor = UIColor.white
        container.addSubview(underline)

        glow.showsTouchWhenHighlighted = true
        container.addSubview(glow)

        // layout
        container.autoFloatInSuperview()

        [ALEdge.leading, .trailing, .top].forEach({ edge in label.autoPinEdgeToSuperview(edge: edge) })

        underline.autoPinEdgeToSuperview(edge: .bottom)
        underline.autoSet(dimension: .height, to: 1)
        underline.autoConstrain(attribute: .top, to: .baseline, of: label, offset: 6)
        underline.autoPin(edge: .leading, to: .leading, of: label)
        underline.autoPin(edge: .trailing, to: .trailing, of: label)

        glow.autoAlignAxis(toSuperviewAxis: .vertical)
        glow.autoConstrain(attribute: .horizontal, to: .horizontal, of: label)

        // bind text to properties
        _text.producer.combineLatest(with: _font.producer)
            .map(unwrap)
            .mapOptional({ text, font in font.track(.linkTracking, text) })
            .startWithValues({ [weak self] attributed in
                self?.label.attributedText = attributed?.attributedString
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

    // MARK: - Subviews

    /// A glow added when the button is highlighted.
    fileprivate let glow = UIButton.newAutoLayout()

    /// The label for text content.
    fileprivate let label = UILabel.newAutoLayout()

    /// The underline view.
    fileprivate let underline = UIView.newAutoLayout()

    // MARK: - Text

    /// A backing property for `text`.
    fileprivate let _text = MutableProperty(String?.none)

    /// The text displayed by the control.
    var text: String?
    {
        get { return _text.value }
        set
        {
            _text.value = newValue
            accessibilityLabel = newValue
        }
    }

    /// A backing property for `font`.
    fileprivate let _font = MutableProperty(UIFont.gothamBook(14))

    /// The font used by the control.
    var font: UIFont
    {
        get { return _font.value }
        set { _font.value = newValue }
    }

    // MARK: - State

    /// Updates the glow appearance when the highlight state changes.
    override var isHighlighted: Bool { didSet { glow.isHighlighted = isHighlighted } }
}

