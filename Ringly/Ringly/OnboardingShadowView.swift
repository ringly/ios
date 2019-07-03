import UIKit

/// A shadow view for the post-login onboarding process.
final class OnboardingShadowView: UIView
{
    // MARK: - Initialization
    fileprivate func setup()
    {
        backgroundColor = .clear
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

    // MARK: - Drawing
    override func draw(_ rect: CGRect)
    {
        UIColor(red: 0.7833, green: 0.53, blue: 0.8015, alpha: 0.8).setFill()
        UIBezierPath(ovalIn: bounds).fill()
    }
}
