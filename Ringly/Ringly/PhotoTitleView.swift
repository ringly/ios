import UIKit

final class PhotoTitleView: UIView
{
    // title of view
    private let titleLabel = UILabel.newAutoLayout()
    private let title: String = "EXPRESS YOURSELF"

    // back button to go back to capture image view
    let backButton = UIButton.newAutoLayout()
    let exitButton = UIButton.newAutoLayout()

    // MARK: - Initialization
    private func setup()
    {
        let font = UIFont.gothamBook(17)

        // setup exit button
        exitButton.setImage(UIImage(asset: .addButtonLarge), for: .normal)
        exitButton.showsTouchWhenHighlighted = true
        exitButton.transform = CGAffineTransform(rotationAngle: .pi/4.0)
        addSubview(exitButton)

        // setup back button
        backButton.setImage(UIImage(asset: .navigationBackArrow), for: .normal)
        backButton.showsTouchWhenHighlighted = true
        addSubview(backButton)

        // setup title label
        titleLabel.attributedText = font.track(.controlsTracking, title).attributedString
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.white
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.numberOfLines = 2
        titleLabel.minimumScaleFactor = 0.7
        addSubview(titleLabel)

        // layout
        titleLabel.autoCenterInSuperview()

        exitButton.autoPinEdgesToSuperviewEdges(excluding: .leading)
        exitButton.autoSet(dimension: .width, to: 60)

        backButton.autoPinEdgesToSuperviewEdges(excluding: .trailing)
        backButton.autoSet(dimension: .width, to: 60)
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
