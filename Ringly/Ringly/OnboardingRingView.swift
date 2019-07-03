import ReactiveSwift
import UIKit

final class OnboardingRingView: UIView
{
    // MARK: - Subviews
    let stone = UIImageView.newAutoLayout()
    fileprivate let base = RingBaseView.newAutoLayout()
    
    // MARK: - Style
    let style = MutableProperty(RLYPeripheralStyle.undetermined)
    
    // MARK: - Initialization
    fileprivate func setup()
    {
        base.backgroundColor = UIColor.clear
        
        let spacer = UIView.newAutoLayout()
        
        addSubview(spacer)
        addSubview(stone)
        addSubview(base)
        
        // layout
        base.autoConstrain(attribute: .height, to: .width, of: self, multiplier: 1.1647058824)
        base.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.zero, excluding: .top)
        base.autoPin(edge: .top, to: .bottom, of: spacer)
        
        stone.autoPinEdgeToSuperview(edge: .top)
        stone.autoPin(edge: .bottom, to: .top, of: spacer)
        stone.autoAlignAxis(toSuperviewAxis: .vertical)
        stone.autoConstrain(attribute: .width, to: .width, of: self, multiplier: 0.6941176471, relation: .lessThanOrEqual)
        stone.autoConstrain(attribute: .width, to: .width, of: self, multiplier: 0.6882352941, relation: .greaterThanOrEqual)
        
        spacer.autoConstrain(attribute: .height, to: .height, of: self, multiplier: 0.01746724891)
        
        // style updates
        var lastAspectConstraint: NSLayoutConstraint?
        
        style.producer.startWithValues({ [weak self] style in
            self?.base.style = style
            self?.stone.image = RLYPeripheralStoneFromStyle(style).stoneImage
            
            lastAspectConstraint?.autoRemove()
            lastAspectConstraint = nil
            
            if let stone = self?.stone, let size = stone.image?.size
            {
                lastAspectConstraint = stone.autoConstrain(attribute: .width, to: .height, of: stone, multiplier: size.width / size.height)
            }
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
}

private final class RingBaseView: UIView
{
    fileprivate var style: RLYPeripheralStyle = .undetermined
    {
        didSet
        {
            setNeedsDisplay()
        }
    }
    
    fileprivate static func maskImageWithSize(_ size: CGSize) -> UIImage?
    {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)

        if let context = UIGraphicsGetCurrentContext()
        {
            // draw ring at bottom
            let thickness = 0.08080808081 * size.height
            let bottom = CGRect(x: 0, y: 0, width: size.width, height: size.width)
            let insetBottom = bottom.insetBy(dx: thickness / 2, dy: thickness / 2)
            
            context.saveGState()
            context.setLineWidth(thickness)
            context.setStrokeColor(gray: 0, alpha: 1)
            context.strokeEllipse(in: insetBottom)
            context.restoreGState()
            
            context.move(to: CGPoint(x: size.width * 0.1470588235, y: size.height))
            context.addLine(to: CGPoint(x: size.width * 0.1294117647, y: size.height - size.height * 0.1262626263))
            context.addLine(to: CGPoint(x: size.width * 0.2352941176, y: size.height - size.height * 0.2676767677))
            context.addLine(to: CGPoint(x: size.width - size.width * 0.2352941176, y: size.height - size.height * 0.2676767677))
            context.addLine(to: CGPoint(x: size.width - size.width * 0.1294117647, y: size.height - size.height * 0.1262626263))
            context.addLine(to: CGPoint(x: size.width - size.width * 0.1470588235, y: size.height))
            context.closePath()
            
            context.setFillColor(gray: 0, alpha: 1)
            context.fillPath()
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    fileprivate override func draw(_ rect: CGRect)
    {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        guard let mask = RingBaseView.maskImageWithSize(bounds.size)?.cgImage else { return }
        guard let gradient = RLYPeripheralBandFromStyle(style).ringBaseGradient else { return }

        context.saveGState()
        context.clip(to: bounds, mask: mask)
        
        context.drawLinearGradient(gradient,
            start: CGPoint.zero,
            end: CGPoint(x: 0, y: bounds.size.height),
            options: []
        )
        
        context.restoreGState()
    }
}

extension RLYPeripheralBand
{
    fileprivate var ringBaseGradient: CGGradient?
    {
        switch self
        {
        case .gold: fallthrough
        case .invalid: fallthrough
        case .undetermined:
            return CGGradient.create([
                (0, UIColor(red: 0.9358, green: 0.8431, blue: 0.4576, alpha: 1.0)),
                (0.1262626263, UIColor(red: 0.9358, green: 0.8431, blue: 0.4576, alpha: 1.0)),
                (0.1262626263, UIColor(red: 0.8389, green: 0.7572, blue: 0.3933, alpha: 1.0)),
                (0.2525252525, UIColor(red: 0.8389, green: 0.7572, blue: 0.3933, alpha: 1.0)),
                (1, UIColor(red: 0.9358, green: 0.8431, blue: 0.4576, alpha: 1.0)),
            ])

        case .silver: fallthrough
        case .rhodium:
            return CGGradient.create([
                (0, UIColor(red: 0.5998, green: 0.5998, blue: 0.5998, alpha: 1.0)),
                (0.1262626263, UIColor(red: 0.5998, green: 0.5998, blue: 0.5998, alpha: 1.0)),
                (0.1262626263, UIColor(red: 0.452, green: 0.4521, blue: 0.4521, alpha: 1.0)),
                (0.2525252525, UIColor(red: 0.452, green: 0.4521, blue: 0.4521, alpha: 1.0)),
                (1, UIColor(red: 0.5519, green: 0.5519, blue: 0.5519, alpha: 1.0)),
            ])
        }
    }
}

extension RLYPeripheralStone
{
    fileprivate var stoneImage: UIImage?
    {
        switch self
        {
        case .blackOnyx:
            return UIImage(asset: .onboardingStargaze)

        case .emerald:
            return UIImage(asset: .onboardingIntoTheWoods)

        case .labradorite:
            return UIImage(asset: .onboardingWanderlust)

        case .lapis:
            return UIImage(asset: .onboardingOutToSea)

        case .pinkChalecedony:
            return UIImage(asset: .onboardingDaybreak)

        case .pinkSapphire:
            return UIImage(asset: .onboardingWineBar)

        case .rainbowMoonstone:
            return UIImage(asset: .onboardingDaydream)

        case .tourmalatedQuartz:
            return UIImage(asset: .onboardingDiveBar)

        case .undetermined:
            return UIImage(asset: .onboardingDaydream)

        case .blueLaceAgate: fallthrough
        case .snowflakeObsidian: fallthrough
        case .invalid: fallthrough
        case .undetermined:
            return UIImage(asset: .onboardingWanderlust)
        }
    }
}
