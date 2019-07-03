import DFULibrary
import RinglyExtensions

extension DFUFirmwareType
{
    init?(string: String)
    {
        switch string
        {
        case "application":
            self = .application
        case "bootloader":
            self = .bootloader
        default:
            return nil
        }
    }
}

/// A single firmware version, available via a URL download.
public struct Firmware: Equatable
{
    // MARK: - Properties
    
    /// The firmware type.
    public let type: DFUFirmwareType
    
    /// The firmware version.
    public let version: String
    
    /// The firmware download URL.
    public let URL: Foundation.URL
    
    // MARK: - Initialization
    
    /**
    Initializes a `Firmware` object.
    
    - parameter type:    The firmware type.
    - parameter version: The firmware version.
    - parameter URL:     The firmware download URL.
    */
    public init(type: DFUFirmwareType, version: String, URL: Foundation.URL)
    {
        self.type = type
        self.version = version
        self.URL = URL
    }
}

extension Firmware: Decoding
{
    // MARK: - Decodable
    public typealias Encoded = [String:Any]

    public static func decode(_ encoded: Encoded) throws -> Firmware
    {
        guard let type = DFUFirmwareType(string: try encoded.decode("target")) else {
            throw DecodeError.key("target", from: encoded)
        }

        return Firmware(
            type: type,
            version: try encoded.decode("version"),
            URL: try encoded.decodeURL("url")
        )
    }
}

public func ==(lhs: Firmware, rhs: Firmware) -> Bool
{
    return lhs.type == rhs.type && lhs.version == rhs.version && lhs.URL == rhs.URL
}

/// A collection of application and bootloader firmware versions.
public struct FirmwareResult: Equatable
{
    // MARK: - Firmwares
    
    /// The application firmwares.
    public let applications: [Firmware]
    
    /// The bootloader firmwares.
    public let bootloaders: [Firmware]
    
    // MARK: - Initializers
    
    /**
    Initializes a `FirmwareResult` with the specified firmwares.
    
    - parameter applications: The application firmwares.
    - parameter bootloaders:  The bootloader firmwares.
    */
    public init(applications: [Firmware], bootloaders: [Firmware])
    {
        self.applications = applications
        self.bootloaders = bootloaders
    }
}

extension FirmwareResult: CustomStringConvertible
{
    // MARK: - Description
    public var description: String
    {
        return "(applications = \(applications), bootloaders = \(bootloaders))"
    }
}

extension FirmwareResult: Decoding
{
    // MARK: - Decodable
    public typealias Encoded = [[String:AnyObject]]

    public static func decode(_ encoded: Encoded) throws -> FirmwareResult
    {
        let firmwares = try encoded.map(Firmware.decode)

        return FirmwareResult(
            applications: firmwares.filter({ firmware in firmware.type == .application }),
            bootloaders: firmwares.filter({ firmware in firmware.type == .bootloader })
        )
    }
}

public func ==(lhs: FirmwareResult, rhs: FirmwareResult) -> Bool
{
    return lhs.applications == rhs.applications && lhs.bootloaders == rhs.bootloaders
}
