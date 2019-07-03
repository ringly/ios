import RinglyExtensions
import UIKit

protocol GradientViewProtocol: class
{
    init()
    var gradient: CGGradient? { get set }
    var startPoint: CGPoint { get set }
    var endPoint: CGPoint { get set }
}

// MARK: - Static View
final class GradientView: UIView, GradientViewProtocol
{
    // MARK: - Gradient
    var gradient: CGGradient? = nil
    {
        didSet { setNeedsDisplay() }
    }

    // MARK: - Positioning
    var startPoint: CGPoint = CGPoint.zero
    {
        didSet { setNeedsDisplay() }
    }

    var endPoint: CGPoint = CGPoint(x: 1, y: 1)
    {
        didSet { setNeedsDisplay() }
    }

    // MARK: - Drawing
    override func draw(_ rect: CGRect)
    {
        guard let gradient = self.gradient, let context = UIGraphicsGetCurrentContext() else { return }

        let bounds = self.bounds

        context.drawLinearGradient(
            gradient,
            start: CGPoint(
                x: bounds.origin.x + bounds.size.width * startPoint.x,
                y: bounds.origin.y + bounds.size.height * startPoint.y
            ),
            end: CGPoint(
                x: bounds.origin.x + bounds.size.width * endPoint.x,
                y: bounds.origin.y + bounds.size.height * endPoint.y
            ),
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        )
    }
}

// MARK: - Animated View
class RotatingGradientView: DisplayLinkView
{
    fileprivate let gradientView = GradientView()

    override func didMoveToWindow()
    {
        super.didMoveToWindow()

        if gradientView.superview == nil
        {
            insertSubview(gradientView, at: 0)
        }
    }

    override func layoutSubviews()
    {
        super.layoutSubviews()

        let size = bounds.size
        let radius = sqrt(pow(size.width / 2, 2) + pow(size.height / 2, 2))

        gradientView.bounds = CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2)
        gradientView.center = CGPoint(x: size.width / 2, y: size.height / 2)
    }

    override func displayLinkCallback(_ displayLink: CADisplayLink)
    {
        let fraction = fmod(displayLink.timestamp, 4) / 4
        gradientView.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI * 2 * fraction))
    }
}

extension RotatingGradientView: GradientViewProtocol
{
    var gradient: CGGradient?
    {
        get { return gradientView.gradient }
        set { gradientView.gradient = newValue }
    }

    var startPoint: CGPoint
    {
        get { return gradientView.startPoint }
        set { gradientView.startPoint = newValue }
    }

    var endPoint: CGPoint
    {
        get { return gradientView.endPoint }
        set { gradientView.endPoint = newValue }
    }
}

// MARK: - Protocol Extensions
typealias GradientStop = (location: CGFloat, color: UIColor)

extension GradientViewProtocol
{
    func setGradient(start: GradientStop, end: GradientStop)
    {
        gradient = CGGradient.create([(start.location, start.color), (end.location, end.color)])
    }

    func setGradient(startColor: UIColor, endColor: UIColor)
    {
        gradient = CGGradient.create([(0, startColor), (1, endColor)])
    }
}

extension GradientViewProtocol where Self: UIView
{
    static func shadowGradientView(alpha: CGFloat) -> Self
    {
        let view = self.init()

        view.backgroundColor = .clear
        view.setGradient(startColor: UIColor(white: 0, alpha: 0), endColor: UIColor(white: 0, alpha: alpha))
        view.startPoint = .zero
        view.endPoint = CGPoint(x: 0, y: 1)

        return view
    }

    static var purpleBlueGradientView: Self
    {
        let view = self.init()
        view.setGradient(
            startColor: UIColor(red:0.7759, green:0.551, blue:0.7441, alpha:1.0),
            endColor: UIColor(red:0.3572, green:0.6399, blue:0.9064, alpha:1.0)
        )

        return view
    }

    static func pinkGradientView(start: CGFloat = 0, end: CGFloat = 1) -> Self
    {
        let view = self.init()
        view.setGradient(
            start: (location: start, color: UIColor.pinkGradientStart),
            end: (location: end, color: UIColor.pinkGradientEnd)
        )

        return view
    }

    static var blueGradientView: Self
    {
        let view = self.init()
        view.setGradient(
            startColor: UIColor(red:0.141, green:0.651, blue:0.918, alpha:1),
            endColor: UIColor(red:0.192, green:0.863, blue:0.773, alpha:1)
        )

        return view
    }

    static var blueGreenGradientView: Self
    {
        let view = self.init()

        view.setGradient(
            startColor: UIColor(red:52.0/255.0, green: 137.0/255.0, blue: 199.0/255.0, alpha:1.0),
            endColor: UIColor(red:49.0/255.0, green: 170.0/255.0, blue:132.0/255.0, alpha:1.0)
        )

        view.endPoint = CGPoint(x: 1, y: 0.5)

        return view
    }
    
    static var lightBlueGreenGradientView: Self
    {
        let view = self.init()
        
        view.setGradient(
            startColor: UIColor(red:72.0/255.0, green: 172.0/255.0, blue: 239.0/255.0, alpha:1.0),
            endColor: UIColor(red:53.0/255.0, green: 203.0/255.0, blue:156.0/255.0, alpha:1.0)
        )
        
        view.endPoint = CGPoint(x: 1, y: 0.5)
        
        return view
    }

    static var activityTrackingGradientView: Self
    {
        return pinkGradientView()
    }
    
    static var mindfulnessGradientView: Self
    {
        return lightBlueGreenGradientView
    }
}
