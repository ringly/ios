import UIKit

/// A button containing a simple-style `DiamondActivityIndicator`.
final class DiamondActivityButton: UIButton
{
    // MARK: - Initialization
    fileprivate func setup()
    {
        showsTouchWhenHighlighted = true

        let activity = DiamondActivityIndicator.newAutoLayout()
        activity.appearance = .simple
        activity.isUserInteractionEnabled = false
        addSubview(activity)

        activity.autoSetDimensions(to: CGSize(width: 25, height: 22))
        activity.autoCenterInSuperview()
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
