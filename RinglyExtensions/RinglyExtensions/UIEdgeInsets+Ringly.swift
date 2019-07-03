import Foundation

extension UIEdgeInsets
{
    /**
     Creates an edge insets value with uniform horizontal and vertical insets.

     - parameter horizontal: The horizontal insets.
     - parameter vertical:   The vertical insets.
     */
    public init(horizontal: CGFloat, vertical: CGFloat)
    {
        self.init(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }
}
