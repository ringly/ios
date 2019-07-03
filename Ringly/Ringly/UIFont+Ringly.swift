import RinglyExtensions
import UIKit

/// Standard tracking values used throughout the Ringly app.
extension CGFloat
{
    /// The tracking used on a standard "link" button.
    static let linkTracking: CGFloat = 100

    /// The standard tracking used on interface elements.
    static let controlsTracking: CGFloat = 300

    /// Double the standard tracking used on interface elements.
    static let doubleTracking: CGFloat = 600
}

extension UIFont
{
    // MARK: - Gotham

    /**
    Returns a Gotham Book font of the specified size.

    - parameter size: The font size.
    */
    @objc(gothamBookWithSize:) static func gothamBook(_ size: CGFloat) -> UIFont
    {
        return UIFont(name: "Gotham-Book", size: size) ?? UIFont.systemFont(ofSize: size, weight: UIFontWeightRegular)
    }

    /**
     Returns a Gotham Light font of the specified size.

     - parameter size: The font size.
     */
    @objc(gothamLightWithSize:) static func gothamLight(_ size: CGFloat) -> UIFont
    {
        return UIFont(name: "Gotham-Light", size: size) ?? UIFont.systemFont(ofSize: size, weight: UIFontWeightLight)
    }

    /**
     Returns a Gotham Bold font of the specified size.

     - parameter size: The font size.
     */
    @objc(gothamBoldWithSize:) static func gothamBold(_ size: CGFloat) -> UIFont
    {
        return UIFont(name: "Gotham-Bold", size: size) ?? UIFont.systemFont(ofSize: size, weight: UIFontWeightBold)
    }

    /**
     Returns a Gotham Medium font of the specified size.

     - parameter size: The font size.
     */
    @objc(gothamMediumWithSize:) static func gothamMedium(_ size: CGFloat) -> UIFont
    {
        return UIFont(name: "Gotham-Medium", size: size) ?? UIFont.systemFont(ofSize: size, weight: UIFontWeightMedium)
    }
    
    // MARK: - Tracking

    /**
     Applies a tracking attribute to all but the final character of the string, while applying the font to the entire
     string.

     Cocoa's text system applies the tracking to the last character as well, so text is slightly off-center. Using this
     function avoids that.

     - parameter tracking: The tracking to apply.
     - parameter string:   The string.
     */
    func track(_ tracking: CGFloat, _ string: String) -> AttributedStringProtocol
    {
        guard string.characters.count > 0 else {
            return string
        }

        let index = string.characters.index(before: string.endIndex)

        return [
            string.substring(to: index).attributes(font: self, tracking: tracking),
            string.substring(from: index).attributes(font: self)
        ].join()
    }
}

extension AttributedStringProtocol
{
    /// Returns an attributed string representation of the receiver, removing the final kerning attribute. This allows
    /// text to be centered correctly.
    var attributedStringRemovingFinalKerning: NSAttributedString
    {
        let mutable = NSMutableAttributedString(attributedString: self.attributedString)

        if mutable.length > 0
        {
            mutable.removeAttribute(NSKernAttributeName, range: NSMakeRange(mutable.length - 1, 1))
        }

        return mutable
    }
}
