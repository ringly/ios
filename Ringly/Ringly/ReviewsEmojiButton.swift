import UIKit

final class ReviewsEmojiButton: UIControl
{
    // MARK: - Model
    struct Model
    {
        let emoji: String
        let text: String
    }

    var model: Model?
    {
        didSet
        {
            labels.emoji.text = model?.emoji
            labels.text.attributedText = model?.text.reviewsBodyAttributedString
        }
    }

    // MARK: - Subviews
    fileprivate let labels = (
        emoji: UILabel.newAutoLayout(),
        text: UILabel.newAutoLayout()
    )

    // MARK: - Initialization
    fileprivate func setup()
    {
        labels.emoji.font = .systemFont(ofSize: ReviewsViewController.emojiFontSize)
        labels.emoji.isUserInteractionEnabled = false
        addSubview(labels.emoji)

        labels.emoji.autoAlignAxis(toSuperviewAxis: .vertical)
        labels.emoji.autoPinEdgeToSuperview(edge: .top)

        labels.text.textColor = .white
        labels.text.isUserInteractionEnabled = false
        addSubview(labels.text)

        labels.text.autoFloatInSuperview(alignedTo: .vertical)
        labels.text.autoPin(edge: .top, to: .bottom, of: labels.emoji, offset: 15)
        labels.text.autoPinEdgeToSuperview(edge: .bottom, inset: 0, relation: .greaterThanOrEqual)
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

    // MARK: - Highlighting
    override var isHighlighted: Bool
    {
        didSet
        {
            let alpha: CGFloat = isHighlighted ? 0.5 : 1
            labels.emoji.alpha = alpha
            labels.text.alpha = alpha
        }
    }
}
