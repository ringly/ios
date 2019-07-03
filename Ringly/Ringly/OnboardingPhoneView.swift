import UIKit

final class OnboardingPhoneView: UIView
{
    // MARK: - Subviews
    let screen = OnboardingScreenView.newAutoLayout()
    
    fileprivate let phone = UIView.newAutoLayout()
    fileprivate let phoneMask = CAShapeLayer()
    fileprivate let screenMask = CAShapeLayer()
    
    fileprivate func setup()
    {
        // add subviews
        let line = UIView.newAutoLayout()
        line.backgroundColor = UIColor.white
        addSubview(line)
        
        phone.backgroundColor = UIColor.white
        phone.layer.mask = phoneMask
        phoneMask.fillRule = kCAFillRuleEvenOdd
        addSubview(phone)
        
        let spacer = UIView.newAutoLayout()
        addSubview(spacer)

        // screen is added as a subview of this view, so that its frame is complete when we set its mask's shape
        screen.layer.mask = screenMask
        addSubview(screen)
        
        // layout
        line.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.zero, excluding: .top)
        line.autoSet(dimension: .height, to: 2)
        
        phone.autoPin(edge: .bottom, to: .top, of: line)
        phone.autoPinEdgeToSuperview(edge: .top)
        phone.autoAlignAxis(toSuperviewAxis: .vertical)
        phone.autoConstrain(attribute: .width, to: .width, of: self, multiplier: 0.8401898734)

        spacer.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.zero, excluding: .bottom)
        
        screen.autoPin(edge: .top, to: .bottom, of: spacer)
        screen.autoPin(edge: .bottom, to: .bottom, of: phone)
        screen.autoAlign(axis: .vertical, toSameAxisOf: phone)
        screen.autoConstrain(attribute: .width, to: .width, of: phone, multiplier: 0.9111531191)
        screen.autoConstrain(attribute: .height, to: .height, of: phone, multiplier: 0.8653576438)
        screen.autoConstrain(attribute: .width, to: .height, of: screen, multiplier: 0.7824675325)
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
    }
    
    // MARK: - Layout
    override func layoutSubviews()
    {
        super.layoutSubviews()
        
        // utility function for creating a mask path
        func pathForSize(_ size: CGSize, cornerFraction: CGFloat) -> CGMutablePath?
        {
            let corner = size.width * cornerFraction
            let path = CGMutablePath()

            path.move(to: CGPoint(x: 0, y: size.height))
            path.addLine(to: CGPoint(x: 0, y: corner))
            path.addArc(tangent1End: .zero, tangent2End: CGPoint(x: corner, y: 0), radius: corner)
            path.addLine(to: CGPoint(x: size.width - corner, y: 0))
            path.addArc(tangent1End: CGPoint(x: size.width, y: 0), tangent2End: CGPoint(x: size.width, y: corner), radius: corner)
            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.closeSubpath()
            
            return path
        }
        
        // add mask path for phone
        if let phonePath = pathForSize(phone.bounds.size, cornerFraction: 0.1001890359)
        {
            let phoneFrame = phone.frame

            let topRect = CGRect(
                x: 0,
                y: 0,
                width: phoneFrame.size.width,
                height: screen.frame.origin.y - phoneFrame.origin.y
            )

            let earpieceWidth = phoneFrame.size.width * 0.1433962264
            let earpieceSize = CGSize(width: earpieceWidth, height: earpieceWidth * 0.2133333333)

            phonePath.__addRoundedRect(transform: nil,
                rect: earpieceSize.centered(in: topRect),
                cornerWidth: earpieceSize.height / 2,
                cornerHeight: earpieceSize.height / 2
            )

            phoneMask.frame = phone.bounds
            phoneMask.path = phonePath
        }
        
        // add mask path for screen
        screenMask.frame = screen.bounds
        screenMask.path = pathForSize(screen.bounds.size, cornerFraction: 0.06846473029)
    }
}
