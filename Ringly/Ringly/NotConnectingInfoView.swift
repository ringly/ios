import UIKit

/// An individual component view of `NotConnectingViewController`, used for displaying each reason that the user's
/// peripheral may not be connecting.
final class NotConnectingInfoView: UIView
{
    // MARK: - Subviews

    /// The label displaying the `title` string.
    fileprivate let titleLabel = UILabel.newAutoLayout()

    /// The label displaying the `body` string.
    fileprivate let bodyLabel = UILabel.newAutoLayout()

    /// The view displaying `image`.
    fileprivate let imageView = UIImageView.newAutoLayout()

    // MARK: - Content

    /// The font used for labels.
    fileprivate let font = UIFont.gothamBook(11)

    /// The title string displayed by the view.
    var title: String?
    {
        get { return titleLabel.attributedText?.string }
        set
        {
            titleLabel.attributedText = newValue.map({ font.track(150, $0).attributedString })
        }
    }

    /// The body string displayed by the view.
    var body: String?
    {
        get { return bodyLabel.attributedText?.string }
        set
        {
            bodyLabel.attributedText = newValue.map({ text in
                font.track(50, text).attributes(paragraphStyle: .with(lineSpacing: 4))
            })
        }
    }

    /// The icon displayed by the view.
    var image: UIImage?
    {
        get { return imageView.image }
        set { imageView.image = newValue }
    }

    // MARK: - Initialization
    fileprivate func setup()
    {
        // add subviews
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0
        addSubview(titleLabel)

        bodyLabel.numberOfLines = 0
        bodyLabel.textColor = .white
        addSubview(bodyLabel)

        addSubview(imageView)

        // layout - horizontal
        imageView.autoPin(edge: .right, to: .left, of: self, offset: 42)

        [titleLabel, bodyLabel].forEach({
            $0.autoPinEdgeToSuperview(edge: .left, inset: 55)
            $0.autoPinEdgeToSuperview(edge: .right)
        })

        // layout - vertical
        titleLabel.autoPinEdgeToSuperview(edge: .top)
        bodyLabel.autoPin(edge: .top, to: .bottom, of: titleLabel, offset: 13)
        bodyLabel.autoPinEdgeToSuperview(edge: .bottom)
        imageView.autoAlign(axis: .horizontal, toSameAxisOf: titleLabel)

        bodyLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
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

    override func layoutSubviews()
    {
        super.layoutSubviews()
    }
}
