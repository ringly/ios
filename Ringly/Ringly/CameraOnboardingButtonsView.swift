import UIKit

final class CameraOnboardingButtonsView: UIView
{
    // skip button to go back to connection screen
    let skipButton : UIButton = UIButton.newAutoLayout()
    let skip : String = " SKIP"

    // MARK: - Initialization
    private func setup()
    {
        // setup skip button to go to camera
        let skipFont = UIFont.gothamBook(17)
        skipButton.setAttributedTitle(skipFont.track(.controlsTracking, skip).attributedString, for: .normal)
        skipButton.titleLabel?.textColor = UIColor.white
        skipButton.titleLabel?.textAlignment = .center
        self.addSubview(skipButton)
        skipButton.showsTouchWhenHighlighted = true
        skipButton.autoCenterInSuperview()
        skipButton.autoSet(dimension: .height, to: 50)
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
