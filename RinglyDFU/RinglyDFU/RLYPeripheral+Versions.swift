import Foundation
import Result
import RinglyKit

extension RLYPeripheral
{
    /// The firmware versions for this peripheral, or an error if they cannot be found.
    var DFUFirmwareVersionsResult: Result<(application: String, bootloader: String), NSError>
    {
        // unpack the application and bootloader versions
        guard let application = applicationVersion else {
            return .failure(DFUMakeError(.unknownApplicationVersion) as NSError)
        }

        // find the bootloader version or implied bootloader version if necessary
        let bootloader = bootloaderVersion.map({ .success($0) }) ?? application.impliedBootloaderVersion

        // combine the two as results
        return bootloader.map({ (application: application, bootloader: $0) })
    }
}
