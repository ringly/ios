import PureLayout
import ReactiveSwift
import RinglyExtensions
import UIKit

/// A two-part text-based control, where the second part is underlined.
final class UnderlineDetailControl: UIControl
{
    // MARK: - Initialization
    fileprivate func setup()
    {
        isAccessibilityElement = true
        accessibilityTraits = UIAccessibilityTraitButton

        let container = UIView.newAutoLayout()
        container.isUserInteractionEnabled = false // disables interaction on all subviews
        addSubview(container)

        leadingLabel.textColor = UIColor.white
        container.addSubview(leadingLabel)

        trailingLabel.textColor = UIColor.white
        container.addSubview(trailingLabel)

        underline.backgroundColor = UIColor.white
        container.addSubview(underline)

        glow.isAccessibilityElement = false
        glow.isUserInteractionEnabled = false
        glow.showsTouchWhenHighlighted = true
        container.addSubview(glow)

        // layout
        container.autoFloatInSuperview()

        [(leadingLabel, ALEdge.leading), (trailingLabel, .trailing)].forEach({ label, side in
            label.isAccessibilityElement = false
            label.isUserInteractionEnabled = false

            label.autoPinEdgeToSuperview(edge: side)
            label.autoPinEdgeToSuperview(edge: .top, inset: 0, relation: .greaterThanOrEqual)
        })

        leadingLabel.autoPin(edge: .trailing, to: .leading, of: trailingLabel)
        leadingLabel.autoConstrain(attribute: .baseline, to: .baseline, of: trailingLabel)

        underline.autoPinEdgeToSuperview(edge: .bottom)
        underline.autoConstrain(attribute: .top, to: .baseline, of: trailingLabel, offset: 6)
        underline.autoSet(dimension: .height, to: 1)
        underline.autoPin(edge: .leading, to: .leading, of: trailingLabel)
        underline.autoPin(edge: .trailing, to: .trailing, of: trailingLabel)

        glow.autoAlignAxis(toSuperviewAxis: .vertical)
        glow.autoConstrain(attribute: .horizontal, to: .horizontal, of: trailingLabel)

        // bind text to properties
        let font = UIFont.gothamBook(14)

        _leadingText.producer
            .mapOptional({ $0.attributes(font: font, tracking: 100) })
            .startWithValues({ [weak self] attributed in
                self?.leadingLabel.attributedText = attributed?.attributedString
            })

        _trailingText.producer
            .mapOptional({ $0.attributes(font: font, tracking: 100) })
            .startWithValues({ [weak self] attributed in
                self?.trailingLabel.attributedText = attributed?.attributedString
            })

        _leadingText.producer.combineLatest(with: _trailingText.producer)
            .map(unwrap)
            .startWithValues({ [weak self] optional in
                self?.accessibilityLabel = optional.map(+)
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

    /// The first label, which is not underlined.
    fileprivate let leadingLabel = UILabel.newAutoLayout()

    /// The second label, which is underlined.
    fileprivate let trailingLabel = UILabel.newAutoLayout()

    /// The underline view.
    fileprivate let underline = UIView.newAutoLayout()

    // MARK: - Text

    /// A backing property for `leadingText`.
    fileprivate let _leadingText = MutableProperty(String?.none)

    /// The leading text content, which is not underlined. In most cases, this string should end with a space, so that
    /// it is properly spaced with the trailing content.
    var leadingText: String?
    {
        get { return _leadingText.value }
        set { _leadingText.value = newValue }
    }

    /// A backing property for `leadingText`.
    fileprivate let _trailingText = MutableProperty(String?.none)

    /// The leading text content, which is underlined.
    var trailingText: String?
    {
        get { return _trailingText.value }
        set { _trailingText.value = newValue }
    }

    // MARK: - State

    /// Updates the glow appearance when the highlight state changes.
    override var isHighlighted: Bool { didSet { glow.isHighlighted = isHighlighted } }
}
