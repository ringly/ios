import UIKit

final class CameraTitleView: UIView
{
    private let titleLabel = UILabel.newAutoLayout()
    let title : String = "WHAT ARE YOU UP TO?"
    let exitButton = UIButton.newAutoLayout()

    // MARK: - Initialization
    private func setup()
    {
        // setup title label
        let font = UIFont.gothamBook(17)
        titleLabel.attributedText = font.track(.controlsTracking, title).attributedString
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.white
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.numberOfLines = 2
        titleLabel.minimumScaleFactor = 0.7
        addSubview(titleLabel)

        titleLabel.autoAlignAxis(toSuperviewAxis: .vertical)
        titleLabel.autoFloatInSuperview(alignedTo: .horizontal, inset: 0)
        titleLabel.autoMatch(dimension: .width, to: .width, of: self, multiplier: 0.6)

        // setup exit button
        exitButton.setImage(UIImage(asset: .addButtonLarge), for: .normal)
        exitButton.showsTouchWhenHighlighted = true
        exitButton.transform = CGAffineTransform(rotationAngle: .pi/4.0)
        addSubview(exitButton)

        exitButton.autoAlign(axis: .horizontal, toSameAxisOf: titleLabel)
        exitButton.autoSetDimensions(to: CGSize(width: 50, height: 50))
        exitButton.autoPinEdgeToSuperview(edge: .trailing, inset: 0)
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
