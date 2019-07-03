import UIKit

final class ActivityIndicatorCollectionViewCell: UICollectionViewCell
{
    // MARK: - Initialization
    fileprivate func setup()
    {
        let indicator = DiamondActivityIndicator.newAutoLayout()
        contentView.addSubview(indicator)

        indicator.constrainToDefaultSize()
        indicator.autoCenterInSuperview()
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
