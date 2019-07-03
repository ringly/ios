import UIKit

/// A view used to display a title at the top of some DFU view controllers.
final class DFUUnderlineLabel: UIView
{
    // MARK: - Title
    var text: String?
    {
        get { return label.text }
        set { label.attributedText = newValue?.rly_DFUTitleString() }
    }

    // MARK: - Subviews
    fileprivate let label = UILabel.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        label.textAlignment = .center
        addSubview(label)

        label.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        label.autoPinEdgeToSuperview(edge: .top)
        label.autoFloatInSuperview(alignedTo: .vertical)

        let underline = UIView.rly_separatorView(withHeight: 1, color: .white)
        addSubview(underline)

        underline.autoPin(edge: .top, to: .bottom, of: label)
        underline.autoPin(edge: .left, to: .left, of: label)
        underline.autoPin(edge: .right, to: .right, of: label)
        underline.autoPinEdgeToSuperview(edge: .bottom)
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
