import UIKit

final class OnboardingCaloriesView: UIView
{
    // MARK: - Initialization
    fileprivate func setup()
    {
        let shadow = OnboardingShadowView.newAutoLayout()
        addSubview(shadow)

        let imageView = UIImageView.newAutoLayout()
        imageView.image = UIImage(asset: .onboardingCaloriesFlame)
        addSubview(imageView)

        imageView.autoConstrainAspectRatio()
        imageView.autoFloatInSuperview()

        shadow.autoPinEdgeToSuperview(edge: .bottom)
        shadow.autoFloatInSuperview(alignedTo: .vertical)
        shadow.autoConstrain(attribute: .horizontal, to: .bottom, of: imageView)
        shadow.autoMatch(dimension: .width, to: .height, of: shadow, multiplier: 13.1111)
        shadow.autoMatch(dimension: .width, to: .width, of: imageView, multiplier: 0.9874476987)
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
