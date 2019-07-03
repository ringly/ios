import UIKit

final class Checkbox: UIView
{
    // MARK: - Checked State
    var checked: Bool = false
    {
        didSet
        {
            ring.transform = checked ? CGAffineTransform(scaleX: 0.9, y: 0.9) : CGAffineTransform.identity
            check.transform = checked ? CGAffineTransform.identity : CGAffineTransform(scaleX: 0.5, y: 0.5)
            check.alpha = checked ? 1 : 0
        }
    }

    // MARK: - Subviews
    fileprivate let ring = UIImageView.newAutoLayout()
    fileprivate let check = UIImageView.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        ring.image = UIImage(asset: .unchecked)
        ring.contentMode = .center
        ring.isUserInteractionEnabled = false
        addSubview(ring)

        check.image = UIImage(asset: .checked)
        check.contentMode = .center
        check.isUserInteractionEnabled = false
        addSubview(check)

        ring.autoPinEdgesToSuperviewEdges()
        check.autoPinEdgesToSuperviewEdges()
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
