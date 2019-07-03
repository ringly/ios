import CoreGraphics

extension CGPoint
{
    public init(angle: CGFloat, radius: CGFloat, fromCenter center: CGPoint = .zero)
    {
        self.init(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
    }
}
