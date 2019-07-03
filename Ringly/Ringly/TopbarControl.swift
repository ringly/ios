import PureLayout
import ReactiveSwift
import UIKit

final class TopbarControl: UIControl
{
    // MARK: - Initialization
    fileprivate func setup()
    {
        let label = UILabel.newAutoLayout()
        let imageView = UIImageView.newAutoLayout()

        label.isUserInteractionEnabled = false
        imageView.isUserInteractionEnabled = false

        addSubview(label)
        addSubview(imageView)

        // layout
        label.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        label.autoPinEdgeToSuperview(edge: .leading, inset: 5, relation: .greaterThanOrEqual)
        label.autoPinEdgeToSuperview(edge: .trailing, inset: 0, relation: .greaterThanOrEqual)
        label.autoPinEdgeToSuperview(edge: .top, inset: 0, relation: .greaterThanOrEqual)
        label.autoPinEdgeToSuperview(edge: .bottom, inset: 0, relation: .greaterThanOrEqual)
        label.autoCenterInSuperview()

        imageView.autoPinEdgeToSuperview(edge: .leading, inset: 0, relation: .greaterThanOrEqual)
        imageView.autoPinEdgeToSuperview(edge: .trailing, inset: 0, relation: .greaterThanOrEqual)
        imageView.autoPinEdgeToSuperview(edge: .top, inset: 0, relation: .greaterThanOrEqual)
        imageView.autoPinEdgeToSuperview(edge: .bottom, inset: 0, relation: .greaterThanOrEqual)
        imageView.autoCenterInSuperview()

        // setup
        let color = SignalProducer.combineLatest(highlightedProperty.producer, self.color.producer, highlightedColor.producer)
            .map({ highlighted, color, highlightedColor in
                highlighted ? highlightedColor : color
            })

        color.startWithValues({ color in imageView.tintColor = color })

        content.producer.startWithValues({ content in
            switch content
            {
            case .label:
                imageView.image = nil
            }
        })

        SignalProducer.combineLatest(content.producer, color.producer).startWithValues({ content, color in
            switch content
            {
            case .label(let maybeText):
                guard let text = maybeText?.uppercased() else {
                    label.text = nil
                    return
                }

                if text.startIndex != text.endIndex
                {
                    let font = UIFont.gothamBook(9)
                    let index = text.characters.index(before: text.endIndex)

                    label.attributedText = [
                        text.substring(to: index).attributes(font: font, tracking: 300),
                        text.substring(from: index).attributes(font: font)
                    ].join().attributes(color: color)
                }
                else
                {
                    label.text = nil
                }
            }
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

    // MARK: - Properties

    /// The current content of the control.
    let content = MutableProperty(TopbarControlContent.label(""))

    /// The color of content when not highlighted.
    let color = MutableProperty(UIColor.ringlyTextHighlight)

    /// The color of content when highlighted.
    let highlightedColor = MutableProperty(UIColor.white)

    // MARK: - Objective-C Bridging

    /// The bridges the unavailable enum and property to Objective-C, and should be removed when no longer necessary.
    func setText(_ text: String)
    {
        self.content.value = .label(text)
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
}

enum TopbarControlContent
{
    case label(String?)
}
