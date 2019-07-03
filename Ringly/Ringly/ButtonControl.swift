import ReactiveSwift
import RinglyExtensions
import UIKit

/// A standard button for the app - a border, with capitalized kerned text in the center.
final class ButtonControl: UIControl, GestureAvoidable
{
    fileprivate let controlMaskView = ButtonControlMaskView(frame: .zero)

    // MARK: - Initialization
    fileprivate func setup()
    {
        accessibilityTraits = UIAccessibilityTraitButton
        isAccessibilityElement = true

        // update appearance
        SignalProducer.combineLatest(highlightedProperty.producer, _fillColor.producer, _highlightedFillColor.producer)
            .map({ highlighted, fillColor, highlightedFillColor in
                highlighted ? highlightedFillColor : fillColor
            })
            .startWithValues({ [weak self] color in self?.backgroundColor = color })

        // add mask to use when text color is not set
        let controlMaskView = self.controlMaskView
        controlMaskView.backgroundColor = .clear
        mask = controlMaskView

        // add label to use when text color is set
        let label = UILabel.newAutoLayout()
        label.textAlignment = .center
        addSubview(label)

        label.autoPinEdgeToSuperview(edge: .leading, inset: 10, relation: .greaterThanOrEqual)
        label.autoPinEdgeToSuperview(edge: .trailing, inset: 10, relation: .greaterThanOrEqual)
        label.autoCenterInSuperview()

        // bind title, font, and text color to the content views
        let attributedTitle = _title.producer.combineLatest(with: _font.producer)
            .map(unwrap)
            .mapOptional({ title, font in
                font.track(.buttonTracking, title.uppercased())
            })

        attributedTitle.combineLatest(with: _textColor.producer)
            .startWithValues({ attributedTitle, optionalTextColor in
                // only add title to mask if text color is nil
                controlMaskView.attributedTitle = optionalTextColor == nil ? attributedTitle?.attributedString : nil

                // only add title to label if text color is not nil
                label.attributedText = unwrap(attributedTitle, optionalTextColor).map({ title, textColor in
                    title.attributes(color: textColor)
                })
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

    // MARK: - Text Content

    /// A backing property for `title`.
    fileprivate let _title = MutableProperty(String?.none)

    /// A backing property for `font`.
    fileprivate let _font = MutableProperty(UIFont.gothamBook(15))

    /// A backing property for `textColor`.
    fileprivate let _textColor = MutableProperty(UIColor?.none)

    /// The title displayed by the button.
    var title: String?
    {
        get { return _title.value }
        set
        {
            _title.value = newValue
            accessibilityLabel = newValue
        }
    }

    /// The font used by the button.
    var font: UIFont
    {
        get { return _font.value }
        set { _font.value = newValue }
    }

    /// The text color used by the button. This value is optional, if set to `nil` the text will be a cutout.
    var textColor: UIColor?
    {
        get { return _textColor.value }
        set { _textColor.value = newValue }
    }

    // MARK: - Fill Colors

    /// The default value for `fillColor`.
    static let defaultFillColor = UIColor.white

    /// The default value for `highlightedFillColor`.
    static let defaultHighlightedFillColor = UIColor(white: 0.95, alpha: 1.0)

    /// A backing property for `fillColor`.
    fileprivate let _fillColor = MutableProperty(ButtonControl.defaultFillColor)

    /// A backing property for `highlightedFillColor`.
    fileprivate let _highlightedFillColor = MutableProperty(ButtonControl.defaultHighlightedFillColor)

    /// The color used to fill the button.
    var fillColor: UIColor
    {
        get { return _fillColor.value }
        set { _fillColor.value = newValue }
    }

    /// The color used to fill the button when it is highlighted.
    var highlightedFillColor: UIColor
    {
        get { return _highlightedFillColor.value }
        set { _highlightedFillColor.value = newValue }
    }

    @nonobjc func useDarkAppearance()
    {
        fillColor = UIColor(white: 0.2, alpha: 1.0)
        highlightedFillColor = .black
    }

    // MARK: - Highlighted
    fileprivate let highlightedProperty = MutableProperty(false)

    override var isHighlighted: Bool
    {
        didSet
        {
            highlightedProperty.value = isHighlighted
        }
    }

    // MARK: - Layout
    override func layoutSubviews()
    {
        super.layoutSubviews()
        mask?.frame = bounds
    }
}

private final class ButtonControlMaskView: UIView
{
    // MARK: - Text Content

    /// The title displayed by the button.
    var attributedTitle: NSAttributedString? = nil
    {
        didSet { setNeedsDisplay() }
    }

    // MARK: - Drawing
    fileprivate override func draw(_ rect: CGRect)
    {
        let bounds = self.bounds

        if let attributedTitle = self.attributedTitle, let context = UIGraphicsGetCurrentContext()
        {
            context.saveGState()

            // fill the entire mask area
            context.setFillColor(UIColor.black.cgColor)
            context.fill(bounds)

            // determine text drawing characteristics
            let size = attributedTitle.size()
            let point = CGPoint(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2)

            // draw the text as a hole in the previously drawn rect
            context.saveGState()
            context.setBlendMode(.destinationOut)
            attributedTitle.draw(at: point)
            context.restoreGState()

            context.restoreGState()
        }
        else
        {
            UIColor.black.setFill()
            UIRectFill(bounds)
        }
    }
}
