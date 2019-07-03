import UIKit

/// Enumerates the directions that `LineView` can draw in.
enum LineViewDirection
{
    /// In a 0-1 coordinate system, the line is drawn from `(0, 0)` to `(1, 1)`.
    case descending

    /// In a 0-1 coordinate system, the line is drawn from `(0, 1)` to `(1, 0)`.
    case ascending
}

/// A view that draws a diagonal line.
final class LineView: UIView
{
    // MARK: - Initialization
    fileprivate func setup()
    {
        backgroundColor = UIColor.clear
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

    /// The direction to draw the line in.
    var direction = LineViewDirection.ascending
    {
        didSet { setNeedsDisplay() }
    }

    /// The width of the line.
    var lineWidth: CGFloat = 1
    {
        didSet { setNeedsDisplay() }
    }

    /// The color of the line.
    var color = UIColor.white
    {
        didSet { setNeedsDisplay() }
    }

    override func draw(_ rect: CGRect)
    {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(lineWidth)

        let size = bounds.size

        switch direction
        {
        case .ascending:
            context.move(to: CGPoint(x: 0, y: size.height))
            context.addLine(to: CGPoint(x: size.width, y: 0))
        case .descending:
            context.move(to: CGPoint(x: 0, y: 0))
            context.addLine(to: CGPoint(x: size.width, y: size.height))
        }

        context.strokePath()
    }
}
