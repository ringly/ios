import Foundation
import RinglyExtensions
import UIKit

/// An endpoint for registering the user's peripheral.
public struct PeripheralRegistrationRequest
{
    // MARK: - Initialization

    /**
     Initializes a peripheral registration endpoint.

     - parameter name:               The name of the peripheral.
     - parameter MACAddress:         The MAC address of the peripheral.
     - parameter applicationVersion: The application version of the peripheral.
     - parameter bootloaderVersion:  The bootloader version of the peripheral.
     - parameter softdeviceVersion:  The softdevice version of the peripheral.
     - parameter hardwareVersion:    The hardware version of the peripheral.
     */
    public init(name: String,
                MACAddress: String,
                applicationVersion: String,
                bootloaderVersion: String,
                softdeviceVersion: String,
                hardwareVersion: String)
    {
        self.name = name
        self.MACAddress = MACAddress
        self.applicationVersion = applicationVersion
        self.bootloaderVersion = bootloaderVersion
        self.softdeviceVersion = softdeviceVersion
        self.hardwareVersion = hardwareVersion
    }

    // MARK: - Properties

    /// The name of the peripheral.
    public let name: String

    /// The MAC address of the peripheral.
    public let MACAddress: String

    /// The application version of the peripheral.
    public let applicationVersion: String

    /// The bootloader version of the peripheral.
    public let bootloaderVersion: String

    /// The softdevice version of the peripheral.
    public let softdeviceVersion: String

    /// The hardware version of the peripheral.
    public let hardwareVersion: String
}

extension PeripheralRegistrationRequest: RequestProviding
{
    // MARK: - Request
    public func request(for baseURL: URL) -> URLRequest?
    {
        return URLRequest(
            method: .post,
            baseURL: baseURL,
            relativeURLString: "users/device-snapshot",
            jsonBody: jsonBody
        )
    }

    public var jsonBody: [String:Any]
    {
        let bundle = Bundle.main
        let device = UIDevice.current

        return [
            // add device-specific keys, these will not change across an individual run of the app
            "operating_system": "0",
            "os_version": device.systemVersion,
            "model": device.modelIdentifier as Any? ?? NSNull(),
            "client_version": bundle.object(forInfoDictionaryKey: kCFBundleVersionKey as String) ?? NSNull(),

            // add peripheral keys
            "ring_name": name as AnyObject,
            "mac_address": MACAddress,
            "application_version": applicationVersion,
            "bootloader_version": bootloaderVersion,
            "softdevice_version": softdeviceVersion,
            "hardware_version": hardwareVersion
        ]
    }
}

