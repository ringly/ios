import UIKit

final class OnboardingStepsView: UIView
{
    // MARK: - Initialization
    fileprivate func setup()
    {
        let imageView = UIImageView.newAutoLayout()
        imageView.image = UIImage(asset: .onboardingStepsShoes)
        addSubview(imageView)
        
        imageView.autoConstrainAspectRatio()
        imageView.autoFloatInSuperview()
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
