import Foundation
import RinglyExtensions
import RinglyKit

/// Describes the conditional DFU firmware features of a peripheral.
internal struct FirmwareFeatures
{
    // MARK: - Features

    /// If `true`, the peripheral's identifier will change in bootloader mode.
    let changesIdentifierInBootloaderMode: Bool

    /// If `true`, the peripheral maintains bond data across updates.
    let maintainsBondData: Bool

    /// The fastest notification mode supported by this peripheral.
    let writerNotificationMode: WriterNotificationMode

    /// If `true`, the firmware update will modify services. This requires a Bluetooth power toggle to reset the iOS
    /// cache.
    let modifiesServices: Bool
}

extension FirmwareFeatures
{
    // MARK: - Initialization

    /**
     Returns the firmware features available on a peripheral with the specified firmware versions.

     - parameter application: The application firmware version.
     - parameter bootloader:  The bootloader firmware version.
     */
    init(application: String, bootloader: String)
    {
        changesIdentifierInBootloaderMode = bootloader.rly_compareVersionNumbers("1") != .orderedAscending

        maintainsBondData = bootloader.rly_compareVersionNumbers("1.0.0.3") != .orderedAscending
                         && application.rly_compareVersionNumbers("1.3.1.1") != .orderedAscending

        writerNotificationMode = WriterNotificationMode(bootloader: bootloader)

        modifiesServices = application.rly_compareVersionNumbers("2") != .orderedAscending
                        && application.rly_compareVersionNumbers("2.2") == .orderedAscending
    }

    // MARK: - Recovery Mode

    /// The features supported in recovery mode.
    static func recoveryModeFeatures(knownHardwareVersion: RLYKnownHardwareVersion)
        -> FirmwareFeatures
    {
        return FirmwareFeatures(changesIdentifierInBootloaderMode: false,
                                maintainsBondData: false,
                                writerNotificationMode: knownHardwareVersion == .version2 ? .fast : .safe,
                                modifiesServices: false)
    }
}
