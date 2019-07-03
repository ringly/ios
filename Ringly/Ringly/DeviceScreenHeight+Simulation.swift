import RinglyExtensions
import UIKit

extension DeviceScreenHeight
{
    /// Returns the current simulated (if `DEBUG` or `FUTURE` and applicable) or actual device screen height.
    static var current: DeviceScreenHeight
    {
        #if DEBUG || FUTURE
            return Preferences.shared.simulatedScreenSize.value
                .map({ DeviceScreenHeight(screenHeight: $0.height) })
                ?? UIScreen.main.deviceScreenHeight
        #else
            return UIScreen.main.deviceScreenHeight
        #endif
    }
}
