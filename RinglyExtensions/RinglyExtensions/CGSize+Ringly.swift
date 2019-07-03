import CoreGraphics

extension CGSize
{
    /// Returns a `CGSize` where both dimensions are `CGFloat.max`.
    public static var max: CGSize
    {
        return CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    }

    /**
     Returns a rect of the size centered in the specified rect.

     - parameter rect: The rect to center in.
     */
    public func centered(in rect: CGRect) -> CGRect
    {
        return CGRect(
            origin: CGPoint(x: rect.midX - width / 2, y: rect.midY - height / 2),
            size: self
        )
    }

    /**
     Returns a size that fits the receiver within `size`, maintaining the receiver's aspect ratio.

     - parameter size: The size to fit within.
     */
    public func aspectFit(in size: CGSize) -> CGSize
    {
        if width > size.width || height > size.height
        {
            let factor = min(size.width / width, size.height / height)
            return CGSize(width: width * factor, height: height * factor)
        }
        else
        {
            return self
        }
    }
}
