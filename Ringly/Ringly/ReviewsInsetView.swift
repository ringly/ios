import UIKit

final class ReviewsInsetView: UIView
{
    // MARK: - Content View
    let contentView = UIView.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        addSubview(contentView)
        contentView.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets(top: 0, left: 0, bottom: 70, right: 0))
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
}
