import UIKit

final class RingProgressIndicator: UIView
{
    // MARK: - Progress

    /// The progress to display, from `0` to `1`.
    var progress: CGFloat = 0
    {
        didSet { setNeedsLayout() }
    }

    // MARK: - Subviews
    fileprivate let empty = UIView.progressSubview()
    fileprivate let full = UIView.progressSubview()

    // MARK: - Initialization
    fileprivate func setup()
    {
        empty.wrapper.alpha = 0.25
        addSubview(empty.wrapper)
        addSubview(full.wrapper)
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

    /// The ideal size of the progress indicator, without rescaling.
    var idealSize: CGSize
    {
        return empty.imageView.image?.size ?? .zero
    }

    override func layoutSubviews()
    {
        super.layoutSubviews()

        let size = bounds.size
        let fullHeight = size.height * progress
        let emptyHeight = size.height - fullHeight

        empty.wrapper.frame = CGRect(x: 0, y: 0, width: size.width, height: emptyHeight)
        full.wrapper.frame = CGRect(x: 0, y: size.height - fullHeight, width: size.width, height: fullHeight)

        empty.imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        full.imageView.frame = CGRect(x: 0, y: -emptyHeight, width: size.width, height: size.height)
    }
}

extension UIView
{
    fileprivate static func progressSubview() -> (wrapper: UIView, imageView: UIImageView)
    {
        let imageView = UIImageView()
        imageView.image = UIImage(asset: .ringOutlineLarge)

        let wrapper = UIView()
        wrapper.clipsToBounds = true
        wrapper.addSubview(imageView)

        return (wrapper: wrapper, imageView: imageView)
    }
}
