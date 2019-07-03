import UIKit

extension UIDeviceBatteryState
{
    var charging: Bool
    {
        return self == .charging || self == .full
    }
}
