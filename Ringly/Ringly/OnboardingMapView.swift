import ReactiveSwift
import UIKit
import enum Result.NoError

final class OnboardingMapView: UIView
{
    // MARK: - Subviews
    fileprivate let largePin = OnboardingMapPinView.newAutoLayout()
    fileprivate let largePinShadow = OnboardingShadowView.newAutoLayout()
    fileprivate let smallPin = OnboardingMapPinView.newAutoLayout()
    fileprivate let smallPinShadow = OnboardingShadowView.newAutoLayout()
    fileprivate let path = OnboardingMapPathView.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        // add views
        [largePinShadow, largePin, smallPinShadow, smallPin, path].forEach(addSubview)

        // maintain aspect ratios
        autoMatch(dimension: .width, to: .height, of: self, multiplier: 1.2429577465)

        [largePin, smallPin].forEach({ pin in
            pin.autoMatch(dimension: .width, to: .height, of: pin, multiplier: 0.7071823204)
        })

        largePinShadow.autoMatch(dimension: .width, to: .height, of: largePinShadow, multiplier: 5.7368)
        smallPinShadow.autoMatch(dimension: .width, to: .height, of: smallPinShadow, multiplier: 5.6667)

        // place shadows
        [(largePin, largePinShadow), (smallPin, smallPinShadow)].forEach({ pin, shadow in
            shadow.autoConstrain(attribute: .horizontal, to: .bottom, of: pin)
            shadow.autoAlign(axis: .vertical, toSameAxisOf: pin)
        })

        largePinShadow.autoMatch(dimension: .width, to: .width, of: largePin, multiplier: 0.8861788618)
        smallPinShadow.autoMatch(dimension: .width, to: .width, of: smallPin, multiplier: 1.1724137931)

        // place pins
        largePin.autoPinEdgeToSuperview(edge: .left)
        largePin.autoConstrain(attribute: .top, to: .bottom, of: self, multiplier: 0.3309859155)
        largePin.autoMatch(dimension: .width, to: .width, of: self, multiplier: 0.3371104816)

        smallPin.autoPinEdgeToSuperview(edge: .top)
        smallPin.autoPinEdgeToSuperview(edge: .right)
        smallPin.autoMatch(dimension: .width, to: .width, of: self, multiplier: 0.164305949)

        // place path
        path.autoPinEdgeToSuperview(edge: .bottom)
        path.autoConstrain(attribute: .left, to: .right, of: self, multiplier: 0.2181303116)
        path.autoConstrain(attribute: .right, to: .right, of: self, multiplier: 0.9320113314)
        path.autoMatch(dimension: .width, to: .height, of: path, multiplier: 1.3)

        // initialize fade-out
        smallPin.alpha = 0
        largePin.alpha = 0
        smallPinShadow.alpha = 0
        largePinShadow.alpha = 0
        path.strokeProgress = 0
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

    // MARK: - Animation

    /// A signal producer that will play the view's path-growing animation.
    
    func animationProducer() -> SignalProducer<(), NoError>
    {
        return UIView.animationProducer(duration: 0.25, animations: { [weak self] in
                self?.largePin.alpha = 1
                self?.largePinShadow.alpha = 1
            })
            .then(path.fillShapeProducer(duration: 1))
            .then(UIView.animationProducer(duration: 0.25, animations: { [weak self] in
                self?.smallPin.alpha = 1
                self?.smallPinShadow.alpha = 1
            }))
            .void
    }
}
