import UIKit

final class AvatarControl: UIControl
{
    // MARK: - Content
    var image: UIImage?
    {
        didSet
        {
            imageView.image = image ?? UIImage(asset: .emptyProfile)
        }
    }

    override var isHighlighted: Bool
    {
        didSet { imageView.alpha = isHighlighted ? 0.5 : 1 }
    }

    // MARK: - Subviews
    fileprivate let imageView = UIImageView.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        // accessibility setup
        accessibilityLabel = "Edit Avatar"
        accessibilityTraits = UIAccessibilityTraitButton
        isAccessibilityElement = true

        // layer setup
        let borderWidth: CGFloat = 10
        layer.borderWidth = borderWidth
        layer.borderColor = UIColor.white.cgColor
        layer.masksToBounds = true

        // add image view
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = false
        addSubview(imageView)

        // layout
        let inset = borderWidth / 2
        imageView.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets(horizontal: inset, vertical: inset))
        autoSetDimensions(to: CGSize(width: AvatarControl.size, height: AvatarControl.size))
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

    // MARK: - Layout
    @nonobjc static let size: CGFloat = 154

    override func layoutSubviews()
    {
        super.layoutSubviews()
        layer.cornerRadius = bounds.size.width / 2
    }
}
