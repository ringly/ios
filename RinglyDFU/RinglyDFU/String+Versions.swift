import Foundation
import Result

extension String
{
    // MARK: - Implied Bootloader Version

    /// Returns the fallback bootloader version for the receiver (as a version number).
    ///
    /// Older versions of the peripheral application firmware do not allow us to read the current bootloader version. To
    /// work around this, we use some assumptions to determine the bootloader version.
    ///
    /// - Bootloader `1.1` started 100% shipping and updating after version `1.4.0` - therefore anything above this
    ///   version has at least version `1.1`. However, bootloader `1.1` and its matched application versions allow us
    ///   to directly read the bootloader version, so this assumption won't be necessary. Therefore, a version above or
    ///   equal to `1.4.0` returns a failure result.
    /// - Bootloader `1.0` started 100% shipping with version `1.3.0` - therefore, any peripheral at or above this
    ///   version has at least the `1.0` bootloader.
    /// - Before that, we assume bootloader `0.0.26`. There are a few users with `1.2.0` / `1.0`, but the `0.0.26`
    ///   process is backwards compatible.
    public var impliedBootloaderVersion: Result<String, NSError>
    {
        // if we're on at least 1.4.0, we can read the real bootloader version, and should require that
        guard self.rly_compareVersionNumbers("1.4.0") == .orderedAscending else {
            return .failure(DFUMakeError(.unknownBootloaderVersion) as NSError)
        }

        // if we're on at least 1.3.0, we have version 1.0.0
        guard self.rly_compareVersionNumbers("1.3.0") == .orderedAscending else {
            return .success("1.0.0")
        }

        // otherwise, assuming version 0.0.26
        return .success("0.0.26")
    }
}
