import PureLayout
import UIKit

extension UIImageView
{
    /// Adds a layout constraint requiring the image view to match its current image's aspect ratio.
    @discardableResult
    public func autoConstrainAspectRatio() -> NSLayoutConstraint?
    {
        return (image?.size).map({ size in
            return autoConstrain(
                attribute: .width,
                to: .height,
                of: self,
                multiplier: size.width / size.height
            )
        })
    }

    /// Adds layout constraints requiring the image view to match its current image's size.
    @discardableResult
    public func autoConstrainSize() -> [NSLayoutConstraint]?
    {
        return (image?.size).map(autoSetDimensions)
    }
}
