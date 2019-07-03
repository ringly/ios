import Foundation
import RinglyExtensions

/// The peripheral will notify us repeatedly of successful packet writes. Doing this less frequently make writing much
/// faster, but cannot be done on 0.0.26 devices.
internal enum WriterNotificationMode
{
    // MARK: - Cases

    /// Use for bootloader 1.0 or greater writes.
    case fast

    /// Use for bootloader 0.0.26 writes.
    case safe
}

extension WriterNotificationMode
{
    // MARK: - Bootloader

    /**
     Initializes a writable notification mode with a bootloader version.

     - parameter bootloader: The bootloader version.

     - returns: The fastest writable notification mode that is safe to use with the bootloader version.
     */
    init(bootloader: String)
    {
        self = "1".rly_compareVersionNumbers(bootloader) != .orderedDescending ? .fast : .safe
    }
}

extension WriterNotificationMode
{
    // MARK: - Packets Notification Interval

    /// The value to use for Nordic's `PACKETS_NOTIFICATION_INTERVAL` global variable.
    var packetsNotificationInterval: UInt16
    {
        switch self
        {
        case .fast:
            return 10
        case .safe:
            return 1
        }
    }
}
