import CoreGraphics

extension CGRect
{
    // MARK: - Transforms

    /// Returns a transform from the rect to a second rect.
    ///
    /// - parameter rect: The rect to transform to.
    
    public func transform(to rect: CGRect) -> CGAffineTransform
    {
        return CGAffineTransform(translationX: rect.midX - midX, y: rect.midY - midY).scaledBy(x: rect.size.width / size.width,
            y: rect.size.height / size.height
        )
    }

    /// The midpoint of the rect.
    public var mid: CGPoint
    {
        return CGPoint(x: midX, y: midY)
    }
}
