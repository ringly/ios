import PureLayout
import ReactiveSwift
import UIKit

private let rowCornerRadius: CGFloat = 6

final class ApplicationsOnboardingAnimationView: UIView
{
    let phase = MutableProperty(LayoutPhase.grid)
    
    // MARK: - Subviews
    let rows = [
        UIView.newAutoLayout(),
        UIView.newAutoLayout(),
        UIView.newAutoLayout(),
        UIView.newAutoLayout()
    ]
    
    let vibrations = [
        UIImageView.newAutoLayout(),
        UIImageView.newAutoLayout(),
        UIImageView.newAutoLayout(),
        UIImageView.newAutoLayout()
    ]
    
    let icons = [
        UIImageView.newAutoLayout(),
        UIImageView.newAutoLayout(),
        UIImageView.newAutoLayout(),
        UIImageView.newAutoLayout(),
        UIImageView.newAutoLayout(),
        UIImageView.newAutoLayout(),
        UIImageView.newAutoLayout(),
        UIImageView.newAutoLayout()
    ]
    
    // MARK: - Initialization
    fileprivate func setup()
    {
        // setup for icons
        icons[0].image = UIImage(asset: .onboardingPhone)
        icons[1].image = UIImage(asset: .onboardingMessages)
        icons[2].image = UIImage(asset: .onboardingMail)
        icons[3].image = UIImage(asset: .onboardingCalendar)
        icons[4].image = UIImage(asset: .onboardingWhatsApp)
        icons[5].image = UIImage(asset: .onboardingInstagram)
        icons[6].image = UIImage(asset: .onboardingFacebook)
        icons[7].image = UIImage(asset: .onboardingTwitter)
        
        // setup for rows
        rows[0].backgroundColor = UIColor.ringlyBlue
        rows[1].backgroundColor = UIColor.ringlyGreen
        rows[2].backgroundColor = UIColor.ringlyYellow
        rows[3].backgroundColor = UIColor.ringlyPurple
        
        vibrations[0].image = UIImage(asset: .vibrations4)
        vibrations[1].image = UIImage(asset: .vibrations3)
        vibrations[2].image = UIImage(asset: .vibrations2)
        vibrations[3].image = UIImage(asset: .vibrations1)
        
        // add subviews
        rows.forEach(addSubview)
        icons.forEach(addSubview)
        
        for (row, vibration) in zip(rows, vibrations)
        {
            row.layer.cornerRadius = rowCornerRadius
            row.addSubview(vibration)
        }
        
        // icons layout
        for icon in icons
        {
            guard let size = icon.image?.size else { continue }
            
            icon.autoConstrain(attribute: .width, to: .width, of: self, multiplier: size.width / 240.0)
            icon.autoConstrain(attribute: .height, to: .width, of: icon, multiplier: size.height / size.width)
        }
        
        var gridConstraints = [NSLayoutConstraint]()
        var sideConstraints = [NSLayoutConstraint]()
        
        for i in 0..<4
        {
            icons[i * 2].autoConstrain(attribute: .horizontal, to: .bottom, of: self, multiplier: 0.125 + 0.25 * CGFloat(i))
            icons[i * 2 + 1].autoConstrain(attribute: .horizontal, to: .bottom, of: self, multiplier: 0.125 + 0.25 * CGFloat(i))
            
            gridConstraints += [
                icons[i * 2].autoConstrain(attribute: .vertical, to: .trailing, of: self, multiplier: 0.3041666667),
                icons[i * 2 + 1].autoConstrain(attribute: .vertical, to: .trailing, of: self, multiplier: 0.6958333333)
            ]
            
            sideConstraints += [
                icons[i * 2].autoConstrain(attribute: .vertical, to: .trailing, of: self, multiplier: 0.2291666667),
                icons[i * 2 + 1].autoConstrain(attribute: .vertical, to: .trailing, of: self, multiplier: 0.2291666667)
            ]
        }
        
        // rows layout
        for row in rows
        {
            row.autoPinEdgeToSuperview(edge: .leading, inset: -rowCornerRadius)
        }
        
        (rows as NSArray).autoDistributeViews(along: .vertical, alignedTo: .leading, fixedSpacing: 0)
        
        rows[0].autoPinEdgeToSuperview(edge: .leading, inset: -rowCornerRadius)
        
        let trailingConstraints = rows.map({ row in
            row.autoPinEdgeToSuperview(edge: .trailing, inset: -rowCornerRadius)
        })
        
        // vibrations layout
        for (vibration, row) in zip(vibrations, rows)
        {
            vibration.autoAlignAxis(toSuperviewAxis: .horizontal)
            vibration.autoConstrain(attribute: .height, to: .height, of: row, multiplier: 0.3076923077)
            vibration.autoConstrain(attribute: .vertical, to: .trailing, of: self, multiplier: 1 - 0.2291666667)
            
            let size = vibration.image?.size ?? CGSize(width: 1, height: 1)
            vibration.autoConstrain(attribute: .width, to: .height, of: vibration, multiplier: size.width / size.height)
        }
        
        // layout changes
        phase.producer.startWithValues({ phase in
            var active = [NSLayoutConstraint]()
            var inactive = [NSLayoutConstraint]()
            
            if phase == .grid
            {
                active += gridConstraints
                inactive += sideConstraints
            }
            else
            {
                active += sideConstraints
                inactive += gridConstraints
            }
            
            for constraint in inactive
            {
                constraint.isActive = false
            }
            
            for constraint in active
            {
                constraint.isActive = true
            }
            
            trailingConstraints[0].isActive = phase >= LayoutPhase.expandFirst
            trailingConstraints[1].isActive = phase >= LayoutPhase.expandSecond
            trailingConstraints[2].isActive = phase >= LayoutPhase.expandThird
            trailingConstraints[3].isActive = phase >= LayoutPhase.expandFourth
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
    
    enum LayoutPhase: Int, Comparable
    {
        case grid
        case lineup
        case expandFirst
        case expandSecond
        case expandThird
        case expandFourth
    }
}

func <(lhs: ApplicationsOnboardingAnimationView.LayoutPhase, rhs: ApplicationsOnboardingAnimationView.LayoutPhase) -> Bool
{
    return lhs.rawValue < rhs.rawValue
}
