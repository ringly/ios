import ReactiveSwift
import RinglyExtensions
import RinglyKit
import UIKit
import enum Result.NoError

final class PeripheralImageControl: UIControl
{
    // MARK: - Style
    var style: RLYPeripheralStyle?
    {
        didSet
        {
            let type = style.map(RLYPeripheralTypeFromStyle) ?? .ring
            peripheralView.image = style?.image ?? type.image
            shadowView.image = type.shadowImage

            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    // MARK: - Layout Mode

    /// Defines the cases for the `layoutMode` property.
    enum LayoutMode { case shadowInside, shadowOutside }

    /// The current layout mode - whether or not the shadow should be inside or outside the view's bounds.
    var layoutMode = LayoutMode.shadowInside { didSet { setNeedsLayout() } }

    // MARK: - Subviews

    /// A transform applied to the peripheral view (but not the shadow view).
    var peripheralTransform: CGAffineTransform
    {
        get { return peripheralView.transform }
        set { peripheralView.transform = newValue }
    }

    /// The image view for displaying a peripheral image.
    fileprivate let peripheralView = UIImageView.newAutoLayout()

    /// The image view for displaying a shadow image.
    fileprivate let shadowView = UIImageView.newAutoLayout()

    /// The current glow view, if any.
    fileprivate var glow: (view: UIView, offset: CGPoint)?

    // MARK: - Initialization
    fileprivate func setup()
    {
        // adding subviews
        peripheralView.isUserInteractionEnabled = false
        addSubview(peripheralView)

        shadowView.isUserInteractionEnabled = false
        addSubview(shadowView)

        // highlight when tapped
        reactive.highlighted.startWithValues({ [weak self] highlighted in
            self?.alpha = highlighted ? 0.8 : 1
        })
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

    // MARK: - Layout
    fileprivate var imageLayoutSizes: (peripheral: CGSize, shadow: CGSize, padding: CGFloat)?
    {
        let shadowSize = shadowView.image?.size ?? CGSize.zero

        return unwrap(
            peripheralView.image?.size,
            shadowSize,
            shadowSize.height > 0 ? 10 : 0
        )
    }

    override var intrinsicContentSize : CGSize
    {
        if let (peripheralSize, shadowSize, padding) = imageLayoutSizes
        {
            switch layoutMode
            {
            case .shadowInside:
                return CGSize(
                    width: max(peripheralSize.width, shadowSize.width),
                    height: peripheralSize.height + shadowSize.height + padding
                )

            case .shadowOutside:
                return peripheralSize
            }
        }
        else
        {
            return .zero
        }
    }

    override func layoutSubviews()
    {
        super.layoutSubviews()

        // if we don't have current images, there's no need to perform layout, nothing is visible
        guard let (peripheralSize, shadowSize, padding) = imageLayoutSizes else { return }

        let bounds = self.bounds

        switch layoutMode
        {
        case .shadowInside:
            let totalSize = CGSize(
                width: max(peripheralSize.width, shadowSize.width),
                height: peripheralSize.height + shadowSize.height + padding
            )

            let fitSize = totalSize.aspectFit(in: bounds.size)
            let factor = fitSize.width / totalSize.width

            let fitPeripheralSize = CGSize(width: peripheralSize.width * factor, height: peripheralSize.height * factor)
            let fitShadowSize = CGSize(width: shadowSize.width * factor, height: shadowSize.height * factor)

            peripheralView.frame = CGRect(
                origin: CGPoint(
                    x: bounds.midX - fitPeripheralSize.width / 2,
                    y: bounds.midY - fitSize.height / 2
                ),
                size: fitPeripheralSize
            )

            shadowView.frame = CGRect(
                origin: CGPoint(
                    x: bounds.midX - fitShadowSize.width / 2,
                    y: bounds.midY + fitSize.height / 2 - fitShadowSize.height
                ),
                size: fitShadowSize
            )

        case .shadowOutside:
            let fitPeripheralSize = peripheralSize.aspectFit(in: bounds.size)
            let factor = fitPeripheralSize.width / peripheralSize.width
            let fitShadowSize = CGSize(width: shadowSize.width * factor, height: shadowSize.height * factor)

            let peripheralFrame = CGRect(
                origin: CGPoint(
                    x: bounds.midX - fitPeripheralSize.width / 2,
                    y: bounds.midY - fitPeripheralSize.height / 2
                ),
                size: fitPeripheralSize
            )

            peripheralView.frame = peripheralFrame

            shadowView.frame = CGRect(
                origin: CGPoint(
                    x: bounds.midX - fitShadowSize.width / 2,
                    y: peripheralFrame.maxY + padding * factor
                ),
                size: fitShadowSize
            )
        }

        // adjust the glow view
        let glowSize = PeripheralImageControl.glowSize

        if let (glowView, offset) = glow
        {
            let peripheralFrame = peripheralView.frame

            glowView.frame = CGRect(
                origin: CGPoint(
                    x: peripheralFrame.minX + offset.x * peripheralFrame.size.width - glowSize / 2,
                    y: peripheralFrame.minY + offset.y * peripheralFrame.size.height - glowSize / 2
                ),
                size: CGSize(width: glowSize, height: glowSize)
            )
        }
    }
}

extension PeripheralImageControl
{
    // MARK: - Vibration Effect

    /**
    A signal producer for vibrating the specified peripheral and moving the peripheral on the screen.

    - parameter peripheral: The peripheral to vibrate.
    */
    func producerForVibrating(peripheral: RLYPeripheral) -> SignalProducer<(), NoError>
    {
        let delayBeforeVibration: DispatchTimeInterval = .milliseconds(25)
        let vibrationDuration: TimeInterval = 0.4
        let delayBeforeGlow: TimeInterval = 0
        let glowFadeTime: TimeInterval = 0.2
        let glowDuration: TimeInterval = 0.9

        return timer(interval: delayBeforeVibration, on: QueueScheduler.main)
            .on(started: {
                peripheral.write(command: RLYColorVibrationCommand(azureColorAndVibration: .onePulse))
            })
            .take(first: 1)
            .on(completed: {
                self.rly_wiggle(withMoves: 9, distance: CGSize(width: 3, height: 0), duration: vibrationDuration)
            })
            .delay(vibrationDuration + delayBeforeGlow, on: QueueScheduler.main)
            .then(SignalProducer.`defer` { [weak self] () -> SignalProducer<(), NoError> in
                guard let strong = self else { return SignalProducer.empty }

                let glowView = UIImageView.newAutoLayout()
                glowView.image = PeripheralImageControl.glowImage
                glowView.alpha = 0

                strong.glow = (view: glowView, offset: peripheral.offsetForGlow)

                if peripheral.glowAbovePeripheral
                {
                    strong.addSubview(glowView)
                }
                else
                {
                    strong.insertSubview(glowView, belowSubview: strong.peripheralView)
                }

                // fade the glow in and out
                return UIView.animationProducer(duration: glowFadeTime, animations: {
                        glowView.alpha = 1
                    })
                    .delay(glowDuration, on: QueueScheduler.main)
                    .then(UIView.animationProducer(duration: glowFadeTime, animations: {
                        glowView.alpha = 0
                    }))
                    .on(completed: { [weak self] in
                        glowView.removeFromSuperview()
                        self?.glow = nil
                    })
                    .ignoreValues()
            })
            .ignoreValues()
    }

    /// An image for the peripheral LED glow effect.
    fileprivate static var glowImage: UIImage?
    {
        // this rect will be filled with blue glow ("shadow", actually)
        let rect = CGRect(x: 0, y: 0, width: glowSize, height: glowSize)

        // full opacity blue
        let lightRect = rect.insetBy(dx: (glowSize - glowCenterSize) / 2, dy: (glowSize - glowCenterSize) / 2)

        // slightly inset, and filled white, but it looks a lot like "light" blue
        let whiteFactor: CGFloat = 0.9
        let whiteRect = lightRect.insetBy(dx: lightRect.size.width - lightRect.size.width * whiteFactor,
            dy: lightRect.size.height - lightRect.size.height * whiteFactor
        )

        // create an image context for the full size
        UIGraphicsBeginImageContext(rect.size)

        if let ctx = UIGraphicsGetCurrentContext()
        {
            // add the glow shadow - it's rendered twice so the gradient is more "aggressive"
            ctx.setShadow(offset: CGSize.zero, blur: lightRect.origin.x, color: UIColor.ringlyBlue.cgColor)

            // render the full opacity blue and white, rendering the shadow once for each
            UIColor.ringlyBlue.set()
            UIBezierPath(ovalIn: lightRect).fill()

            UIColor.white.set()
            UIBezierPath(ovalIn: whiteRect).fill()
        }

        // get the derived image for the light
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    fileprivate static let glowSize: CGFloat = 30
    fileprivate static let glowCenterSize: CGFloat = 6
}

extension RLYPeripheralType
{
    fileprivate var shadowImage: UIImage?
    {
        switch self
        {
        case .bracelet:
            return UIImage(asset: .shadowBracelet)
        default:
            return nil
        }
    }
}

extension RLYPeripheral
{
    /// The offset for the glow image shown after tapping on the peripheral's icon.
    fileprivate var offsetForGlow: CGPoint
    {
        
        switch type
        {
        case .bracelet:
            switch style
            {
            case .go01:
                return CGPoint(x: 0.5, y: 0.77)
            case .go02:
                return CGPoint(x: 0.5, y: 0.77)
            default:
                return CGPoint(x: 0.5, y: 0.54)
            }
        default:
            return CGPoint(x: 0.9, y: 0.4)
        }
    }

    fileprivate var glowAbovePeripheral: Bool
    {
        switch type
        {
        case .bracelet:
            return true
        default:
            return false
        }
    }
}
