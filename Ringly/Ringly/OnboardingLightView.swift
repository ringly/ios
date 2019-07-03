import UIKit

final class OnboardingLightView: UIView
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

    // MARK: - Color
    var color: UIColor?
    {
        didSet
        {
            setNeedsDisplay()
        }
    }

    // MARK: - Drawing
    override func draw(_ rect: CGRect)
    {
        guard let color = self.color, let context = UIGraphicsGetCurrentContext() else { return }

        guard let gradient = CGGradient.create([
            (0, color),
            (1, color.withAlphaComponent(0))
        ]) else { return }

        let size = bounds.size
        
        context.move(to: CGPoint(x: 0, y: size.height / 2))
        context.addLine(to: CGPoint(x: size.width, y: 0))
        context.addLine(to: CGPoint(x: size.width, y: size.height))
        context.closePath()
        context.clip()
        
        context.drawLinearGradient(gradient,
            start: CGPoint.zero, end: CGPoint(x: size.width, y: 0),
            options: CGGradientDrawingOptions()
        )
    }
}
