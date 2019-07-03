import UIKit

extension UIDevice
{
    /// Returns the device's model identifier, if available.
    public var modelIdentifier: String?
    {
        var name = utsname()
        uname(&name)

        return withUnsafePointer(to: &name.machine, { ptr in
            String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
        })
    }
}
