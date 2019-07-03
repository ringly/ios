import DFULibrary
import Foundation
import Result
import RinglyAPI

// MARK: - Package Component Type
extension DFUFirmwareType
{
    /// The filename, without extension, of data files in a package of the receiver's type.
    var baseFilename: String
    {
        switch self
        {
        case .application:
            return "application"
        case .bootloader:
            return "bootloader"
        case .softdevice:
            return "softdevice"
        default:
            fatalError("Unsupported firmware type \(self.rawValue)")
        }
    }
}

// MARK: - Package Component
public struct PackageComponent
{
    // MARK: - Type
    public let type: DFUFirmwareType

    // MARK: - Data File Locations

    /// The URL for the data file (`.hex` extension).
    public let dataURL: URL

    /// The URL for the metadata file (`.dat` extension).
    public let metadataURL: URL?

    // MARK: - Version

    /// The package component's version.
    public let version: String
}

extension PackageComponent
{
    /**
     Creates a package component from the specified directory, if the required files are present.

     - parameter directoryURL: The directory URL.
     - parameter version:      The version of the package component.
     - parameter type:         The type of the package component.
     */
    public static func with(directoryURL: URL, version: String, type: DFUFirmwareType)
        -> Result<PackageComponent, NSError>
    {
        let fm = FileManager.default

        let baseFilenameURL = directoryURL.appendingPathComponent(type.baseFilename)
        let dataURL = baseFilenameURL.appendingPathExtension("hex")
        let metadataURL = baseFilenameURL.appendingPathExtension("dat")

        if fm.fileExists(atPath: dataURL.path)
        {
            return .success(PackageComponent(
                type: type,
                dataURL: dataURL,
                metadataURL: fm.fileExists(atPath: metadataURL.path) ? metadataURL : nil,
                version: version
            ))
        }
        else
        {
            return .failure(DFUMakeError(.missingDataFile) as NSError)
        }
    }
}

extension PackageComponent
{
    var firmware: DFUFirmware?
    {
        return DFUFirmware(urlToBinOrHexFile: dataURL, urlToDatFile: metadataURL, type: type)
    }
}
