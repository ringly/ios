import UIKit

final class ReviewsNegativeCompletionViewController: UIViewController
{
    override func loadView()
    {
        let view = ReviewsInsetView.newAutoLayout()
        self.view = view

        let container = UIView.newAutoLayout()
        view.contentView.addSubview(container)
        container.autoFloatInSuperview()

        let gem = UILabel.newAutoLayout()
        gem.font = UIFont.systemFont(ofSize: ReviewsViewController.emojiFontSize)
        gem.text = tr(.reviewsNegativeCompletionEmoji)
        container.addSubview(gem)

        gem.autoPinEdgeToSuperview(edge: .top)
        gem.autoAlignAxis(toSuperviewAxis: .vertical)

        let label = UILabel.newAutoLayout()
        label.attributedText = tr(.reviewsNegativeCompletionTitle).reviewsTitleAttributedString
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = 248
        label.textColor = .white
        container.addSubview(label)

        label.autoPinEdgesToSuperviewMarginsExcluding(edge: .top)
        label.autoPin(edge: .top, to: .bottom, of: gem, offset: 48)
    }
}
