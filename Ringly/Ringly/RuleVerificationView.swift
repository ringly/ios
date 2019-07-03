import ReactiveSwift
import UIKit

/// A view that displays an interface for verifying that a rule has been complied with (e.g. password requirements).
final class RuleVerificationView: UIView
{
    // MARK: - Subviews
    fileprivate let label = UILabel.newAutoLayout()
    fileprivate let check = UIImageView.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        accessibilityElementsHidden = false // provide hints on the fields we are verifying instead

        check.image = UIImage(asset: .authenticationCheck)
        addSubview(check)

        label.font = UIFont.gothamBook(11)
        label.numberOfLines = 0
        label.textColor = UIColor(white: 1, alpha: 0.8)
        label.textAlignment = .center
        addSubview(label)

        _verified.producer.startWithValues({ [weak self] verified in
            self?.label.alpha = verified ? 1 : 0.75
            self?.check.alpha = verified ? 1 : 0
            self?.setNeedsLayout()
        })
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

    // MARK: - Verification

    /// Whether or not the view should be in "verified" mode. This triggers a layout requirement, so to animate the
    /// transition, wrap this in an animation block and apply `layoutIfNeeded`.
    var verified: Bool
    {
        get { return _verified.value }
        set { _verified.value = newValue }
    }

    /// A backing property for `verified`.
    fileprivate let _verified = MutableProperty(false)

    // MARK: - Content

    /// The text displayed by the verification label.
    var text: String?
    {
        get { return label.text }
        set { label.text = newValue }
    }

    // MARK: - Layout
    fileprivate static let innerPadding: CGFloat = 5

    /// Returns the layout sizes for the check and label, respectively.
    fileprivate func layoutSizes() -> (CGSize, CGSize)
    {
        return (check.sizeThatFits(CGSize.max), label.sizeThatFits(CGSize.max))
    }

    override func layoutSubviews()
    {
        super.layoutSubviews()

        // sizes needed for overall layout calculations
        let size = bounds.size
        let (checkSize, labelSize) = layoutSizes()

        // the check is always a fixed distance from the label - the only thing that matters is where the center is
        let labelXOriginOffset = labelSize.width - (verified ? checkSize.width + RuleVerificationView.innerPadding : 0)
        let labelXOrigin = size.width / 2 - labelXOriginOffset / 2

        // assign frames to views
        check.frame = CGRect(
            x: labelXOrigin - checkSize.width - RuleVerificationView.innerPadding,
            y: size.height / 2 - checkSize.height / 2,
            width: checkSize.width,
            height: checkSize.height
        )

        label.frame = CGRect(
            x: labelXOrigin,
            y: size.height / 2 - labelSize.height / 2,
            width: labelSize.width,
            height: labelSize.height
        )
    }

    override var intrinsicContentSize : CGSize
    {
        let (checkSize, labelSize) = layoutSizes()

        return CGSize(
            width: checkSize.width + labelSize.width + RuleVerificationView.innerPadding,
            height: max(checkSize.height, labelSize.height)
        )
    }
}
