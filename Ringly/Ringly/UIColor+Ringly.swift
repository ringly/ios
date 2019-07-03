import RinglyKit
import UIKit

public extension UIColor
{
    // MARK: - Default Colors

    /// A color to represent a blue Ringly LED color.
    @nonobjc static let ringlyBlue = UIColor(red: 70 / 255.0, green: 170 / 255.0, blue: 240 / 255.0, alpha: 1)

    /// A color to represent the green Ringly LED color.
    @nonobjc static let ringlyGreen = UIColor(red: 70 / 255.0, green: 230 / 255.0, blue: 180 / 255.0, alpha: 1)

    /// A color to represent the yellow Ringly LED color.
    @nonobjc static let ringlyYellow = UIColor(red: 250 / 255.0, green: 215 / 255.0, blue: 140 / 255.0, alpha: 1)

    /// A color to represent the purple Ringly LED color.
    @nonobjc static let ringlyPurple = UIColor(red: 207 / 255.0, green: 139 / 255.0, blue: 210 / 255.0, alpha: 1)
    
    /// A color to represent the red Ringly LED color.
    @nonobjc static let ringlyRed = UIColor(red: 255 / 255.0, green: 130 / 255.0, blue: 130 / 255.0, alpha: 1)

    /// A color to represent the none/disabled Ringly LED color.
    @nonobjc static let ringlyNone = UIColor(red: 90 / 255.0, green: 80 / 255.0, blue: 74 / 255.0, alpha: 1)

    /// Returns a color for the specified `DefaultColor`.
    ///
    /// - Parameter defaultColor: The default color to return a color for.
    static func color(defaultColor: DefaultColor) -> UIColor
    {
        switch defaultColor
        {
            case .none:
                return UIColor.ringlyNone
            case .blue:
                return UIColor.ringlyBlue
            case .green:
                return UIColor.ringlyGreen
            case .purple:
                return UIColor.ringlyPurple
            case .red:
                return UIColor.ringlyRed
            case .yellow:
                return UIColor.ringlyYellow
        }
    }
}

extension UIColor
{
    // MARK: - Authentication
    @nonobjc static let authenticationButtonInvalid = UIColor(red: 0.7629, green: 0.8238, blue: 0.9314, alpha: 1.0)
    @nonobjc static let authenticationButtonValid = UIColor(red: 0.4681, green: 0.6188, blue: 0.8643, alpha: 1.0)
    @nonobjc static let authenticationErrorAlert = UIColor(red: 0.6604, green: 0.539, blue: 0.7748, alpha: 1.0)

    // MARK: - Gradient Colors
    @nonobjc static let pinkGradientStart = UIColor(red:1, green:0.4823529412, blue:0.4823529412, alpha: 1)
    @nonobjc static let pinkGradientEnd = UIColor(red:0.8117647059, green:0.5450980392, blue:0.8235294118, alpha:1)

    // MARK: - Interface
    @nonobjc static let ringlyTextHighlight = UIColor(red: 205 / 255.0, green: 160 / 255.0, blue: 150 / 255.0, alpha: 1)
    @nonobjc static let ringlyLightBlack = UIColor(red: 54 / 255.0, green: 54 / 255.0, blue: 54 / 255.0, alpha: 1)

    // MARK: - Tab Bar
    @nonobjc static let tabBarBackgroundColor = UIColor.white
    
    /// A color to represent the progress colors
    @nonobjc static let progressPink = UIColor(red: 248.0 / 255.0, green: 173.0 / 255.0, blue: 201.0 / 255.0, alpha: 1)
    @nonobjc static let progressPurple = UIColor(red: 207.0 / 255.0, green: 139.0 / 255.0, blue: 210.0 / 255.0, alpha: 1)

}
