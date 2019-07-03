import Foundation
import ReactiveSwift
import RinglyExtensions

struct ActivityProgressColorScheme
{
    let innerCircleStart:UIColor
    let innerCircleEnd:UIColor
    let outerRing:UIColor
    let progress:UIColor
    
    static func steps() -> ActivityProgressColorScheme {
        return ActivityProgressColorScheme(
            innerCircleStart: .white,
            innerCircleEnd: .white,
            outerRing: .progressPink,
            progress: .progressPurple
        )
    }
    
    static func stepsSmall() -> ActivityProgressColorScheme {
        return ActivityProgressColorScheme(
            innerCircleStart: .white,
            innerCircleEnd: .white,
            outerRing: UIColor(red: 247.0/255.0, green: 195.0/255.0, blue: 215.0/255.0, alpha: 1.0),
            progress: UIColor(red: 207.0/255.0, green: 139.0/255.0, blue: 210.0/255.0, alpha: 1.0)
        )
    }
    
    static func stepsDay() -> ActivityProgressColorScheme {
        return ActivityProgressColorScheme(
            innerCircleStart: .white,
            innerCircleEnd: .white,
            outerRing: UIColor(red: 240.0/255.0, green: 227.0/255.0, blue: 240.0/255.0, alpha: 1.0),
            progress: UIColor(red: 207.0/255.0, green: 139.0/255.0, blue: 210.0/255.0, alpha: 1.0)
        )
    }

    static func mindfulnessSmall() -> ActivityProgressColorScheme {
        return ActivityProgressColorScheme(
            innerCircleStart: .white,
            innerCircleEnd: .white,
            outerRing: UIColor(red: 211.0/255.0, green: 240.0/255.0, blue: 250.0/255.0, alpha: 1.0),
            progress: UIColor(red: 70.0/255.0, green: 170.0/255.0, blue: 240.0/255.0, alpha: 1.0)
        )
    }
    
    static func guidedAudioLarge() -> ActivityProgressColorScheme {
        return ActivityProgressColorScheme(
            innerCircleStart: .white,
            innerCircleEnd: .white,
            outerRing: UIColor(red: 241.0/255.0, green: 241.0/255.0, blue: 241.0/255.0, alpha: 1.0),
            progress: UIColor(red: 25.0/255.0, green: 147.0/255.0, blue: 187.0/255.0, alpha: 1.0)
        )
    }
}

final class ActivityProgressControl: UIControl
{
    // MARK: - Data

    /// The title content displayed by the control.
    let title = MutableProperty((text: String, icon: UIImage?)?.none)

    /// The current data displayed by the control.
    let data = MutableProperty(ActivityControlData?.none)
    
    let colorScheme = MutableProperty(ActivityProgressColorScheme.steps())
    
    let contentHidden = MutableProperty<Bool>(false)

    // MARK: - Subviews

    /// The outer circle providing the unfilled progress.
    fileprivate let outerCircleView = UIView.newAutoLayout()

    /// The layer providing a shadow under `centerView`.
    fileprivate let shadowLayer = CALayer()

    /// The center white-ish gradient view.
    fileprivate let centerView = GradientView.newAutoLayout()

    /// The progress layer, showing the current progress around `centerView`.
    fileprivate let progressLayer = CAShapeLayer()

    /// The current bounds of the view, used to generate a bezier path for `progressLayer`.
    fileprivate let currentBounds = MutableProperty(CGRect?.none)

    /// The stroke width of `progressLayer`.
    fileprivate let strokeWidth: CGFloat

    // MARK: - Initialization
    fileprivate func setup()
    {
        // update view appearance
        outerCircleView.isUserInteractionEnabled = false
        outerCircleView.clipsToBounds = true
        addSubview(outerCircleView)

        // add progress layer
        progressLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransform(rotationAngle: -CGFloat(M_PI) / 2))
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = self.strokeWidth + 1 // removes antialiasing artifacts, is clipped
        outerCircleView.layer.addSublayer(progressLayer)

        // add shadow layer
        shadowLayer.shadowColor = UIColor.black.cgColor
        shadowLayer.shadowOpacity = 0.3


        centerView.startPoint = .zero
        centerView.endPoint = CGPoint(x: 1, y: 1)
        centerView.clipsToBounds = true
        centerView.isUserInteractionEnabled = false
        addSubview(centerView)

        // add content view
        let content = ActivityProgressControlContentView.newAutoLayout()
        content.reactive.isHidden <~ self.contentHidden
        content.isUserInteractionEnabled = false
        addSubview(content)
        
        
        content.autoMatch(dimension: .width, to: .width, of: self, multiplier: 0.8)
        content.autoMatch(dimension: .height, to: .height, of: self, multiplier: 0.8)

        // layout
        outerCircleView.autoPinEdgesToSuperviewEdges()

        centerView.autoPinEdgesToSuperviewEdges(insets: 
            UIEdgeInsets(
                top: self.strokeWidth,
                left: self.strokeWidth,
                bottom: self.strokeWidth,
                right: self.strokeWidth
            )
        )

        content.autoCenterInSuperview()

        currentBounds.producer.skipNil().skipRepeats()
            .map({ bounds in
                UIBezierPath(ovalIn: bounds.insetBy(
                    dx: self.strokeWidth / 2,
                    dy: self.strokeWidth / 2
                ))
            })
            .startWithValues({ [weak progressLayer] path in
                progressLayer?.path = path.cgPath
            })

        data.producer
            .map({ $0?.progress ?? 0 })
            .startWithValues({ [weak progressLayer] progress in
                if progress == 0.0 {
                    self.resetProgress()
                } else {
                    progressLayer?.strokeStart = 0
                    progressLayer?.strokeEnd = max(progress, 0.000001)
                }
            })

        // bind title content
        title.producer.startWithValues({ title in
            content.title.attributedText = (title?.text).map({
                UIFont.gothamBook(12).track(150, $0).attributedString
            })

        })

        // bind label content
        data.producer
            .map({ $0?.valueText ?? .standalone("--") })
            .skipRepeats(==)
            .observe(on: UIScheduler())
            .startCrossDissolve(in: content.value, duration: 0.1, action: {
                let screenOffset:CGFloat = DeviceScreenHeight.current.select(four: 0, five: 0, six: 6, sixPlus: 6, preferred: 0)
                var valueFont = UIFont.gothamBook(20.0 + screenOffset)

                if $0.valueLength() > 4 {
                    valueFont = UIFont.gothamBook(17.0 + screenOffset)
                }
                switch $0 {
                case .standalone(let value):
                    content.value.attributedText = valueFont.track(150, value).attributedString
                default:
                    break
                }
            })
        
        colorScheme.producer.startWithValues({ [weak self] colorScheme in
            self?.centerView.setGradient(
                startColor: colorScheme.innerCircleStart,
                endColor: colorScheme.innerCircleEnd
            )
            
            self?.outerCircleView.backgroundColor = colorScheme.outerRing
            self?.progressLayer.strokeColor = colorScheme.progress.cgColor
        })
    }
    override func updateConstraints() {
        super.updateConstraints()
        
        self.centerView.setGradient(
            startColor: colorScheme.value.innerCircleStart,
            endColor: colorScheme.value.innerCircleEnd
        )
    }
    
    init(strokeWidth: CGFloat, withShadow: Bool) {
        self.strokeWidth = strokeWidth
        
        super.init(frame: CGRect.zero)
        self.setup()
        if withShadow {
            layer.insertSublayer(shadowLayer, at: 0)
        }
    }

    func resetProgress() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.progressLayer.strokeEnd = 0.0
        CATransaction.commit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout
    override func layoutSubviews()
    {
        super.layoutSubviews()

        // redraw the path bounds
        let bounds = self.bounds
        progressLayer.frame = bounds
        currentBounds.value = bounds

        // update shadow apperance
        let centerFrame = centerView.frame

        let shadowSize = CGSize(
            width: centerFrame.size.width * 0.91,
            height: centerFrame.size.height * 0.91
        )

        shadowLayer.frame = CGRect(
            x: centerFrame.midX - shadowSize.width / 2,
            y: centerFrame.midY - shadowSize.height / 2,
            width: shadowSize.width,
            height: shadowSize.height
        )

        shadowLayer.shadowPath = UIBezierPath(ovalIn: shadowLayer.bounds).cgPath
        shadowLayer.shadowRadius = 0.34 * centerFrame.size.height
        shadowLayer.shadowOffset = CGSize(width: 0, height: 0.08 * centerFrame.size.height)

        // update corner radii
        outerCircleView.layer.cornerRadius = outerCircleView.bounds.size.width / 2
        centerView.layer.cornerRadius = centerView.bounds.size.width / 2
    }
}

final class ActivityProgressControlContentView: UIView
{
    // MARK: - Labels
    let title = UILabel.newAutoLayout()
    let value = UILabel.newAutoLayout()
    let header = UILabel.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        title.textAlignment = .center
        title.textColor = UIColor(white: 0.2, alpha: 0.5)
        addSubview(title)

        title.autoAlignAxis(toSuperviewAxis: .vertical)

        value.textAlignment = .center
        value.textColor = UIColor(white: 0.33, alpha: 1)
        addSubview(value)

        value.autoAlign(axis: .horizontal, toSameAxisOf: self, offset: -6.0)
        value.autoAlignAxis(toSuperviewAxis: .vertical)
        title.autoPin(edge: .top, to: .bottom, of: value, offset: 1.0)
        
        header.textAlignment = .center
        header.textColor = UIColor(white: 0.2, alpha: 0.5)
        addSubview(header)
        header.autoAlignAxis(toSuperviewAxis: .vertical)
        header.autoPin(edge: .bottom, to: .top, of: value, offset: 1.0)
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
