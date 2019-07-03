import CoreGraphics
import UIKit

extension CGGradient
{
    /**
     Creates a gradient with the specified components.

     - parameter components: An array of tuples, `(location, color)`.
     */
    static func create(_ components: [(CGFloat, UIColor)]) -> CGGradient?
    {
        // pre-allocate array for components
        let locations = components.map({ location, _ in location })
        let colors = components.map({ _, color in color.cgColor })

        return locations.withUnsafeBufferPointer({ locations in
            CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as NSArray, locations: locations.baseAddress)
        })
    }
}
