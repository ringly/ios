import UIKit

final class TickTitleSupplementaryView: UICollectionReusableView
{
    // MARK: - Title
    fileprivate let titleLabel = UILabel.newAutoLayout()

    var title: String?
    {
        get { return titleLabel.text }
        set
        {
            titleLabel.attributedText = newValue.map({ text in
                UIFont.gothamBold(12).track(150, text).attributedString
            })
        }
    }

    // MARK: - Initialization
    fileprivate func setup()
    {
        titleLabel.textColor = .white

        addSubview(titleLabel)
        titleLabel.autoFloatInSuperview(alignedTo: .vertical)
        titleLabel.autoPinEdgeToSuperview(edge: .top)
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
