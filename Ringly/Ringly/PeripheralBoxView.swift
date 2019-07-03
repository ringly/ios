import PureLayout
import ReactiveSwift
import UIKit
import enum Result.NoError

final class PeripheralBoxView: UIView
{
    // MARK: - Appearance
    let inCharger = MutableProperty(false)
    let playingArrowAnimation = MutableProperty(false)

    var peripheralBackgroundColor: UIColor
    {
        get { return peripheralBackground.tintColor }
        set { peripheralBackground.tintColor = newValue }
    }

    // MARK: - Subviews
    fileprivate let peripheralBackground = UIImageView.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        // add the charger box image at the root level
        let boxView = UIImageView.newAutoLayout()
        let boxImage = UIImage(asset: .ringBox)
        boxView.image = boxImage
        addSubview(boxView)

        boxView.autoConstrainAspectRatio()
        boxView.autoFloatInSuperview()

        let topMeasure = UIView.newAutoLayout()
        addSubview(topMeasure)
        topMeasure.autoPin(edge: .top, to: .top, of: boxView)
        topMeasure.autoMatch(dimension: .height, to: .height, of: boxView, multiplier: 0.616)

        // add a clipping view, so that the bottom of the peripheral will disappear when it enters the box
        let clipView = UIView.newAutoLayout()
        clipView.clipsToBounds = true
        addSubview(clipView)

        clipView.autoPinEdgesToSuperviewEdges(excluding: .bottom)
        clipView.autoPin(edge: .bottom, to: .bottom, of: topMeasure)

        // add the peripheral image
        let peripheralView = UIView.newAutoLayout()
        clipView.addSubview(peripheralView)

        let peripheralOutlineImage = UIImage(asset: .ringOutlineSmall)
        peripheralView.autoAlignAxis(toSuperviewAxis: .vertical)
        peripheralView.autoMatch(
            dimension: .width,
            to: .width,
            of: boxView,
            multiplier: (peripheralOutlineImage?.size.width)! / (boxImage?.size.width)!
        )

        peripheralView.autoPin(edge: .top, to: .top, of: self, offset: 0, relation: .greaterThanOrEqual)

        peripheralBackground.image = UIImage(asset: .ringFillSmall).withRenderingMode(.alwaysTemplate)
        peripheralView.addSubview(peripheralBackground)
        peripheralBackground.autoPinEdgesToSuperviewEdges()

        let peripheralOutline = UIImageView.newAutoLayout()
        peripheralOutline.image = peripheralOutlineImage
        peripheralView.addSubview(peripheralOutline)
        peripheralOutline.autoPinEdgesToSuperviewEdges()
        peripheralOutline.autoConstrainAspectRatio()

        // add the arrow animation image
        let downArrow = UIImageView.newAutoLayout()
        downArrow.image = UIImage(asset: .ringDownArrow)
        clipView.addSubview(downArrow)
        downArrow.autoAlignAxis(toSuperviewAxis: .vertical)

        // move the peripheral in and out of the charger box
        let peripheralOut = peripheralView.autoConstrain(attribute: .top, to: .bottom, of: boxView, multiplier: 0.1428571429)
        let peripheralIn = peripheralView.autoConstrain(attribute: .top, to: .bottom, of: boxView, multiplier: 0.4897959184)

        inCharger.producer.startWithValues({ inCharger in
            NSLayoutConstraint.conditionallyActivateConstraints([
                (peripheralOut, !inCharger),
                (peripheralIn, inCharger)
            ])
        })

        // play the down arrow animation
        let arrowOut = downArrow.autoAlign(axis: .horizontal, toSameAxisOf: peripheralView, multiplier: 1.125)
        let arrowIn = downArrow.autoConstrain(attribute: .top, to: .bottom, of: clipView)

        let showArrow = playingArrowAnimation.producer.and(inCharger.producer.not).skipRepeats()

        showArrow.producer.flatMap(.latest, transform: { playing -> SignalProducer<(), NoError> in
            let initialize: SignalProducer<(), NoError> = SignalProducer.deferValue { [weak self] in
                downArrow.alpha = 0
                arrowIn.isActive = false
                arrowOut.isActive = true
                clipView.layoutIfInWindowAndNeeded()
            }

            if playing
            {
                func recursive() -> SignalProducer<(), NoError> {
                    return initialize
                        .then(UIView.animationProducer(duration: 0.37, animations: { downArrow.alpha = 1 }))
                        .then(UIView.animationProducer(duration: 1.125, animations: {
                            UIView.setAnimationCurve(.easeIn)
                            arrowOut.isActive = false
                            arrowIn.isActive = true
                            clipView.layoutIfInWindowAndNeeded()
                        }))
                        .delay(0.5, on: QueueScheduler.main)
                        .void
                        .then(SignalProducer.`defer`(recursive))
                }

                return recursive()
            }
            else
            {
                return initialize
            }
        }).take(until: reactive.lifetime.ended).start()
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
