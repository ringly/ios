import PureLayout
import ReactiveSwift
import UIKit


final class BatteryView: UIView
{
    let percentage = MutableProperty(0)
    let config = MutableProperty(SizeConfig.large)
    
    fileprivate let body = UIView.newAutoLayout()
    fileprivate let pole = UIView.newAutoLayout()

    fileprivate let indicator = BatteryIndicatorView.newAutoLayout()


    // MARK: - Initialization
    private func setup()
    {

        // create the battery icon
        let borderColor = self.tintColor.cgColor

        body.layer.borderColor = borderColor
        body.layer.borderWidth = 1
        addSubview(body)

        pole.layer.borderColor = borderColor
        pole.layer.borderWidth = 1
        addSubview(pole)


        pole.autoAlignAxis(toSuperviewAxis: .horizontal)

        // add the battery indicator inside the main battery view
        indicator.percentage <~ percentage
        body.addSubview(indicator)

        
        self.config.signal.observeValues({ [unowned self] config in
            // set fixed size for icon
            self.autoSetDimensions(to: config.size)
            self.pole.autoSetDimensions(to: config.poleSize)
            self.pole.autoPinEdgeToSuperview(edge: .right, inset: config.poleInset)
            self.body.autoPin(edge: .right, to: .left, of: self.pole, offset: config.poleInset)
            [ALEdge.top, .bottom, .left].forEach({ edge in self.body.autoPinEdgeToSuperview(edge: edge, inset: config.poleInset) })

            self.indicator.autoPinEdgesToSuperviewEdges(insets: config.indicatorInset)
            
            self.body.layer.cornerRadius = config.cornerRadius
            self.pole.layer.cornerRadius = config.cornerRadius
            
            self.body.layer.masksToBounds = true

            self.indicator.fallback.value = config.fallback
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
    
    override func tintColorDidChange() {
        body.layer.borderColor = self.tintColor.cgColor
        pole.layer.borderColor = self.tintColor.cgColor
        self.indicator.tintColor = self.tintColor
        self.indicator.setNeedsDisplay()
    }
}

fileprivate final class BatteryIndicatorView: UIView
{
    let percentage = MutableProperty(0)
    let fallback = MutableProperty<CGFloat>(3.0)

    // MARK: - Initialization
    fileprivate func setup()
    {
        backgroundColor = .clear
        percentage.signal.observeValues({ [weak self] _ in self?.setNeedsDisplay() })
        fallback.signal.observeValues({ [weak self] _ in self?.setNeedsDisplay() })
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
    fileprivate override func draw(_ rect: CGRect)
    {
        // don't draw anything for an empty battery
        let percentage = self.percentage.value
        guard percentage > 0 else { return }

        // the amount of "slant" on the battery indicator
        let fallback: CGFloat = self.fallback.value

        let bounds = self.bounds
        let path = UIBezierPath()
        path.move(to: CGPoint(x: bounds.minX, y: bounds.maxY))

        let width = CGFloat(percentage) / 100 * (bounds.size.width + fallback)
        path.addLine(to: CGPoint(x: bounds.minX + width, y: bounds.maxY))
        path.addLine(to: CGPoint(x: bounds.minX + width - fallback, y: bounds.minY))
        path.addLine(to: CGPoint(x: bounds.minX - fallback, y: bounds.minY))
        path.close()

        self.tintColor.setFill()
        path.fill()
    }
}

enum SizeConfig {
    case small
    case large
    
    
    var size:CGSize {
        switch self {
        case .small:
            return CGSize(width: 11, height: 7)
        case .large:
            return CGSize(width: 31, height: 16)
        }
    }
    
    var poleSize: CGSize {
        switch self {
        case .small:
            return CGSize(width: 1.1, height: 3)
        case .large:
            return CGSize(width: 4, height: 8)
        }
    }
    
    var indicatorInset: UIEdgeInsets {
        switch self {
        case .small:
            return UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        case .large:
            return UIEdgeInsets(top: 2.5, left: 3, bottom: 2.5, right: 3)
        }
    }
    
    var poleInset: CGFloat {
        switch self {
        case .small:
            return 0.0
        case .large:
            return 0.5
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small:
            return 1.0
        case .large:
            return 0.0
        }
    }
    
    var fallback: CGFloat {
        switch self {
        case .small:
           return 0.0
        case .large:
           return 3.0
        }
    }
}
