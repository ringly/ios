import UIKit

final class CameraOnboardingTitleView: UIView
{
    private let tapDescription : String = "DOUBLE TAP YOUR RINGLY TO TAKE A SNAP"

    // MARK: - Initialization
    private func setup()
    {
        // setup title label
        let instructionFont = UIFont.gothamBook(17)
        let instructions = UILabel.newAutoLayout()
        instructions.attributedText = instructionFont.track(.controlsTracking, tapDescription).attributedString
        instructions.textAlignment = .center
        instructions.textColor = UIColor.white
        instructions.lineBreakMode = .byWordWrapping
        instructions.adjustsFontSizeToFitWidth = true
        instructions.minimumScaleFactor = 0.6
        instructions.numberOfLines = 2
        self.addSubview(instructions)

        instructions.autoFloatInSuperview(alignedTo: .horizontal)
        instructions.autoFloatInSuperview(alignedTo: .vertical, inset: 25)
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
