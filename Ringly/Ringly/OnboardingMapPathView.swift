import ReactiveSwift
import UIKit
import enum Result.NoError

final class OnboardingMapPathView: UIView
{
    // MARK: - Layer
    fileprivate let shape = CAShapeLayer()
    fileprivate let shapeDelegate = ShapeLayerDelegate()

    // MARK: - Stroke Progress
    var strokeProgress: CGFloat
    {
        get { return shape.strokeEnd }
        set { shape.strokeEnd = newValue }
    }

    // MARK: - Initialization
    fileprivate func setup()
    {
        //shape.delegate = self
        shape.delegate = shapeDelegate
        shape.strokeColor = UIColor.white.cgColor
        shape.fillColor = UIColor.clear.cgColor
        shape.lineCap = kCALineCapRound
        shape.lineDashPhase = 0
        layer.addSublayer(shape)
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
    override func layoutSubviews()
    {
        super.layoutSubviews()

        let bounds = self.bounds
        shape.frame = bounds

        // mostly paintcode-generated
        func x(_ input: CGFloat) -> CGFloat
        {
            return (input / 245) * bounds.size.width
        }

        func y(_ input: CGFloat) -> CGFloat
        {
            return (input / 192) * bounds.size.height
        }

        let path = UIBezierPath()
        path.move(to: CGPoint(x: x(-0.4), y: y(185.75)))
        path.addCurve(to: CGPoint(x: x(245.14), y: y(129.97)), controlPoint1: CGPoint(x: x(146.24), y: y(205.56)), controlPoint2: CGPoint(x: x(245.14), y: y(174.47)))
        path.addCurve(to: CGPoint(x: x(115.47), y: y(44.48)), controlPoint1: CGPoint(x: x(245.14), y: y(85.47)), controlPoint2: CGPoint(x: x(115.47), y: y(92.52)))
        path.addCurve(to: CGPoint(x: x(233.47), y: y(0.48)), controlPoint1: CGPoint(x: x(115.47), y: y(-3.57)), controlPoint2: CGPoint(x: x(233.47), y: y(0.48)))

        shape.path = path.cgPath
        shape.lineDashPattern = [NSNumber(value: x(7.47).native), NSNumber(value: x(18.68).native)]
        shape.lineWidth = x(4.67)
    }

    // MARK: - Animation

    /**
     A producer that will fill the view's path when started.

     - parameter duration: The duration of the animation.
     */
    
    func fillShapeProducer(duration: TimeInterval) -> SignalProducer<(), NoError>
    {
        return CATransaction.producerWithDuration(duration, animations: { [weak self] in
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
            self?.strokeProgress = 1
        })
    }

    fileprivate final class ShapeLayerDelegate: NSObject, CALayerDelegate
    {
        @objc func action(for layer: CALayer, forKey event: String) -> CAAction?
        {
            return nil
        }
    }
}
