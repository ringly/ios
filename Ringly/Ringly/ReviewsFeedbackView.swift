import ReactiveSwift
import RinglyExtensions
import UIKit
import enum Result.NoError

/// A view that displays the feedback request interface for reviews.
final class ReviewsFeedbackView: UIView
{
    // MARK: - Model
    struct Model
    {
        /// The emoji displayed at the top of the prompt.
        let emoji: String

        /// The title text displayed below the emoji.
        let titleText: String

        /// The body text displayed below the title.
        let bodyText: String

        /// The title for the action button.
        let actionTitle: String

        /// The title for the dismiss button.
        let dismissTitle: String
    }

    var model: Model?
    {
        didSet
        {
            labels.emoji.text = model?.emoji
            labels.title.attributedText = model?.titleText.reviewsTitleAttributedString
            labels.body.attributedText = model?.bodyText.reviewsBodyAttributedString

            pad.actionTitle = model?.actionTitle
            pad.dismissTitle = model?.dismissTitle
        }
    }

    // MARK: - Subviews
    fileprivate let labels = (
        emoji: UILabel.newAutoLayout(),
        title: UILabel.newAutoLayout(),
        body: UILabel.newAutoLayout()
    )

    fileprivate let pad = AlertControlPad.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        let smallPadding: CGFloat = DeviceScreenHeight.current.select(five: 20, preferred: 30)
        let largePadding: CGFloat = DeviceScreenHeight.current.select(five: 20, preferred: 40)

        if DeviceScreenHeight.current > .four
        {
            labels.emoji.font = UIFont.systemFont(ofSize: ReviewsViewController.emojiFontSize)
            addSubview(labels.emoji)

            labels.emoji.autoPinEdgeToSuperview(edge: .top)
            labels.emoji.autoAlignAxis(toSuperviewAxis: .vertical)
        }

        labels.title.numberOfLines = 0
        labels.title.preferredMaxLayoutWidth = 215
        labels.title.textColor = .white
        addSubview(labels.title)

        labels.title.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        labels.title.autoFloatInSuperview(alignedTo: .vertical)

        if DeviceScreenHeight.current > .four
        {
            labels.title.autoPin(edge: .top, to: .bottom, of: labels.emoji, offset: smallPadding)
        }
        else
        {
            labels.title.autoPinEdgeToSuperview(edge: .top)
        }

        labels.body.numberOfLines = 0
        labels.body.preferredMaxLayoutWidth = 220
        labels.body.textColor = .white
        addSubview(labels.body)

        labels.body.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        labels.body.autoPin(edge: .top, to: .bottom, of: labels.title, offset: largePadding)
        labels.body.autoFloatInSuperview(alignedTo: .vertical)

        addSubview(pad)
        pad.autoFloatInSuperview(alignedTo: .vertical)
        pad.autoSet(dimension: .width, to: 260)
        pad.autoPinEdgeToSuperview(edge: .bottom)
        pad.autoPin(edge: .top, to: .bottom, of: labels.body, offset: largePadding)
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

    // MARK: - Button Producers
    var actionProducer: SignalProducer<(), NoError> { return pad.actionProducer }
    var dismissProducer: SignalProducer<(), NoError> { return pad.dismissProducer }
}
