import ReactiveSwift
import UIKit
import enum Result.NoError

final class ReviewsPromptViewController: UIViewController
{
    // MARK: - Buttons
    fileprivate let buttons = (
        negative: ReviewsEmojiButton.newAutoLayout(),
        positive: ReviewsEmojiButton.newAutoLayout()
    )

    // MARK: - View Loading
    override func loadView()
    {
        let view = ReviewsInsetView.newAutoLayout()
        self.view = view

        // add title label at the top of the view
        let titleLabel = UILabel.newAutoLayout()
        titleLabel.attributedText = tr(.reviewsPromptTitle).reviewsTitleAttributedString
        titleLabel.numberOfLines = 0
        titleLabel.textColor = .white
        view.contentView.addSubview(titleLabel)

        titleLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        titleLabel.autoAlignAxis(toSuperviewAxis: .vertical)
        titleLabel.autoPinEdgeToSuperview(edge: .top, inset: 60)

        // add buttons container for alignment and centering
        let buttonsContainer = UIView.newAutoLayout()
        view.contentView.addSubview(buttonsContainer)

        buttonsContainer.autoAlignAxis(toSuperviewAxis: .vertical)
        buttonsContainer.autoPin(edge: .top, to: .bottom, of: titleLabel, offset: 20, relation: .greaterThanOrEqual)

        NSLayoutConstraint.autoSet(priority: UILayoutPriorityDefaultHigh, forConstraints: {
            buttonsContainer.autoAlignAxis(toSuperviewAxis: .horizontal)
        })

        // add buttons to container
        buttons.negative.model = ReviewsEmojiButton.Model(
            emoji: tr(.reviewsNegativeEmoji),
            text: tr(.reviewsPromptNegative)
        )

        buttons.positive.model = ReviewsEmojiButton.Model(
            emoji: tr(.reviewsPositiveEmoji),
            text: tr(.reviewsPromptPositive)
        )

        buttonsContainer.addSubview(buttons.negative)
        buttonsContainer.addSubview(buttons.positive)

        buttons.negative.autoPinEdgesToSuperviewEdges(excluding: .trailing)
        buttons.positive.autoPinEdgesToSuperviewEdges(excluding: .leading)
        buttons.positive.autoPin(edge: .leading, to: .trailing, of: buttons.negative, offset: 75)
        buttons.positive.autoMatch(dimension: .width, to: .width, of: buttons.negative)
    }

    // MARK: - Feedback
    var feedbackProducer: SignalProducer<ReviewsFeedback, NoError>
    {
        return SignalProducer.merge(
            SignalProducer(buttons.negative.reactive.controlEvents(.touchUpInside)).map({ _ in ReviewsFeedback.negative }),
            SignalProducer(buttons.positive.reactive.controlEvents(.touchUpInside)).map({ _ in ReviewsFeedback.positive })
        )
    }
}
