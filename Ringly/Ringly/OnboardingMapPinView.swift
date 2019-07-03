import UIKit

final class OnboardingMapPinView: UIView
{
    // MARK: - Initialization
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        backgroundColor = .clear
    }

    // MARK: - Drawing
    override func draw(_ rect: CGRect)
    {
        let size = bounds.size

        func x(_ input: CGFloat) -> CGFloat
        {
            return (input / 122) * size.width
        }

        func y(_ input: CGFloat) -> CGFloat
        {
            return (input / 180) * size.height
        }

        // largely PaintCode generated
        let path = UIBezierPath()
        path.move(to: CGPoint(x: x(122), y: y(61)))
        path.addCurve(to: CGPoint(x: x(61), y: y(180)), controlPoint1: CGPoint(x: x(122), y: y(94.69)), controlPoint2: CGPoint(x: x(80), y: y(150)))
        path.addCurve(to: CGPoint(x: x(0), y: y(61)), controlPoint1: CGPoint(x: x(42), y: y(150)), controlPoint2: CGPoint(x: x(0), y: y(94.69)))
        path.addCurve(to: CGPoint(x: x(61), y: y(0)), controlPoint1: CGPoint(x: x(0), y: y(27.31)), controlPoint2: CGPoint(x: x(27.31), y: y(0)))
        path.addCurve(to: CGPoint(x: x(122), y: y(61)), controlPoint1: CGPoint(x: x(94.69), y: y(0)), controlPoint2: CGPoint(x: x(122), y: y(27.31)))
        path.close()
        UIColor(red: 0.3063, green: 0.9023, blue: 0.7097, alpha: 1.0).setFill()
        path.fill()

        UIColor.white.setFill()
        UIBezierPath(ovalIn: CGRect(x: x(43), y: y(45), width: x(37), height: y(37))).fill()
    }
}
