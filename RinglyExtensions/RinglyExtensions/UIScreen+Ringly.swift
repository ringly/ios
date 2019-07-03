import UIKit

/// An enumeration describing standard screen heights of iOS device models.
public enum DeviceScreenHeight: Int
{
    /// An iPhone 4 screen size.
    case four

    /// An iPhone 5 screen size.
    case five

    /// An iPhone 6 screen size.
    case six

    /// An iPhone 6 Plus screen size.
    case sixPlus

    /// An iPad screen size.
    case pad
}

extension DeviceScreenHeight
{
    // MARK: - Initialization

    /**
     Returns the device screen height for the specified screen height.

     - parameter screenHeight: The screen height.
     */
    public init(screenHeight: CGFloat)
    {
        if screenHeight < 481
        {
            self = .four
        }
        else if screenHeight < 569
        {
            self = .five
        }
        else if screenHeight < 668
        {
            self = .six
        }
        else if screenHeight < 737
        {
            self = .sixPlus
        }
        else
        {
            self = .pad
        }
    }
}

extension DeviceScreenHeight
{
    // MARK: - Selecting Values

    /**
     Selects a value, preferring values closer to the receiver.

     To provide layout value overrides (the typical use case) for iPhone 4 and 5, this function could be used:

         let value = screenHeight.select(
             four: 5,
             five: 10,
             preferred: 20
         )

     This will return `5` on an iPhone 4, `10` on an iPhone 5, and `20` on any other model.

     It's preferable to use layout constraints when possible, since they offer more flexibility, but this function can
     be used for easy hard breaks on padding or offset values.

     All parameters except `preferred` are optional (both in type and the ability to be omitted). The default value for
     all of them is `nil`, which indicates that screen height should be bypassed.

     - parameter four:      A value to prefer for `Four`.
     - parameter five:      A value to prefer for `Five` and below.
     - parameter six:       A value to prefer for `Six` and below.
     - parameter sixPlus:   A value to prefer for `SixPlus` and below.
     - parameter preferred: The preferred value, to be used if not overriden by a lower value.
     */
    public func select<Value>(four: Value? = nil,
                              five: Value? = nil,
                              six: Value? = nil,
                              sixPlus: Value? = nil,
                              preferred: Value)
                              -> Value
    {
        switch self
        {
        case .four:
            return four ?? five ?? six ?? sixPlus ?? preferred
        case .five:
            return five ?? six ?? sixPlus ?? preferred
        case .six:
            return six ?? sixPlus ?? preferred
        case .sixPlus:
            return sixPlus ?? preferred
        case .pad:
            return preferred
        }
    }
}

extension DeviceScreenHeight: Comparable {}
public func <(lhs: DeviceScreenHeight, rhs: DeviceScreenHeight) -> Bool
{
    return lhs.rawValue < rhs.rawValue
}

extension UIScreen
{
    /// Returns the "device screen height" of this screen, which determines which model of iPhone the app is running on.
    /// While it's preferable to use auto-layout for differences between devices, in some cases, we need to hard-code
    /// smaller sizes for older devices.
    public var deviceScreenHeight: DeviceScreenHeight
    {
        return DeviceScreenHeight(screenHeight: bounds.size.height)
    }
}
